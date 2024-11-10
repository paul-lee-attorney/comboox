// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "./IROAKeeper.sol";

import "../common/access/RoyaltyCharge.sol";

contract ROAKeeper is IROAKeeper, RoyaltyCharge {
    using RulesParser for bytes32;

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function createIA(uint version, address msgSender) external onlyDK {
 
        uint caller = _msgSender(msgSender, 58000);

        require(_gk.getROM().isMember(caller), "not MEMBER");
        
        bytes32 snOfDoc = bytes32((uint(uint8(IRegCenter.TypeOfDoc.IA)) << 224) +
            uint224(version << 192)); 

        DocsRepo.Doc memory doc = _rc.createDoc(
            snOfDoc,
            msgSender
        );

        IAccessControl(doc.body).initKeepers(
            address(this),
            address(_gk)
        );

        _gk.getROA().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    // ======== Circulate IA ========

    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);

        require(ISigPage(ia).isParty(caller), "ROAK.md.OPO: NOT Party");

        require(IDraftControl(ia).isFinalized(), 
            "ROAK.CIA: IA not finalized");

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        _ia.circulateDoc();
        uint16 signingDays = _ia.getSigningDays();
        uint16 closingDays = _ia.getClosingDays();

        

        RulesParser.VotingRule memory vr = 
            _gk.getSHA().getRule(_ia.getTypeOfIA()).votingRuleParser();

        _ia.setTiming(false, signingDays + vr.frExecDays + vr.dtExecDays + vr.dtConfirmDays, closingDays);

        _gk.getROA().circulateFile(ia, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        address msgSender,
        bytes32 sigHash
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 36000);

        require(ISigPage(ia).isParty(caller), "ROAK.md.OPO: NOT Party");

        IRegisterOfAgreements _roa = _gk.getROA();

        require(
            _roa.getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Circulated),
            "ROAK.signIA: wrong state"
        );

        _lockDealsOfParty(ia, caller);
        ISigPage(ia).signDoc(true, caller, sigHash);
    }

    function _lockDealsOfParty(address ia, uint256 caller) private {
        uint[] memory list = IInvestmentAgreement(ia).getSeqList();
        uint256 len = list.length;
        while (len > 0) {
            uint seq = list[len - 1];
            len--;

            DealsRepo.Deal memory deal = 
                IInvestmentAgreement(ia).getDeal(seq);

            if (deal.head.seller == caller) {

                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    _gk.getROS().decreaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
                }

            } else if (deal.body.buyer == caller) {
                
                _buyerIsVerified(deal.body.buyer);
                
                if (deal.head.typeOfDeal ==
                   uint8(DealsRepo.TypeOfDeal.CapitalIncrease)) {
                    IInvestmentAgreement(ia).lockDealSubject(seq);
                }
                
            }
        }
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline,
        address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 58000);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = 
            _ia.getDeal(seqOfDeal);

        bool isST = (deal.head.seqOfShare != 0);

        if (isST) {
            require(caller == deal.head.seller, "ROAK.PTC: not seller");
            require(_lockUpCheck(address(_ia), deal, uint48(block.timestamp)), 
                "ROAK.PTC: target share locked");
        } else {
            require (_gk.getROD().isDirector(caller) ||
                _gk.getROM().controllor() == caller, 
                "ROAK.PTC: not director or controllor");
        }

        _vrAndSHACheck(_ia);

        _ia.clearDealCP(seqOfDeal, hashLock, closingDeadline);
    }

    function _vrAndSHACheck(IInvestmentAgreement _ia) private view {
        
        IMeetingMinutes _bmm = _gk.getBMM();
        IMeetingMinutes _gmm = _gk.getGMM();
        IRegisterOfAgreements _roa = _gk.getROA();

        require(
            _roa.getHeadOfFile(address(_ia)).state == uint8(FilesRepo.StateOfFile.Approved),
            "BOAK.vrAndSHACheck: wrong state"
        );

        uint256 typeOfIA = _ia.getTypeOfIA();

        IShareholdersAgreement _sha = _gk.getSHA();

        RulesParser.VotingRule memory vr = 
            _sha.getRule(typeOfIA).votingRuleParser();

        uint seqOfMotion = _roa.getHeadOfFile(address(_ia)).seqOfMotion;

        if (vr.amountRatio > 0 || vr.headRatio > 0) {
            if (vr.authority == 1)
                require(_gmm.isPassed(seqOfMotion), 
                    "ROAK.vrCheck:  rejected by GM");
            else if (vr.authority == 2)
                require(_bmm.isPassed(seqOfMotion), 
                    "ROAK.vrCheck:  rejected by Board");
            else if (vr.authority == 3)
                require(_gmm.isPassed(seqOfMotion) && 
                    _bmm.isPassed(seqOfMotion), 
                    "ROAK.vrCheck: rejected by GM or Board");
            else revert("ROAK.vrCheck: authority overflow");
        }
    }

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external onlyDK {

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        if (_ia.closeDeal(deal.head.seqOfDeal, hashKey))
            _gk.getROA().execFile(ia);

        if (deal.head.seqOfShare > 0) 
            _shareTransfer(_ia, deal.head.seqOfDeal);
        else _issueNewShare(_ia, deal.head.seqOfDeal);
    }

    function _lockUpCheck(
        address _ia,
        DealsRepo.Deal memory deal,
        uint48 closingDate
    ) private view returns(bool) {

        IShareholdersAgreement _sha = _gk.getSHA();
        
        if (!_sha.hasTitle(uint8(IShareholdersAgreement.TitleOfTerm.LockUp))) {
            return true;
        }

        address lu = _sha.getTerm(uint8(IShareholdersAgreement.TitleOfTerm.LockUp));
        
        if (closingDate > 0) {
            deal.head.closingDeadline = closingDate;
        }

        if (!ILockUp(lu).isTriggered(deal)) {
            return true;
        } else if (ILockUp(lu).isExempted(_ia, deal)) {
            return true;
        }

        return false;
    }

    function _buyerIsVerified(
        uint buyer
    ) private view {
        require (_gk.getLOO().getInvestor(buyer).state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved), 
            "ROAK.buyerIsVerified: not");
    }

    function _shareTransfer(IInvestmentAgreement _ia, uint256 seqOfDeal) private {
        
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _buyerIsVerified(deal.body.buyer);

        require (_lockUpCheck(address(_ia), deal, uint48(block.timestamp)),
            "ROAK._ST: share locked");

        require(_checkAlong(_ia, seqOfDeal), "ROAK.shareTransfer: Along Deal Open");

        _ros.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _ros.transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, 
            deal.body.buyer, deal.head.priceOfPaid, deal.head.priceOfPar);

        if (deal.body.buyer != deal.body.groupOfBuyer && 
            deal.body.groupOfBuyer != _rom.groupRep(deal.body.buyer)) 
                _rom.addMemberToGroup(deal.body.buyer, deal.body.groupOfBuyer);
    }

    function _checkAlong(IInvestmentAgreement _ia, uint seqOfDeal) private view returns(bool) {
        uint[] memory seqList = _ia.getSeqList();
        uint len = seqList.length;
        while (len > 0) {
            DealsRepo.Deal memory deal = _ia.getDeal(seqList[len - 1]);
            if ((deal.head.typeOfDeal == uint8(DealsRepo.TypeOfDeal.TagAlong) ||
                deal.head.typeOfDeal == uint8(DealsRepo.TypeOfDeal.DragAlong)) &&
                deal.head.preSeq == uint16(seqOfDeal) &&
                deal.body.state != uint8(DealsRepo.StateOfDeal.Closed)) 
            {
                return false;
            }
            len--;
        }
        return true;
    }

    function issueNewShare(address ia, uint256 seqOfDeal, address msgSender) public onlyDK {

        uint caller = _msgSender(msgSender, 58000);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(_gk.getROD().isDirector(caller) ||
            _gk.getROM().controllor() == caller, 
            "ROAK.issueNewShare: not director or controllor");

        _vrAndSHACheck(_ia);

        if (_ia.directCloseDeal(seqOfDeal)) _gk.getROA().execFile(ia);

        _issueNewShare(_ia, seqOfDeal);
    }

    function _issueNewShare(IInvestmentAgreement _ia, uint seqOfDeal) private {
        
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _buyerIsVerified(deal.body.buyer);

        SharesRepo.Share memory share;

        share.head = SharesRepo.Head({
            seqOfShare: 0,
            preSeq: 0,
            class: deal.head.classOfShare,
            issueDate: uint48(block.timestamp),
            shareholder: deal.body.buyer,
            priceOfPaid: deal.head.priceOfPaid,
            priceOfPar: deal.head.priceOfPar,
            votingWeight: deal.head.votingWeight,
            argu: 0
        });

        share.body = SharesRepo.Body({
            payInDeadline: uint48(block.timestamp) + 43200,
            paid: deal.body.paid,
            par: deal.body.par,
            cleanPaid: deal.body.paid,
            distrWeight: deal.body.distrWeight
        });

        _ros.addShare(share);
        
        if (deal.body.buyer != deal.body.groupOfBuyer &&
            deal.body.groupOfBuyer != _rom.groupRep(deal.body.buyer))
                _rom.addMemberToGroup(deal.body.buyer, deal.body.groupOfBuyer);
    }


    function transferTargetShare(
        address ia,
        uint256 seqOfDeal,
        address msgSender
    ) public onlyDK {

        uint caller = _msgSender(msgSender, 58000);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(
            caller == _ia.getDeal(seqOfDeal).head.seller,
                "ROAK.TTS: not seller"
        );

        _vrAndSHACheck(_ia);

        if (_ia.directCloseDeal(seqOfDeal))
            _gk.getROA().execFile(ia);

        _shareTransfer(_ia, seqOfDeal);
    }

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        IRegisterOfAgreements _roa = _gk.getROA();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "ROAK.TD: NOT seller"
        );

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        uint8 state = _roa.getHeadOfFile(ia).state;

        if ((state < uint8(FilesRepo.StateOfFile.Proposed) &&
                block.timestamp >= _roa.terminateStartpoint(ia)) || 
            (state == uint8(FilesRepo.StateOfFile.Rejected)) ||
            (state == uint8(FilesRepo.StateOfFile.Approved) &&
                block.timestamp >= _ia.getDeal(seqOfDeal).head.closingDeadline)
        ) {
            if (_ia.terminateDeal(seqOfDeal))
                _roa.terminateFile(ia);
            if (_ia.releaseDealSubject(seqOfDeal))
                _gk.getROS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);            
        } else revert("ROAK.TD: wrong state");
    }


    function payOffApprovedDeal(
        address ia,
        uint seqOfDeal,
        uint msgValue,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = 
            _ia.getDeal(seqOfDeal);

        _vrAndSHACheck(_ia);

        uint centPrice = _gk.getCentPrice();
        uint valueOfDeal = (deal.body.paid * deal.head.priceOfPaid + 
            (deal.body.par - deal.body.paid) * deal.head.priceOfPar) / 10 ** 4 * 
            centPrice / 100;

        require( valueOfDeal <= msgValue, "ROAK.payApprDeal: insufficient msgValue");

        if (_ia.payOffApprovedDeal(seqOfDeal, msgValue, caller)) 
            _gk.getROA().execFile(ia);

        if (deal.head.seqOfShare > 0) {
            _gk.saveToCoffer(
                deal.head.seller, valueOfDeal, 
                bytes32(0x4465706f736974436f6e73696465726174696f6e4f6653544465616c00000000)
            ); // DepositConsiderationOfSTDeal 
            _shareTransfer(_ia, deal.head.seqOfDeal);
        } else {
            _issueNewShare(_ia, deal.head.seqOfDeal);
            emit PayOffCIDeal(caller, valueOfDeal);
        }

        msgValue -= valueOfDeal;
        if (msgValue > 0) {
            _gk.saveToCoffer(
                caller, msgValue,
                bytes32(0x4465706f73697442616c616e63654f664f54434465616c000000000000000000)
            ); // DepositBalanceOfOTCDeal 
        }    
    }
    
}

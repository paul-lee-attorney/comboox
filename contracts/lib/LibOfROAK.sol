// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
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

pragma solidity ^0.8.24;

import "./RulesParser.sol";
import "./InterfacesHub.sol";
import "./TypesList.sol";

library LibOfROAK {
    using RulesParser for bytes32;
    using InterfacesHub for address;

    error ROAKLib_NotPartyOfIA(address ia, uint caller);
    
    error ROAKLib_IANotFinalized(address ia);

    error ROAKLib_WrongFileState(address ia, uint state);
    
    error ROAKLib_WrongSellor(address ia, uint seqOfDeal, uint caller);

    error ROAKLib_ShareLocked(address ia, uint seqOfDeal);

    error ROAKLib_NotApproved(uint seqOfMotion);
    
    error ROAKLib_AlongDealOpen(address ia, uint seqOfDeal);

    error ROAKLib_BuyerNotVerified(uint buyer);

    error ROAKLib_BuyerNotSignerOfSHA(uint buyer);

    error ROAKLib_WrongPayee(uint payee);

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    // ======== Circulate IA ========

    function circulateIA(
        uint caller,
        address ia,
        bytes32 docUrl,
        bytes32 docHash
    ) external {
        address gk = address(this);

        if (!ISigPage(ia).isParty(caller)) {
            revert ROAKLib_NotPartyOfIA(ia, caller);
        }

        if (!IDraftControl(ia).isFinalized()) {
            revert ROAKLib_IANotFinalized(ia);
        }

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        _ia.circulateDoc();
        uint16 signingDays = _ia.getSigningDays();
        uint16 closingDays = _ia.getClosingDays();        

        RulesParser.VotingRule memory vr = 
            gk.getSHA().getRule(_ia.getTypeOfIA()).votingRuleParser();

        _ia.setTiming(false, signingDays + vr.frExecDays + vr.dtExecDays + vr.dtConfirmDays, closingDays);

        gk.getROA().circulateFile(ia, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        uint caller,
        address ia,
        bytes32 sigHash
    ) external {
        address gk = address(this);

        if (!ISigPage(ia).isParty(caller)) {
            revert ROAKLib_NotPartyOfIA(ia, caller);
        }

        IRegisterOfAgreements _roa = gk.getROA();

        if (
            _roa.getHeadOfFile(ia).state != uint8(FilesRepo.StateOfFile.Circulated)
        ) {
            revert ROAKLib_WrongFileState(ia, _roa.getHeadOfFile(ia).state);
        }

        _lockDealsOfParty(ia, caller);

        ISigPage(ia).signDoc(true, caller, sigHash);
    }

    function _lockDealsOfParty(address ia, uint256 caller) private {
        address gk = address(this);

        uint[] memory list = IInvestmentAgreement(ia).getSeqList();
        uint256 len = list.length;

        while (len > 0) {
            uint seq = list[len - 1];
            len--;

            DealsRepo.Deal memory deal = 
                IInvestmentAgreement(ia).getDeal(seq);

            if (deal.head.seller == caller) {

                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    gk.getROS().decreaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
                }

            } else if (deal.body.buyer == caller) {
                
                _buyerIsVerified(gk, deal.body.buyer);
                
                if (deal.head.typeOfDeal ==
                   uint8(DealsRepo.TypeOfDeal.CapitalIncrease)) {
                    IInvestmentAgreement(ia).lockDealSubject(seq);
                }
                
            }
        }
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        uint caller,
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline
    ) external {
        address gk = address(this);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = 
            _ia.getDeal(seqOfDeal);

        bool isST = (deal.head.seqOfShare != 0);

        if (isST) {
            if (deal.head.seller != caller) 
                revert ROAKLib_WrongSellor(ia, seqOfDeal, caller);
            if (!_lockUpCheck(gk, ia, deal, closingDeadline)) 
                revert ROAKLib_ShareLocked(ia, seqOfDeal);
        } else {
            if (
                !gk.getROD().isDirector(caller) &&
                gk.getROM().controllor() != caller
            ) revert ROAKLib_WrongSellor(ia, seqOfDeal, caller);
        }

        _vrAndSHACheck(gk, _ia);

        _ia.clearDealCP(seqOfDeal, hashLock, closingDeadline);
    }

    function _vrAndSHACheck(address gk, IInvestmentAgreement _ia) private view {
        
        IMeetingMinutes _bmm = gk.getBMM();
        IMeetingMinutes _gmm = gk.getGMM();
        IRegisterOfAgreements _roa = gk.getROA();

        if (_roa.getHeadOfFile(address(_ia)).state == uint8(FilesRepo.StateOfFile.Approved)) {
            revert ROAKLib_WrongFileState(
                address(_ia), 
                _roa.getHeadOfFile(address(_ia)).state
            );
        }

        uint256 typeOfIA = _ia.getTypeOfIA();

        IShareholdersAgreement _sha = gk.getSHA();

        RulesParser.VotingRule memory vr = 
            _sha.getRule(typeOfIA).votingRuleParser();

        uint seqOfMotion = _roa.getHeadOfFile(address(_ia)).seqOfMotion;

        if (vr.amountRatio > 0 || vr.headRatio > 0) {
            if (vr.authority == 1) {
                if (!_gmm.isPassed(seqOfMotion)) {
                    revert ROAKLib_NotApproved(seqOfMotion);
                }
            } else if (vr.authority == 2) {
                if (!_bmm.isPassed(seqOfMotion)) {
                    revert ROAKLib_NotApproved(seqOfMotion);
                }
            } 
        }
    }

    function _closeDeal(
        address gk,
        IInvestmentAgreement _ia, 
        DealsRepo.Deal memory deal
    ) private {
        if (deal.head.seqOfShare > 0) {
            _shareTransfer(gk, _ia, deal.head.seqOfDeal);
        } else {
            _issueNewShare(gk, _ia, deal.head.seqOfDeal);
        }
    }

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external {
        address gk = address(this);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        if (_ia.closeDeal(deal.head.seqOfDeal, hashKey))
            address(this).getROA().execFile(ia);

        _closeDeal(gk, _ia, deal);
    }

    function _lockUpCheck(
        address gk,
        address _ia,
        DealsRepo.Deal memory deal,
        uint closingDate
    ) private view returns(bool) {

        IShareholdersAgreement _sha = gk.getSHA();
        
        if (!_sha.hasTitle(uint8(IShareholdersAgreement.TitleOfTerm.LockUp))) {
            return true;
        }

        address lu = _sha.getTerm(uint8(IShareholdersAgreement.TitleOfTerm.LockUp));
        
        if (closingDate > 0) {
            deal.head.closingDeadline = uint48(closingDate);
        }

        if (!ILockUp(lu).isTriggered(deal)) {
            return true;
        } else if (ILockUp(lu).isExempted(_ia, deal)) {
            return true;
        }

        return false;
    }

    function _buyerIsVerified(address gk, uint buyer) private view {

        if (
            gk.getROI().getInvestor(buyer).state != 
            uint8(InvestorsRepo.StateOfInvestor.Approved)
        ) revert ROAKLib_BuyerNotVerified(buyer);
        
        if (!gk.getSHA().isSigner(buyer)) 
            revert ROAKLib_BuyerNotSignerOfSHA(buyer);
        
    }

    function _shareTransfer(address gk, IInvestmentAgreement _ia, uint256 seqOfDeal) private {
        
        IRegisterOfShares _ros = gk.getROS();
        IRegisterOfMembers _rom = gk.getROM();

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _buyerIsVerified(gk, deal.body.buyer);

        if (!_lockUpCheck(gk, address(_ia), deal, block.timestamp)) {
            revert ROAKLib_ShareLocked(address(_ia), seqOfDeal);
        }

        if (!_checkAlong(_ia, seqOfDeal)) {
            revert ROAKLib_AlongDealOpen(address(_ia), seqOfDeal);
        }

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

    function issueNewShare(uint caller, address ia, uint256 seqOfDeal) external {
        
        address gk = address(this);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        if(
            !gk.getROD().isDirector(caller) &&
            gk.getROM().controllor() != caller
        ) revert ROAKLib_WrongSellor(ia, seqOfDeal, caller); 

        _vrAndSHACheck(gk, _ia);

        if (_ia.directCloseDeal(seqOfDeal)) gk.getROA().execFile(ia);

        _issueNewShare(gk, _ia, seqOfDeal);
    }

    function _issueNewShare(address gk, IInvestmentAgreement _ia, uint seqOfDeal) private {
        
        IRegisterOfShares _ros = gk.getROS();
        IRegisterOfMembers _rom = gk.getROM();

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _buyerIsVerified(gk, deal.body.buyer);

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
        uint caller,
        address ia,
        uint256 seqOfDeal
    ) public  {

        address gk = address(this);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(
            caller == _ia.getDeal(seqOfDeal).head.seller,
                "ROAK.TTS: not seller"
        );

        _vrAndSHACheck(gk, _ia);

        if (_ia.directCloseDeal(seqOfDeal))
            gk.getROA().execFile(ia);

        _shareTransfer(gk, _ia, seqOfDeal);
    }

    function terminateDeal(
        uint caller,
        address ia,
        uint256 seqOfDeal
    ) external {

        address gk = address(this);

        IRegisterOfAgreements _roa = gk.getROA();

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
                gk.getROS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);            
        } else revert ROAKLib_WrongFileState(ia, state);

    }

    function payOffApprovedDeal(
        uint caller,
        ICashier.TransferAuth memory auth, 
        address ia, 
        uint seqOfDeal,
        address to,
        uint payee
    ) external {
        address gk = address(this);

        ICashier _cashier = gk.getCashier();

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);
        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        auth.value = (deal.body.paid * deal.head.priceOfPaid + 
            (deal.body.par - deal.body.paid) * deal.head.priceOfPar) / 100;
        auth.from = msg.sender;

        if (deal.head.seqOfShare > 0) {
            if (deal.head.seller != payee)
                revert ROAKLib_WrongPayee(payee);

            // remark: PayOffShareTransferDeal
            _cashier.forwardUsd(
                auth, to, 
                bytes32(0x5061794f666653686172655472616e736665724465616c000000000000000000)
            );
        } else {
            if (address(_cashier) != to)
                revert ROAKLib_WrongPayee(payee);

            // remark: PayOffCapIncreaseDeal
            ICashier(_cashier).forwardUsd(
                auth, to, 
                bytes32(0x5061794f6666436170496e6372656173654465616c0000000000000000000000)
            );            
        }

        _payOffApprovedDeal(gk, ia, seqOfDeal, auth.value, caller);
    }

    function _payOffApprovedDeal(
        address gk,
        address ia,
        uint seqOfDeal,
        uint valueOfDeal,
        uint caller
    ) private {
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);
        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _vrAndSHACheck(gk, _ia);

        if (_ia.payOffApprovedDeal(seqOfDeal, valueOfDeal, caller)) 
            gk.getROA().execFile(ia);

        _closeDeal(gk, _ia, deal);
    }

}

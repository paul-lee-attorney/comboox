// SPDX-License-Identifier: UNLICENSED

/* *
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

import "../books/RulesParser.sol";
import "../InterfacesHub.sol";
import "../utils/RoyaltyCharge.sol";
import "../books/DocsRepo.sol";

library ROAKeeper {
    using RulesParser for bytes32;
    using InterfacesHub for address;
    using RoyaltyCharge for address;
    using DocsRepo for DocsRepo.Head;

    // uint32(uint(keccak256("ROAKeeper")));
    uint public constant TYPE_OF_DOC = 0x7eaeb1a4;
    uint public constant VERSION = 1;

    // ###############
    // ##   Error   ##
    // ###############

    error ROAK_WrongParty(bytes32 reason);
    
    error ROAK_WrongState(bytes32 reason);

    error ROAK_ShareLocked(bytes32 reason);

    // ==== Create IA ====

    function createIA(uint version) external {
        address _gk = address(this); 
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        if (!_gk.getROM().isMember(caller)) 
            revert ROAK_WrongParty(bytes32("ROAK_NotMember"));

        DocsRepo.Doc memory doc = _gk.getRCByGK().cloneDoc(
            uint32(uint(keccak256("InvestmentAgreement"))),
            version
        );

        IAccessControl(doc.body).initKeepers(
            _gk, _gk
        );

        _gk.getROA().regFile(DocsRepo.codifyHead(doc.head), doc.body);

        IOwnable(doc.body).setNewOwner(msg.sender);
    }

    // ======== Circulate IA ========

    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        if (!ISigPage(ia).isParty(caller)) {
            revert ROAK_WrongParty(bytes32("ROAK_NotPartyOfIA"));
        }

        if (!IDraftControl(ia).isFinalized()) {
            revert ROAK_WrongState(bytes32("ROAK_IANotFinalized"));
        }

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
        bytes32 sigHash
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        if (!ISigPage(ia).isParty(caller)) {
            revert ROAK_WrongParty(bytes32("ROAK_NotPartyOfIA"));
        }

        IRegisterOfAgreements _roa = _gk.getROA();

        if (
            _roa.getHeadOfFile(ia).state != uint8(FilesRepo.StateOfFile.Circulated)
        ) {
            revert ROAK_WrongState(bytes32("ROAK_IaNotCirculated"));
        }

        _lockDealsOfParty(_gk, ia, caller);

        ISigPage(ia).signDoc(true, caller, sigHash);

    }

    function _lockDealsOfParty(address _gk, address ia, uint256 caller) private {

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
                
                _buyerIsVerified(_gk, deal.body.buyer);
                
                if (deal.head.typeOfDeal ==
                   uint8(DealsRepo.TypeOfDeal.CapitalIncrease)) {
                    IInvestmentAgreement(ia).lockDealSubject(seq);
                }
                
            }
        }
    }

    function _buyerIsVerified(address _gk, uint buyer) private view {
        if (
            _gk.getROI().getInvestor(buyer).state != 
            uint8(InvestorsRepo.StateOfInvestor.Approved)
        ) revert ROAK_WrongParty(bytes32("ROAK_BuyerNotVerified"));
        
        if (!_gk.getSHA().isSigner(buyer)) 
            revert ROAK_WrongParty(bytes32("ROAK_BuyerNotSignerOfSHA"));
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        bool isST = (deal.head.seqOfShare != 0);

        if (isST) {
            if (deal.head.seller != caller) 
                revert ROAK_WrongParty(bytes32("ROAK_CallerNotSeller"));
            if (!_lockUpCheck(_gk, ia, deal, closingDeadline)) 
                revert ROAK_ShareLocked(bytes32("ROAK_TargetShareLocked"));
        } else {
            if (
                !_gk.getROD().isDirector(caller) &&
                _gk.getROM().controllor() != caller
            ) revert ROAK_WrongParty(bytes32("ROAK_NotDirectorOrControllor"));
        }

        _vrAndSHACheck(_gk, _ia);

        _ia.clearDealCP(seqOfDeal, hashLock, closingDeadline);
    }

    function _vrAndSHACheck(address _gk, IInvestmentAgreement _ia) private view {
        IMeetingMinutes _bmm = _gk.getBMM();
        IMeetingMinutes _gmm = _gk.getGMM();
        IRegisterOfAgreements _roa = _gk.getROA();

        if (_roa.getHeadOfFile(address(_ia)).state != uint8(FilesRepo.StateOfFile.Approved)) {
            revert ROAK_WrongState(bytes32("ROAK_IaNotApproved"));
        }

        uint256 typeOfIA = _ia.getTypeOfIA();

        IShareholdersAgreement _sha = _gk.getSHA();

        RulesParser.VotingRule memory vr = 
            _sha.getRule(typeOfIA).votingRuleParser();

        uint seqOfMotion = _roa.getHeadOfFile(address(_ia)).seqOfMotion;

        if (vr.amountRatio > 0 || vr.headRatio > 0) {
            if (vr.authority == 1) {
                if (!_gmm.isPassed(seqOfMotion)) {
                    revert ROAK_WrongState(bytes32("ROAK_GMMNotApproved"));
                }
            } else if (vr.authority == 2) {
                if (!_bmm.isPassed(seqOfMotion)) {
                    revert ROAK_WrongState(bytes32("ROAK_BMMNotApproved"));
                }
            } 
        }
    }    

    // ==== Close Deal ====

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        if (_ia.closeDeal(deal.head.seqOfDeal, hashKey))
            address(this).getROA().execFile(ia);

        _closeDeal(_gk, _ia, deal);
    }

    function _closeDeal(
        address _gk,
        IInvestmentAgreement _ia, 
        DealsRepo.Deal memory deal
    ) private {
        if (deal.head.seqOfShare > 0) {
            _shareTransfer(_gk, _ia, deal.head.seqOfDeal);
        } else {
            _issueNewShare(_gk, _ia, deal.head.seqOfDeal);
        }
    }

    function _shareTransfer(address _gk, IInvestmentAgreement _ia, uint256 seqOfDeal) private {
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _buyerIsVerified(_gk, deal.body.buyer);

        if (!_lockUpCheck(_gk, address(_ia), deal, block.timestamp)) {
            revert ROAK_ShareLocked(bytes32("ROAK_TargetShareLocked"));
        }

        if (!_checkAlong(_ia, seqOfDeal)) {
            revert ROAK_WrongState(bytes32("ROAK_AlongDealOpen"));
        }

        _ros.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _ros.transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, 
            deal.body.buyer, deal.head.priceOfPaid, deal.head.priceOfPar);

        if (deal.body.buyer != deal.body.groupOfBuyer && 
            deal.body.groupOfBuyer != _rom.groupRep(deal.body.buyer)) 
                _rom.addMemberToGroup(deal.body.buyer, deal.body.groupOfBuyer);
    }

    function _lockUpCheck(
        address _gk,
        address _ia,
        DealsRepo.Deal memory deal,
        uint closingDate
    ) private view returns(bool) {

        IShareholdersAgreement _sha = _gk.getSHA();
        
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

    // ==== Issue New Share ====

    function issueNewShare(address ia, uint256 seqOfDeal) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        if(
            !_gk.getROD().isDirector(caller) &&
            _gk.getROM().controllor() != caller
        ) revert ROAK_WrongParty(bytes32("ROAK_NotDirectorOrControllor"));

        _vrAndSHACheck(_gk, _ia);

        if (_ia.directCloseDeal(seqOfDeal)) _gk.getROA().execFile(ia);

        _issueNewShare(_gk, _ia, seqOfDeal);
    }

    function _issueNewShare(address _gk, IInvestmentAgreement _ia, uint seqOfDeal) private {
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _buyerIsVerified(_gk, deal.body.buyer);

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

    // ==== Transfer Target Share ====

    function transferTargetShare(
        address ia,
        uint256 seqOfDeal
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        if (caller != _ia.getDeal(seqOfDeal).head.seller)
            revert ROAK_WrongParty(bytes32("ROAK_NotSeller"));

        _vrAndSHACheck(_gk, _ia);

        if (_ia.directCloseDeal(seqOfDeal))
            _gk.getROA().execFile(ia);

        _shareTransfer(_gk, _ia, seqOfDeal);
    }

    // ==== Terminate Deal ====

    function terminateDeal(
        address ia,
        uint256 seqOfDeal
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        IRegisterOfAgreements _roa = _gk.getROA();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        if (caller != deal.head.seller)
            revert ROAK_WrongParty(bytes32("ROAK_NotSeller"));

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
        } else revert ROAK_WrongState(bytes32("ROAK_IaNotTerminatable"));
    }

    // ==== Pay Off Approved Deal ====

    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, 
        uint seqOfDeal, address to
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);
        uint payee = to.msgSender(TYPE_OF_DOC, VERSION, 58000);

        ICashier _cashier = _gk.getCashier();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        auth.value = (deal.body.paid * deal.head.priceOfPaid + 
            (deal.body.par - deal.body.paid) * deal.head.priceOfPar) / 100;
        auth.from = msg.sender;

        if (deal.head.seqOfShare > 0) {
            if (deal.head.seller != payee)
                revert ROAK_WrongParty(bytes32("ROAK_PayeeNotSeller"));

            // remark: PayOffShareTransferDeal
            _cashier.forwardUsd(
                auth, to, 
                bytes32(0x5061794f666653686172655472616e736665724465616c000000000000000000)
            );
        } else {
            if (address(_cashier) != to)
                revert ROAK_WrongParty(bytes32("ROAK_PayeeNotCashier"));

            // remark: PayOffCapIncreaseDeal
            ICashier(_cashier).forwardUsd(
                auth, to, 
                bytes32(0x5061794f6666436170496e6372656173654465616c0000000000000000000000)
            );            
        }

        _payOffApprovedDeal(_gk, ia, seqOfDeal, auth.value, caller);
    }

    function _payOffApprovedDeal(
        address _gk,
        address ia,
        uint seqOfDeal,
        uint valueOfDeal,
        uint caller
    ) private {
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);
        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _vrAndSHACheck(_gk, _ia);

        if (_ia.payOffApprovedDeal(seqOfDeal, valueOfDeal, caller)) 
            _gk.getROA().execFile(ia);

        _closeDeal(_gk, _ia, deal);
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IROPKeeper.sol";

contract ROPKeeper is IROPKeeper, AccessControl {
    using PledgesRepo for bytes32;
    
    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays,
        uint256 caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IBookOfShares _bos = _gk.getBOS();

        PledgesRepo.Head memory head = snOfPld.snParser();
        
        head.pledgor = _bos.getShare(head.seqOfShare).head.shareholder;

        require(head.pledgor == caller, "BOPK.createPld: NOT shareholder");

        head = _gk.getROP().createPledge(
            snOfPld,
            paid,
            par,
            guaranteedAmt,
            execDays
        );

        _bos.decreaseCleanPaid(head.seqOfShare, paid);
    }

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint256 caller
    ) external onlyDK {
        _getGK().getROP().transferPledge(seqOfShare, seqOfPld, buyer, amt, caller);
    }

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        uint256 caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();

        PledgesRepo.Pledge memory pld = 
            _gk.getROP().refundDebt(seqOfShare, seqOfPld, amt, caller);

        _gk.getBOS().increaseCleanPaid(seqOfShare, pld.body.paid);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        uint256 caller
    ) external onlyDK {
        _getGK().getROP().extendPledge(seqOfShare, seqOfPld, extDays, caller);    
    }

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint256 caller
    ) external onlyDK {        
        _getGK().getROP().lockPledge(seqOfShare, seqOfPld, hashLock, caller);    
    }

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();

        uint64 paid = _gk.getROP().releasePledge(seqOfShare, seqOfPld, hashKey);
        _gk.getBOS().increaseCleanPaid(seqOfShare, paid);
    }

    function execPledge(
        bytes32 snOfDeal,
        uint256 seqOfPld,
        uint version,
        address primeKeyOfCaller,
        uint buyer,
        uint groupOfBuyer,
        uint caller
    ) external onlyDK {
        DealsRepo.Deal memory deal;
        deal.head = DealsRepo.snParser(snOfDeal);

        IInvestmentAgreement _ia = IInvestmentAgreement(
            _createIA(deal.head.seqOfShare, seqOfPld, version, primeKeyOfCaller, caller)
        );

        IGeneralKeeper _gk = _getGK();

        PledgesRepo.Pledge memory pld = 
            _gk.getROP().getPledge(deal.head.seqOfShare, seqOfPld);

        deal.body.buyer = uint40(buyer);
        deal.body.groupOfBuyer = uint40(groupOfBuyer);
        deal.body.paid = uint64(pld.body.paid);
        deal.body.par = uint64(pld.body.par);

        deal.head.typeOfDeal = _gk.getROM().isMember(buyer) ? 3 : 2;

        deal = _circulateIA(deal, _ia);

        _signIA(_ia, deal);

        _proposeIA(address(_ia), deal, caller);
    }

    function _createIA(
        uint seqOfShare,
        uint seqOfPld,
        uint version,
        address primeKeyOfCaller,
        uint caller        
    ) private returns(address) {
        IGeneralKeeper _gk = _getGK();

        _gk.getROP().execPledge(seqOfShare, seqOfPld, caller);

        bytes32 snOfDoc = bytes32((uint(uint8(IRegCenter.TypeOfDoc.IA)) << 240) +
            (version << 224)); 

        DocsRepo.Doc memory doc = _getRC().createDoc(
            snOfDoc,
            primeKeyOfCaller
        );

        IAccessControl(doc.body).init(
            address(this),
            address(this),
            address(_getRC()),
            address(_gk)
        );

        _gk.getROA().regFile(DocsRepo.codifyHead(doc.head), doc.body);

        return doc.body;        
    }

    function _circulateIA(
        DealsRepo.Deal memory deal,
        IInvestmentAgreement _ia
    ) private returns (DealsRepo.Deal memory) {
        deal.head.seqOfDeal = _ia.regDeal(deal);

        _ia.finalizeIA();

        IGeneralKeeper _gk = _getGK();

        RulesParser.VotingRule memory vr = 
            RulesParser.votingRuleParser(_gk.getSHA().getRule(deal.head.typeOfDeal));

        _gk.getROA().circulateFile(
            address(_ia), 0, 
            uint16((deal.head.closingDeadline - uint48(block.timestamp) + 43200)/86400), 
            vr, bytes32(0), bytes32(0)
        );

        return deal;
    }

    function _signIA(
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal
    ) private {
        _ia.lockDealSubject(deal.head.seqOfDeal);
        
        ISigPage(address(_ia)).regSig(
            deal.head.seqOfDeal,
            deal.head.seller,
            uint48(block.timestamp),
            bytes32(0)
        );

        ISigPage(address(_ia)).regSig(
            deal.head.seqOfDeal,
            deal.body.buyer,
            uint48(block.timestamp),
            bytes32(0)
        );

        _getGK().getROA().establishFile(address(_ia));
    }

    function _proposeIA(
        address ia,
        DealsRepo.Deal memory deal,
        uint caller
    ) private {
        IGeneralKeeper _gk = _getGK();

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToApproveDoc(uint(uint160(ia)), deal.head.typeOfDeal, caller, deal.head.seller);
        
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, deal.head.seller);
        _gk.getROA().proposeFile(ia, seqOfMotion);       
    }


    function revokePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();

        IRegisterOfPledges _rop = _gk.getROP();

        PledgesRepo.Pledge memory pld = _rop.getPledge(seqOfShare, seqOfPld);
        require(pld.head.pledgor == caller, "BOPK.RP: not pledgor");

        _rop.revokePledge(seqOfShare, seqOfPld, caller);
        _gk.getBOS().increaseCleanPaid(seqOfShare, pld.body.paid);   
        
    }
}

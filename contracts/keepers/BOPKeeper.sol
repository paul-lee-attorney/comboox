// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IBOPKeeper.sol";

contract BOPKeeper is IBOPKeeper, AccessControl {
    using PledgesRepo for bytes32;

    IGeneralKeeper private _gk = _getGK();
    IBookOfMembers private _bom = _gk.getBOM();
    IMeetingMinutes private _gmm = _gk.getGMM();
    IBookOfIA private _boi = _gk.getBOI();
    IBookOfPledges private _bop = _gk.getBOP();
    IBookOfShares private _bos = _gk.getBOS();
    
    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays,
        uint256 caller
    ) external onlyDK {

        PledgesRepo.Head memory head = snOfPld.snParser();
        
        head.pledgor = _bos.getShare(head.seqOfShare).head.shareholder;

        require(head.pledgor == caller, "BOPK.createPld: NOT shareholder");

        head = _bop.createPledge(
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
        _bop.transferPledge(seqOfShare, seqOfPld, buyer, amt, caller);
    }

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        uint256 caller
    ) external onlyDK {

        PledgesRepo.Pledge memory pld = 
            _bop.refundDebt(seqOfShare, seqOfPld, amt, caller);

        _bos.increaseCleanPaid(seqOfShare, pld.body.paid);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        uint256 caller
    ) external onlyDK {
        _bop.extendPledge(seqOfShare, seqOfPld, extDays, caller);    
    }

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint256 caller
    ) external onlyDK {        
        _bop.lockPledge(seqOfShare, seqOfPld, hashLock, caller);    
    }

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey
    ) external onlyDK {

        uint64 paid = _bop.releasePledge(seqOfShare, seqOfPld, hashKey);
        _bos.increaseCleanPaid(seqOfShare, paid);
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

        PledgesRepo.Pledge memory pld = 
            _bop.getPledge(deal.head.seqOfShare, seqOfPld);

        deal.body.buyer = uint40(buyer);
        deal.body.groupOfBuyer = uint40(groupOfBuyer);
        deal.body.paid = uint64(pld.body.paid);
        deal.body.par = uint64(pld.body.par);

        deal.head.typeOfDeal = _bom.isMember(buyer) ? 3 : 2;

        deal = _circulateIA(deal, _ia);

        _proposeIA(address(_ia), deal, pld, caller);
    }

    function _createIA(
        uint seqOfShare,
        uint seqOfPld,
        uint version,
        address primeKeyOfCaller,
        uint caller        
    ) private returns(address) {
        _bop.execPledge(seqOfShare, seqOfPld, caller);

        bytes32 snOfDoc = bytes32((uint(uint8(IRegCenter.TypeOfDoc.IA)) << 240) +
            (version << 224)); 

        DocsRepo.Doc memory doc = _getRC().createDoc(
            snOfDoc,
            primeKeyOfCaller
        );

        IAccessControl(doc.body).init(
            primeKeyOfCaller,
            address(this),
            address(_getRC()),
            address(_gk)
        );

        _boi.regFile(DocsRepo.codifyHead(doc.head), doc.body);

        return doc.body;        
    }

    function _circulateIA(
        DealsRepo.Deal memory deal,
        IInvestmentAgreement _ia
    ) private returns (DealsRepo.Deal memory) {
        deal.head.seqOfDeal = _ia.regDeal(deal);

        _ia.setTypeOfIA(deal.head.typeOfDeal);

        RulesParser.VotingRule memory vr = 
            RulesParser.votingRuleParser(_gk.getSHA().getRule(deal.head.typeOfDeal));

        _boi.circulateFile(
            address(_ia), 0, 
            uint16((deal.head.closingDeadline - uint48(block.timestamp) + 43200)/86400), 
            vr, bytes32(0), bytes32(0)
        );

        return deal;
    }

    function _signIA(
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        PledgesRepo.Pledge memory pld
    ) private {
        _ia.lockDealSubject(deal.head.seqOfDeal);
        
        ISigPage(address(_ia)).regSig(
            deal.head.seqOfDeal,
            pld.head.pledgor,
            uint48(block.timestamp),
            bytes32(0)
        );

        ISigPage(address(_ia)).regSig(
            deal.head.seqOfDeal,
            deal.body.buyer,
            uint48(block.timestamp),
            bytes32(0)
        );

        _boi.establishFile(address(_ia));
    }

    function _proposeIA(
        address ia,
        DealsRepo.Deal memory deal,
        PledgesRepo.Pledge memory pld,
        uint caller
    ) private {
        uint64 seqOfMotion = 
            _gmm.createMotionToApproveDoc(ia, deal.head.typeOfDeal, caller, pld.head.pledgor);
        
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, pld.head.pledgor);
        _boi.proposeFile(ia, seqOfMotion);       
    }


    function revokePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external onlyDK {

        PledgesRepo.Pledge memory pld = _bop.getPledge(seqOfShare, seqOfPld);
        require(pld.head.pledgor == caller, "BOPK.RP: not pledgor");

        _bop.revokePledge(seqOfShare, seqOfPld, caller);
        _bos.increaseCleanPaid(seqOfShare, pld.body.paid);   
        
    }
}

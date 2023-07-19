// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IROSKeeper.sol";

import "../common/access/AccessControl.sol";

contract ROSKeeper is IROSKeeper, AccessControl {
    // using SwapsRepo for SwapsRepo.Repo;

    IGeneralKeeper private _gk = _getGK();
    IMeetingMinutes private _gmm = _gk.getGMM();
    IRegisterOfSwaps private _ros = _gk.getROS();
    IBookOfShares private _bos = _gk.getBOS();

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(uint256 seqOfSwap, uint caller) {
        require(_ros.getSwap(seqOfSwap).body.rightholder == caller,
            "ROSK.md.OR: not rightholder");
        _;        
    }

    modifier onlyObligor(uint256 seqOfSwap, uint caller) {
        require(_ros.getSwap(seqOfSwap).head.obligor == caller,
            "ROSK.md.OO: not obligor");
        _;        
    }


    // ##################
    // ##    Write     ##
    // ##################

    function createSwap(
        bytes32 snOfSwap,
        uint rightholder, 
        uint paidOfConsider,
        uint caller
    ) external onlyDK {
        require(caller == SwapsRepo.snParser(snOfSwap).obligor,
            "ROSK.CS: not obligor");
        _ros.createSwap(snOfSwap, rightholder, paidOfConsider);
    }

    function transferSwap(
        uint256 seqOfSwap, 
        uint to, 
        uint amt,
        uint caller
    ) external onlyDK onlyRightholder(seqOfSwap, caller) {
        _ros.transferSwap(seqOfSwap, to, amt);
    }

    function crystalizeSwap(
        uint256 seqOfSwap, 
        uint seqOfConsider, 
        uint seqOfTarget,
        uint caller
    ) external onlyDK onlyRightholder(seqOfSwap, caller) {
        _ros.crystalizeSwap(seqOfSwap, seqOfConsider, seqOfTarget);
    }

    function lockSwap(
        uint256 seqOfSwap, 
        bytes32 hashLock,
        uint caller
    ) external onlyDK onlyRightholder(seqOfSwap, caller) {
        _ros.lockSwap(seqOfSwap, hashLock);        
    }

    function releaseSwap(uint256 seqOfSwap, string memory hashKey)
        external onlyDK
    {
        _ros.releaseSwap(seqOfSwap, hashKey);
    } 

    function execSwap(uint256 seqOfSwap, uint caller) external 
        onlyDK onlyRightholder(seqOfSwap, caller) 
    {
        _ros.execSwap(seqOfSwap);
    }

    function revokeSwap(uint256 seqOfSwap, uint caller) external
        onlyDK onlyObligor(seqOfSwap, caller) 
    {
        _ros.revokeSwap(seqOfSwap);
    }

    function requestToBuy(
        uint256 seqOfMotion,
        uint256 seqOfDeal,
        uint seqOfTarget,
        uint256 caller
    ) external onlyDK {

        MotionsRepo.Motion memory motion = 
            _gmm.getMotion(seqOfMotion);

        require(
            motion.body.state == uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy),
            "BOGK.RTB: NO need to buy"
        );

        DealsRepo.Deal memory deal = 
            IInvestmentAgreement(address(uint160(motion.contents))).getDeal(seqOfDeal);

        require(caller == deal.head.seller, "BOGK.RTB: not Seller");

        SharesRepo.Share memory target = _bos.getShare(seqOfTarget);

        require(_gmm.getBallot(seqOfMotion, _gmm.getDelegateOf(seqOfMotion, target.head.shareholder)).attitude == 2,
            "BOGK.RTB: not vetoer");

        require(block.timestamp < motion.body.voteEndDate + 
            uint48(motion.votingRule.execDaysForPutOpt) * 86400, 
            "BOGK.RTB: missed EXEC deadline");

        SwapsRepo.Swap memory swap;

        swap.head = SwapsRepo.Head({
            seqOfSwap: 0,
            classOfTarget: target.head.class,
            classOfConsider: deal.head.classOfShare,
            createDate: uint48(block.timestamp),
            triggerDate: uint48(block.timestamp),
            closingDays: uint16((deal.head.closingDeadline + 43200 - block.timestamp) / 86400),
            obligor: target.head.shareholder,
            rateOfSwap: deal.head.priceOfPaid * 10000 / target.head.priceOfPaid,
            para: 0
        });

        swap = _ros.regSwap(swap);
        swap.body = _ros.crystalizeSwap(swap.head.seqOfSwap, deal.head.seqOfShare, seqOfTarget);
    }
}

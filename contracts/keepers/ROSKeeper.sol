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

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(uint256 seqOfSwap, uint caller) {
        require(_gk.getROS().getSwap(seqOfSwap).body.rightholder == caller,
            "ROSK.md.OR: not rightholder");
        _;        
    }

    modifier onlyObligor(uint256 seqOfSwap, uint caller) {
        require(_gk.getROS().getSwap(seqOfSwap).head.obligor == caller,
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
    ) external onlyDirectKeeper {
        require(caller == SwapsRepo.snParser(snOfSwap).obligor,
            "ROSK.CS: not obligor");
        _gk.getROS().createSwap(snOfSwap, rightholder, paidOfConsider);
    }

    function transferSwap(
        uint256 seqOfSwap, 
        uint to, 
        uint amt,
        uint caller
    ) external onlyDirectKeeper onlyRightholder(seqOfSwap, caller) {
        _gk.getROS().transferSwap(seqOfSwap, to, amt);
    }

    function crystalizeSwap(
        uint256 seqOfSwap, 
        uint seqOfConsider, 
        uint seqOfTarget,
        uint caller
    ) external onlyDirectKeeper onlyRightholder(seqOfSwap, caller) {
        _gk.getROS().crystalizeSwap(seqOfSwap, seqOfConsider, seqOfTarget);
    }

    function lockSwap(
        uint256 seqOfSwap, 
        bytes32 hashLock,
        uint caller
    ) external onlyDirectKeeper onlyRightholder(seqOfSwap, caller) {
        _gk.getROS().lockSwap(seqOfSwap, hashLock);        
    }

    function releaseSwap(uint256 seqOfSwap, string memory hashKey)
        external onlyDirectKeeper
    {
        _gk.getROS().releaseSwap(seqOfSwap, hashKey);
    } 

    function execSwap(uint256 seqOfSwap, uint caller) external 
        onlyDirectKeeper onlyRightholder(seqOfSwap, caller) 
    {
        _gk.getROS().execSwap(seqOfSwap);
    }

    function revokeSwap(uint256 seqOfSwap, uint caller) external
        onlyDirectKeeper onlyObligor(seqOfSwap, caller) 
    {
        _gk.getROS().revokeSwap(seqOfSwap);
    }

    function requestToBuy(
        uint256 seqOfMotion,
        uint256 seqOfDeal,
        uint seqOfTarget,
        uint256 caller
    ) external onlyDirectKeeper {

        IMeetingMinutes _gmm = _gk.getGMM();

        MotionsRepo.Motion memory motion = 
            _gmm.getMotion(seqOfMotion);

        require(
            motion.body.state == uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy),
            "BOGK.RTB: NO need to buy"
        );

        DealsRepo.Deal memory deal = 
            IInvestmentAgreement(address(uint160(motion.contents))).getDeal(seqOfDeal);

        require(caller == deal.head.seller, "BOGK.RTB: not Seller");

        SharesRepo.Share memory target = _gk.getBOS().getShare(seqOfTarget);

        require(_gmm.getBallot(seqOfMotion, _gmm.getDelegateOf(seqOfMotion, target.head.shareholder)).attitude == 2,
            "BOGK.RTB: not vetoer");

        require(block.timestamp < motion.body.voteEndDate + 
            uint48(motion.votingRule.execDaysForPutOpt) * 86400, 
            "BOGK.RTB: missed EXEC date");

        SwapsRepo.Swap memory swap;

        swap.head = SwapsRepo.Head({
            seqOfSwap: 0,
            classOfTarget: target.head.class,
            classOfConsider: deal.head.classOfShare,
            createDate: uint48(block.timestamp),
            triggerDate: uint48(block.timestamp),
            closingDays: uint16((deal.head.closingDate + 43200 - block.timestamp) / 86400),
            obligor: target.head.shareholder,
            rateOfSwap: deal.head.priceOfPaid * 10000 / target.head.priceOfPaid,
            para: 0
        });

        IRegisterOfSwaps _ros = _gk.getROS();

        swap = _ros.regSwap(swap);
        swap.body = _ros.crystalizeSwap(swap.head.seqOfSwap, deal.head.seqOfShare, seqOfTarget);
    }
}

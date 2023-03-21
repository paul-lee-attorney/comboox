// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bos/IBookOfShares.sol";
import "./SharesRepo.sol";
import "./EnumerableSet.sol";

library SwapsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    enum StateOfSwap {
        Pending,
        Issued,
        Crystalized,
        Locked,
        Released,
        Executed,
        Revoked
    }

    struct Head {
        uint32 seqOfSwap;
        uint16 classOfTarget;
        uint16 classOfConsider;
        uint48 createDate;
        uint48 triggerDate;
        uint16 closingDays;
        uint40 obligor;
        uint32 rateOfSwap;
        uint8 state;
    }

    struct Body {
        uint40 rightholder;
        uint32 seqOfConsider;
        uint64 paidOfConsider;
        uint32 seqOfTarget;
        uint64 paidOfTarget;
    }

    struct Swap {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    struct Repo{
        // seqOfSwap => Swap
        mapping(uint256 => Swap) swaps;
        EnumerableSet.UintSet snList;
    }

    //##################
    //##    写接口    ##
    //##################

    function snParser(uint256 sn) public pure returns (Head memory head) {
        head = Head({
            seqOfSwap: uint32(sn >> 224),
            classOfTarget: uint16(sn >> 208),
            classOfConsider: uint16(sn >> 192),
            createDate: uint48(sn >> 144),
            triggerDate: uint48(sn >> 96),
            closingDays: uint16(sn >> 80),
            obligor: uint40(sn >> 40),
            rateOfSwap: uint32(sn >> 8),
            state: 0
        });
    } 

    function codifyHead(Head memory head) public pure returns (uint256 sn) {
        sn = (uint256(head.seqOfSwap) << 224) +
            (uint256(head.classOfTarget) << 208) +
            (uint256(head.classOfConsider) << 192) +
            (uint256(head.createDate) << 144) +
            (uint256(head.triggerDate) << 96) +
            (uint256(head.closingDays) << 80) +
            (uint256(head.obligor) << 40) +
            (uint256(head.rateOfSwap) << 8);
    } 

    function createSwap(
            Repo storage repo, 
            uint256 sn,
            uint40 rightholder, 
            uint64 paidOfConsider
    ) public returns (Head memory head) 
    {
        head = snParser(sn);
        head = issueSwap(repo, head, rightholder, paidOfConsider);
    }

    function issueSwap(
        Repo storage repo,
        Head memory head,
        uint40 rightholder, 
        uint64 paidOfConsider
    ) public returns(Head memory regHead) {
        Swap memory swap;

        head.createDate = uint48(block.timestamp);
        head.state = uint8(StateOfSwap.Issued);

        swap.head = head;

        swap.body.rightholder = rightholder;
        swap.body.paidOfConsider = paidOfConsider;

        regHead = regSwap(repo, swap);
    }

    function regSwap(
        Repo storage repo,
        Swap memory swap
    ) public returns(Head memory regHead){
        swap.head.seqOfSwap = _increaseCounterOfSwap(repo);

        repo.swaps[swap.head.seqOfSwap] = swap;
        repo.snList.add(codifyHead(swap.head));

        regHead = swap.head;
    }

    function decreaseAmtOfSwap(
        Swap storage swap,
        uint40 caller,
        uint64 amt
    ) public returns(bool flag) {

        require(block.timestamp < swap.head.triggerDate + uint48(swap.head.closingDays) * 86400,
            "SR.DAOS: swap expired");
        require(caller == swap.body.rightholder, "SR.DAOS: caller not rightholder");
        require(swap.body.paidOfConsider >= amt, "SR.DAOS: amt overflow");

        if (swap.head.state < uint8(StateOfSwap.Locked)) {
            swap.body.paidOfConsider -= amt;
            
            if (swap.body.paidOfConsider == 0) 
                swap.head.state == uint8(StateOfSwap.Revoked);
            else if (swap.head.state == uint8(StateOfSwap.Crystalized)) {
                swap.body.paidOfTarget -= amt * uint64(swap.head.rateOfSwap) / 10000;
            }
            
            flag = true;
        }
    }

    function transferSwap(
        Repo storage repo,
        uint32 seqOfSwap,
        uint40 caller,
        uint40 buyer,
        uint64 amt 
    ) public returns(Head memory head) {

        Swap storage swap = repo.swaps[seqOfSwap];

        require(swap.head.state >= uint8(StateOfSwap.Issued), "SR.TS: wrong state");

        Swap memory newSwap = swap;

        decreaseAmtOfSwap(swap, caller, amt);

        newSwap.body.rightholder = buyer;
        newSwap.body.paidOfConsider = amt;

        if (newSwap.head.state == uint8(StateOfSwap.Crystalized))
            newSwap.body.paidOfTarget = amt * uint64(newSwap.head.rateOfSwap) / 10000;
        
        head = regSwap(repo, newSwap);
    }

    function crystalizeSwap(
        Swap storage swap,
        uint40 caller,
        uint32 seqOfConsider,
        uint32 seqOfTarget,
        IBookOfShares _bos
    ) public returns (Body memory){
        require(caller == swap.body.rightholder, "SR.CS: caller not rightholder");
        require(block.timestamp < swap.head.triggerDate + uint48(swap.head.closingDays) * 86400,
            "SR.CS: swap expired");

        require(swap.head.state == uint8(StateOfSwap.Issued), "SR.CS: wrong state");

        SharesRepo.Share memory consider = _bos.getShare(seqOfConsider);
        SharesRepo.Share memory target = _bos.getShare(seqOfTarget);

        require(consider.head.shareholder == swap.body.rightholder, 
            "SR.CS: consider not rightholder's share");
        require(target.head.shareholder == swap.head.obligor, 
            "SR.CS: consider not obligor's share");
        require(consider.head.class == swap.head.classOfConsider, 
            "SR.CS: wrong classOfConsider");
        require(target.head.class == swap.head.classOfTarget, 
            "SR.CS: wrong classOfTarget");

        uint64 paidOfTarget = swap.body.paidOfConsider * uint64(swap.head.rateOfSwap) / 10000;

        swap.body = Body({
            rightholder: swap.body.rightholder,
            seqOfConsider: seqOfConsider,
            paidOfConsider: swap.body.paidOfConsider,
            seqOfTarget: seqOfTarget,
            paidOfTarget: paidOfTarget
        });

        swap.head.state = uint8(StateOfSwap.Crystalized);

        return swap.body;
    }

    function lockSwap(
        Swap storage swap,
        uint40 caller,
        bytes32 hashLock
    ) public returns (bool flag){
        require (block.timestamp < swap.head.triggerDate + uint48(swap.head.closingDays) * 86400, 
            "SR.LS: swap expired");

        require (caller == swap.body.rightholder, "SR.LS: caller not rightholder");

        if (swap.head.state == uint8(StateOfSwap.Issued) || 
            swap.head.state == uint8(StateOfSwap.Crystalized)){
            swap.head.state = uint8(StateOfSwap.Locked);
            swap.hashLock = hashLock;
            flag = true;
        }
    }

    function releaseSwap(
        Swap storage swap,
        uint40 caller,
        string memory hashKey
    ) public returns (bool flag){
        require (caller == swap.head.obligor, "SR.RS: caller not obligor");

        require (swap.head.state == uint8(StateOfSwap.Locked), "PR.RS: wrong state");
        if (swap.hashLock == keccak256(bytes(hashKey))) {
            swap.head.state = uint8(StateOfSwap.Released);

            flag = true;
        }
    }

    function execSwap(Swap storage swap, uint40 caller) public returns(bool flag)
    {
        require(block.timestamp >= swap.head.triggerDate && 
            block.timestamp < swap.head.triggerDate + uint48(swap.head.closingDays) * 86400,
            "SR.ES: swap not in exec period");

        require(caller == swap.body.rightholder, "SR.ES: caller not rightholder");

        if (swap.head.state == uint8(StateOfSwap.Crystalized) ||
            swap.head.state == uint8(StateOfSwap.Locked))
        {
            swap.head.state = uint8(StateOfSwap.Executed);
            flag = true;
        }        
    }

    function reovkeSwap(Swap storage swap, uint40 caller) public returns(bool flag)
    {
        require(block.timestamp > swap.head.triggerDate + uint48(swap.head.closingDays) * 86400,
            "SR.ES: swap not expired");

        if (caller == swap.head.obligor || caller == swap.body.rightholder) {
            swap.head.state = uint8(StateOfSwap.Revoked);
            flag = true;
        }
    }

    function _increaseCounterOfSwap(Repo storage repo) 
        private returns (uint32 seqOfSwap) 
    {
        repo.swaps[0].head.seqOfSwap++;
        seqOfSwap = repo.swaps[0].head.seqOfSwap;
    }

    //#################
    //##    读接口    ##
    //#################

    function counterOfSwap(Repo storage repo) 
        public view returns (uint32) 
    {
        return repo.swaps[0].head.seqOfSwap;
    }

    function getSwaps(Repo storage repo) 
        public view returns (Swap[] memory) 
    {
        uint256 len = counterOfSwap(repo);

        require(len > 0, "SR.GSs: no swaps found");

        Swap[] memory output = new Swap[](len);

        while (len > 0) {
            output[len - 1] = repo.swaps[len];
            len--;
        }

        return output;
    }

    function getSnList(Repo storage repo) public view returns (uint256[] memory list)
    {
        list = repo.snList.values();
    }

}

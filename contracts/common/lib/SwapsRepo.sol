// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../IGeneralKeeper.sol";
import "../../books/bom/IBookOfMembers.sol";
import "../../books/bos/IBookOfShares.sol";

import "./EnumerableSet.sol";
import "./SharesRepo.sol";

library SwapsRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

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
        uint8 para;
    }

    struct Body {
        uint40 rightholder;
        uint32 seqOfConsider;
        uint64 paidOfConsider;
        uint32 seqOfTarget;
        uint64 paidOfTarget;
        uint8 state;
        uint16 para;
    }

    struct Swap {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    struct Repo{
        // seqOfSwap => Swap
        mapping(uint256 => Swap) swaps;
        EnumerableSet.Bytes32Set snList;
    }

    //##################
    //##    写接口    ##
    //##################

    function snParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        head = Head({
            seqOfSwap: uint32(_sn >> 224),
            classOfTarget: uint16(_sn >> 208),
            classOfConsider: uint16(_sn >> 192),
            createDate: uint48(_sn >> 144),
            triggerDate: uint48(_sn >> 96),
            closingDays: uint16(_sn >> 80),
            obligor: uint40(_sn >> 40),
            rateOfSwap: uint32(_sn >> 8),
            para: uint8(_sn)
        });
    } 

    function codifyHead(Head memory head) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encode(
                            head.seqOfSwap,
                            head.classOfTarget,
                            head.classOfConsider,
                            head.createDate,
                            head.triggerDate,
                            head.closingDays,
                            head.obligor,
                            head.rateOfSwap,
                            head.para);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    } 

    function createSwap(
            Repo storage repo, 
            bytes32 sn,
            uint rightholder, 
            uint paidOfConsider,
            IGeneralKeeper _gk
    ) public returns (Head memory head) 
    {
        head = snParser(sn);
        head = issueSwap(repo, head, rightholder, paidOfConsider, _gk);
    }

    function issueSwap(
        Repo storage repo,
        Head memory head,
        uint rightholder, 
        uint paidOfConsider,
        IGeneralKeeper _gk
    ) public returns(Head memory ) {
        Swap memory swap;

        head.createDate = uint48(block.timestamp);

        swap.head = head;

        swap.body.rightholder = uint40(rightholder);
        swap.body.paidOfConsider = uint64(paidOfConsider);
        swap.body.state = uint8(StateOfSwap.Issued);

        return regSwap(repo, swap, _gk).head;
    }

    function regSwap(
        Repo storage repo,
        Swap memory swap,
        IGeneralKeeper _gk
    ) public returns(Swap memory){
        require(_gk.getBOM().isClassMember(swap.head.obligor, swap.head.classOfTarget), 
            "SR.RS: obligor not memberOfTargetClass");
        require(_gk.getBOM().isClassMember(swap.body.rightholder, swap.head.classOfConsider), 
            "SR.RS: rightholder not memberOfConsiderClass");

        require(block.timestamp <= swap.head.triggerDate, "SR.RS: triggerDate not future");
        require(block.timestamp >= swap.head.createDate, "SR.RS: future createDate");

        require(swap.head.rateOfSwap > 0, "SR.RS: zero rateOfSwap");
        require(swap.body.paidOfConsider > 0, "SR.RS: zero paidOfConsider");

        swap.head.seqOfSwap = _increaseCounterOfSwap(repo);

        repo.swaps[swap.head.seqOfSwap] = swap;
        repo.snList.add(codifyHead(swap.head));

        return swap;
    }

    function decreaseAmtOfSwap(
        Swap storage swap,
        uint amt
    ) public returns(bool flag) {

        require(block.timestamp < swap.head.triggerDate + uint48(swap.head.closingDays) * 86400,
            "SR.DAOS: swap expired");
        require(swap.body.paidOfConsider >= amt, "SR.DAOS: amt overflow");

        if (swap.body.state < uint8(StateOfSwap.Locked)) {
            swap.body.paidOfConsider -= uint64(amt);
            
            if (swap.body.paidOfConsider == 0) 
                swap.body.state == uint8(StateOfSwap.Revoked);
            else if (swap.body.state == uint8(StateOfSwap.Crystalized)) {
                swap.body.paidOfTarget -= uint64(amt * swap.head.rateOfSwap) / 10000;
            }
            
            flag = true;
        }
    }

    function splitSwap(
        Repo storage repo,
        uint256 seqOfSwap,
        uint buyer,
        uint amt,
        IGeneralKeeper _gk
    ) public returns(Head memory) {
        Swap storage swap = repo.swaps[seqOfSwap];

        require(swap.body.state >= uint8(StateOfSwap.Issued), "SR.SS: wrong state");

        Swap memory newSwap = swap;

        decreaseAmtOfSwap(swap, amt);

        if (buyer > 0) newSwap.body.rightholder = uint40(buyer);
        newSwap.body.paidOfConsider = uint64(amt);

        if (newSwap.body.state == uint8(StateOfSwap.Crystalized))
            newSwap.body.paidOfTarget = uint64(amt * newSwap.head.rateOfSwap) / 10000;
        
        return regSwap(repo, newSwap, _gk).head;
    }

    function crystalizeSwap(
        Swap storage swap,
        uint seqOfConsider,
        uint seqOfTarget,
        IGeneralKeeper _gk
    ) public returns (Body memory){
        require(block.timestamp < swap.head.triggerDate + uint48(swap.head.closingDays) * 86400,
            "SR.CS: swap expired");

        require(swap.body.state == uint8(StateOfSwap.Issued), "SR.CS: wrong state");

        SharesRepo.Share memory consider = _gk.getBOS().getShare(seqOfConsider);
        SharesRepo.Share memory target = _gk.getBOS().getShare(seqOfTarget);

        require(consider.head.shareholder == swap.body.rightholder, 
            "SR.CS: consider not rightholder's share");
        require(target.head.shareholder == swap.head.obligor, 
            "SR.CS: consider not obligor's share");
        require(consider.head.class == swap.head.classOfConsider, 
            "SR.CS: wrong classOfConsider");
        require(target.head.class == swap.head.classOfTarget, 
            "SR.CS: wrong classOfTarget");

        require(consider.body.cleanPaid >= swap.body.paidOfConsider,
            "SR.CS: considerShare insufficient of cleanPaid");
        
        uint64 paidOfTarget = swap.body.paidOfConsider * uint64(swap.head.rateOfSwap) / 10000;

        require(target.body.cleanPaid >= paidOfTarget,
            "SR.CS: targetShare insufficient of cleanPaid");

        swap.body = Body({
            rightholder: swap.body.rightholder,
            seqOfConsider: uint32(seqOfConsider),
            paidOfConsider: swap.body.paidOfConsider,
            seqOfTarget: uint32(seqOfTarget),
            paidOfTarget: paidOfTarget,
            state: uint8(StateOfSwap.Crystalized),
            para: 0
        });

        return swap.body;
    }

    function lockSwap(
        Swap storage swap,
        bytes32 hashLock
    ) public returns (bool flag){
        require (block.timestamp < swap.head.triggerDate + uint48(swap.head.closingDays) * 86400, 
            "SR.LS: swap expired");

        require (hashLock != bytes32(0), "SR.LS: zero hashLock");

        if (swap.body.state == uint8(StateOfSwap.Issued) || 
            swap.body.state == uint8(StateOfSwap.Crystalized)){
            swap.body.state = uint8(StateOfSwap.Locked);
            swap.hashLock = hashLock;
            flag = true;
        }
    }

    function releaseSwap(
        Swap storage swap,
        string memory hashKey
    ) public returns (bool flag){
        require (swap.body.state == uint8(StateOfSwap.Locked), "PR.RS: wrong state");
        if (swap.hashLock == keccak256(bytes(hashKey))) {
            swap.body.state = uint8(StateOfSwap.Released);
            flag = true;
        }
    }

    function execSwap(Swap storage swap) public returns(bool flag)
    {
        require(block.timestamp >= swap.head.triggerDate && 
            block.timestamp < swap.head.triggerDate + uint48(swap.head.closingDays) * 86400,
            "SR.ES: swap not in exec period");

        if (swap.body.state == uint8(StateOfSwap.Crystalized) ||
            swap.body.state == uint8(StateOfSwap.Locked))
        {
            swap.body.state = uint8(StateOfSwap.Executed);
            flag = true;
        }        
    }

    function revokeSwap(Swap storage swap) public returns(bool flag)
    {
        require(block.timestamp > swap.head.triggerDate + uint48(swap.head.closingDays) * 86400,
            "SR.ES: swap not expired");

        if (swap.body.state < uint8(StateOfSwap.Released)) {
            swap.body.state = uint8(StateOfSwap.Revoked);
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

    function getSNList(Repo storage repo) public view returns (bytes32[] memory list)
    {
        list = repo.snList.values();
    }

}

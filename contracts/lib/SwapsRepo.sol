// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library SwapsRepo {

    enum StateOfSwap {
        Pending,    
        Issued,
        Closed,
        Terminated
    }

    struct Swap {
        uint16 seqOfSwap;
        uint32 seqOfPledge;
        uint64 paidOfPledge;
        uint32 seqOfTarget;
        uint64 paidOfTarget;
        uint32 priceOfDeal;
        bool isPutOpt;
        uint8 state;
    }

    struct Repo {
        // seqOfSwap => Swap
        mapping(uint256 => Swap) swaps;
    }

    // ###############
    // ##  Modifier ##
    // ###############

    modifier swapExist(Repo storage repo, uint seqOfSwap) {
        require (isSwap(repo, seqOfSwap), "SR.swapExist: not");
        _;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    // ==== cofify / parser ====

    function codifySwap(Swap memory swap) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            swap.seqOfSwap,
                            swap.seqOfPledge,
                            swap.paidOfPledge,
                            swap.seqOfTarget,
                            swap.paidOfTarget,
                            swap.priceOfDeal,
                            swap.isPutOpt,
                            swap.state);
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function regSwap(
        Repo storage repo,
        Swap memory swap
    ) public returns(Swap memory) {

        require(swap.seqOfTarget * swap.paidOfTarget * swap.seqOfPledge > 0,
            "SWR.regSwap: zero para");

        swap.seqOfSwap = _increaseCounter(repo);

        repo.swaps[swap.seqOfSwap] = swap;
        repo.swaps[0].paidOfTarget += swap.paidOfTarget;

        return swap;
    }

    function payOffSwap(
        Repo storage repo,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice
    ) public returns (Swap memory ) {

        Swap storage swap = repo.swaps[seqOfSwap];

        require(swap.state == uint8(StateOfSwap.Issued), 
            "SWR.payOffSwap: wrong state");

        require (uint(swap.paidOfTarget) * uint(swap.priceOfDeal) * centPrice <= msgValue, "SWR.payOffSwap: insufficient amt");

        swap.state = uint8(StateOfSwap.Closed);

        return swap;
    }

    function terminateSwap(
        Repo storage repo,
        uint seqOfSwap
    ) public returns (Swap memory){

        Swap storage swap = repo.swaps[seqOfSwap];

        require(swap.state == uint8(StateOfSwap.Issued), 
            "SWR.terminateSwap: wrong state");

        swap.state = uint8(StateOfSwap.Terminated);

        return swap;
    }

    // ==== Counter ====

    function _increaseCounter(Repo storage repo) private returns(uint16) {
        repo.swaps[0].seqOfSwap++;
        return repo.swaps[0].seqOfSwap;
    } 

    // ################
    // ##  查询接口   ##
    // ################

    function counterOfSwaps(Repo storage repo)
        public view returns (uint16)
    {
        return repo.swaps[0].seqOfSwap;
    }

    function sumPaidOfTarget(Repo storage repo)
        public view returns (uint64)
    {
        return repo.swaps[0].paidOfTarget;
    }

    function isSwap(Repo storage repo, uint256 seqOfSwap)
        public view returns (bool)
    {
        return repo.swaps[seqOfSwap].seqOfTarget > 0;
    }

    function getSwap(Repo storage repo, uint256 seqOfSwap)
        public view swapExist(repo, seqOfSwap) returns (Swap memory)
    {
        return repo.swaps[seqOfSwap];
    }

    function getAllSwaps(Repo storage repo)
        public view returns (Swap[] memory )
    {
        uint256 len = counterOfSwaps(repo);
        Swap[] memory swaps = new Swap[](len);

        while (len > 0) {
            swaps[len-1] = repo.swaps[len];
            len--;
        }
        return swaps;
    }

    function allSwapsClosed(Repo storage repo)
        public view returns (bool)
    {
        uint256 len = counterOfSwaps(repo);
        while (len > 0) {
            if (repo.swaps[len].state < uint8(StateOfSwap.Closed))
                return false;
            len--;
        }

        return true;        
    }
}
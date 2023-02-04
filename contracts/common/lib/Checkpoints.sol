// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library Checkpoints {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Checkpoint {
        uint64 blocknumber;
        uint64 paid;
        uint64 par;
    }

    struct History {
        Checkpoint[] checkpoints;
    }

    //##################
    //##    写接口    ##
    //##################

    function push(
        History storage self,
        uint64 paid,
        uint64 par
    ) internal returns (uint64) {
        uint256 pos = self.checkpoints.length;
        if (
            pos != 0 &&
            self.checkpoints[pos - 1].blocknumber == uint64(block.number)
        ) {
            self.checkpoints[pos - 1].paid = paid;
            self.checkpoints[pos - 1].par = par;
        } else {
            self.checkpoints.push(
                Checkpoint({
                    blocknumber: uint64(block.number),
                    paid: paid,
                    par: par
                })
            );
        }
        return (uint64(block.number));
    }

    //##################
    //##    读接口    ##
    //##################

    function latest(History storage self)
        internal
        view
        returns (uint64 paid, uint64 par)
    {
        uint256 pos = self.checkpoints.length;
        paid = pos == 0 ? 0 : self.checkpoints[pos - 1].paid;
        par = pos == 0 ? 0 : self.checkpoints[pos - 1].par;
    }

    function _average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + ((a ^ b) >> 1);
    }

    function getAtBlock(History storage self, uint64 blocknumber)
        internal
        view
        returns (uint64 paid, uint64 par)
    {
        require(
            blocknumber <= block.number,
            "Checkpoints: block not yet mined"
        );

        uint256 high = self.checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = _average(low, high);
            if (self.checkpoints[mid].blocknumber > blocknumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        paid = high == 0 ? 0 : self.checkpoints[high - 1].paid;
        par = high == 0 ? 0 : self.checkpoints[high - 1].par;
    }
}

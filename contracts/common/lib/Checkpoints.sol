// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library Checkpoints {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Checkpoint {
        uint48 timestamp;
        uint64 paid;
        uint64 par;
        uint64 cleanPar;
    }

    struct History {
        // checkpoints[0].blocknumber : counter
        mapping (uint256 => Checkpoint) checkpoints;
    }

    //##################
    //##    写接口    ##
    //##################

    function push(
        History storage self,
        uint64 paid,
        uint64 par,
        uint64 cleanPar
    ) internal returns (uint48) {
        uint256 pos = self.checkpoints[0].timestamp;
        pos++;

        uint48 timestamp= uint48 (block.timestamp);

        if (pos > 1 && self.checkpoints[pos - 1].timestamp == timestamp) {
            self.checkpoints[pos - 1].paid = paid;
            self.checkpoints[pos - 1].par = par;
            self.checkpoints[pos - 1].cleanPar = cleanPar;
        } else {
            self.checkpoints[pos] =
                Checkpoint({
                    timestamp: timestamp,
                    paid: paid,
                    par: par,
                    cleanPar: cleanPar
                });
        }
        return timestamp;
    }

    //##################
    //##    读接口    ##
    //##################

    function latest(History storage self)
        internal
        view
        returns (Checkpoint memory point)
    {
        uint256 pos = self.checkpoints[0].timestamp;
        point = self.checkpoints[pos];
    }

    function _average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + ((a ^ b) >> 1);
    }

    function getAtDate(History storage self, uint48 timestamp)
        internal
        view
        returns (Checkpoint memory point)
    {
        require(
            timestamp <= block.timestamp,
            "Checkpoints: block not yet mined"
        );

        uint256 high = self.checkpoints[0].timestamp + 1;
        uint256 low = 1;
        while (low < high) {
            uint256 mid = _average(low, high);
            if (self.checkpoints[mid].timestamp > timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        if (high > 1) point = self.checkpoints[high - 1];

    }
}

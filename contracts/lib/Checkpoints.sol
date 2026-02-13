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

/// @title Checkpoints
/// @notice Library for timestamped checkpoint history.
/// @dev Uses index 0 as metadata storage.
library Checkpoints {

    /// @notice Snapshot of values at a timestamp.
    struct Checkpoint {
        uint48 timestamp;
        uint16 rate;
        uint64 paid;
        uint64 par;
        uint64 points;
    }

    // checkpoints[0] {
    //     timestamp: counter;
    //     rate: distrWeight;
    //     paid;
    //     par;
    //     points: distrPoints;
    // }

    /// @notice Checkpoint history mapping.
    struct History {
        mapping (uint256 => Checkpoint) checkpoints;
    }

    //##################
    //##  Write I/O  ##
    //##################

    /// @notice Append a checkpoint at the current block time.
    /// @param self Storage history.
    /// @param rate Distribution rate (uint16 range).
    /// @param paid Paid amount (uint64 range).
    /// @param par Par amount (uint64 range).
    /// @param points Distribution points (uint64 range).
    function push(
        History storage self,
        uint rate,
        uint paid,
        uint par,
        uint points
    ) public {

        uint256 pos = counterOfPoints(self);

        Checkpoint memory point = Checkpoint({
            timestamp: uint48(block.timestamp),
            rate: uint16(rate),
            paid: uint64(paid),
            par: uint64(par),
            points: uint64(points)
        });
        
        if (self.checkpoints[pos].timestamp == point.timestamp) {
            self.checkpoints[pos] = point;
        } else {
            self.checkpoints[pos+1] = point;
            _increaseCounter(self);
        }
    }

    /// @dev Increase checkpoint counter with wrap avoidance.
    function _increaseCounter(History storage self)
        public
    {
        unchecked {
            self.checkpoints[0].timestamp = 
                self.checkpoints[0].timestamp == type(uint48).max
                    ? 1
                    : self.checkpoints[0].timestamp + 1;
        }
    }

    /// @notice Update distribution parameters stored at index 0.
    /// @param self Storage history.
    /// @param rate Distribution rate (uint16 range).
    /// @param paid Paid amount (uint64 range).
    /// @param par Par amount (uint64 range).
    /// @param points Distribution points (uint64 range).
    function updateDistrPoints(
        History storage self,
        uint rate,
        uint paid,
        uint par,
        uint points
    ) public {
        Checkpoint storage c = self.checkpoints[0];
        c.rate = uint16(rate);
        c.paid = uint64(paid);
        c.par = uint64(par);
        c.points = uint64(points);
    }

    /// @notice Restore history from a list.
    /// @param self Storage history.
    /// @param list Checkpoints ordered by index.
    function restoreHistory(History storage self, Checkpoint[] memory list) public {
        uint len = list.length;
        while (len > 0) {
            self.checkpoints[len] = list[len-1];
            len--;
        }
        self.checkpoints[0].timestamp = uint48(list.length);
    }

    //################
    //##    Read    ##
    //################

    /// @notice Get number of checkpoints.
    /// @param self Storage history.
    function counterOfPoints(History storage self)
        public view returns (uint256)
    {
        return self.checkpoints[0].timestamp;
    }

    /// @notice Get the latest checkpoint.
    /// @param self Storage history.
    function latest(History storage self)
        public view returns (Checkpoint memory point)
    {
        point = self.checkpoints[counterOfPoints(self)];
    }

    function _average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + ((a ^ b) >> 1);
    }

    /// @notice Get checkpoint at or before a timestamp.
    /// @param self Storage history.
    /// @param timestamp Unix timestamp (<= block.timestamp).
    function getAtDate(History storage self, uint256 timestamp)
        public view returns (Checkpoint memory point)
    {
        require(
            timestamp <= block.timestamp,
            "Checkpoints: block not yet mined"
        );

        uint256 high = counterOfPoints(self) + 1;
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

    /// @notice Get all checkpoints in history order.
    /// @param self Storage history.
    function pointsOfHistory(History storage self)
        public view returns (Checkpoint[] memory) 
    {
        uint256 len = counterOfPoints(self);

        Checkpoint[] memory output = new Checkpoint[](len);

        while (len > 0) {
            output[len-1] = self.checkpoints[len];
            len--;
        }

        return output;
    }

    /// @notice Get distribution parameters stored at index 0.
    /// @param self Storage history.
    function getDistrPoints(History storage self)
        public view returns (Checkpoint memory) 
    {
        return self.checkpoints[0];
    }
    
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
 *
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

pragma solidity ^0.8.8;

import "./IROIKs.sol";
import "../common/access/AccessControl.sol";

contract ROIKs is IROIKs, AccessControl {

    function _getROIKeeper() private view returns(IROIKeeper) {
        return IROIKeeper(gk.getKeeper(11));
    }

    function pause(uint seqOfLR) external {
        _getROIKeeper().pause(msg.sender, seqOfLR);
    }

    function unPause(uint seqOfLR) external {
        _getROIKeeper().unPause(msg.sender, seqOfLR);
    }

    function freezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, bytes32 hashOrder
    ) external {
        _getROIKeeper().freezeShare(
            msg.sender, seqOfLR, seqOfShare, paid, hashOrder
        );
    }

    function unfreezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, bytes32 hashOrder
    ) external {
        _getROIKeeper().unfreezeShare(
            msg.sender, seqOfLR, seqOfShare, paid, hashOrder
        );
    }

    function forceTransfer(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address addrTo, bytes32 hashOrder
    ) external {
        _getROIKeeper().forceTransfer(
            msg.sender, seqOfLR, seqOfShare, paid, addrTo, hashOrder
        );
    }

    function regInvestor(address bKey, uint groupRep, bytes32 idHash) external {
        _getROIKeeper().regInvestor(
            msg.sender, bKey, groupRep, idHash
        );
    }

    function approveInvestor(uint userNo, uint seqOfLR) external{
        _getROIKeeper().approveInvestor(msg.sender, userNo, seqOfLR);        
    }

    function revokeInvestor(uint userNo, uint seqOfLR) external{
        _getROIKeeper().revokeInvestor(msg.sender, userNo, seqOfLR);
    }

}

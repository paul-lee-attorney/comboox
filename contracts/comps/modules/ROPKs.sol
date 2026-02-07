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

import "./IROPKs.sol";
import "../common/access/AccessControl.sol";

contract ROPKs is IROPKs, AccessControl {
    
    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external{
        IROPKeeper(gk.getKeeper(8)).createPledge(msg.sender, snOfPld, paid, par, guaranteedAmt, execDays);
    }

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external{
        IROPKeeper(gk.getKeeper(8)).transferPledge(msg.sender, seqOfShare, seqOfPld, buyer, amt);
    }

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external{
        IROPKeeper(gk.getKeeper(8)).refundDebt(msg.sender, seqOfShare, seqOfPld, amt);
    }

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external{
        IROPKeeper(gk.getKeeper(8)).extendPledge(msg.sender, seqOfShare, seqOfPld, extDays);
    }

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external{
        IROPKeeper(gk.getKeeper(8)).lockPledge(msg.sender, seqOfShare, seqOfPld, hashLock);
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external{
        IROPKeeper(gk.getKeeper(8)).releasePledge(msg.sender, seqOfShare, seqOfPld, hashKey);
    }

    function execPledge(uint seqOfShare, uint256 seqOfPld, uint buyer, uint groupOfBuyer) external{
        IROPKeeper(gk.getKeeper(8)).execPledge(msg.sender, seqOfShare, seqOfPld, buyer, groupOfBuyer);
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external{
        IROPKeeper(gk.getKeeper(8)).revokePledge(msg.sender, seqOfShare, seqOfPld);
    }
}

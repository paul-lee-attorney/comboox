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


import "./IACCKs.sol";

import "../common/access/AccessControl.sol";

contract ACCKs is IACCKs, AccessControl {
    
    // ###################
    // ##  Accountants  ##
    // ###################

    function _getAccountant() private view returns(IAccountant) {
        return IAccountant(gk.getKeeper(uint8(Keepers.Accountant)));
    }

    function initClass(uint class) external onlyDK {
        _getAccountant().initClass(msg.sender, class);
    }

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion
    ) external {
        _getAccountant().distrProfits(
            msg.sender,
            amt,
            expireDate,
            seqOfDR,
            seqOfMotion
        );
    }

    function distributeIncome(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint fundManager,
        uint seqOfMotion
    ) external {
        _getAccountant().distrIncome(
            msg.sender,
            amt,
            expireDate,
            seqOfDR,
            fundManager,
            seqOfMotion
        );
    }

    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external {
        _getAccountant().transferFund(
            msg.sender,
            fromBMM, 
            to, 
            isCBP, 
            amt, 
            expireDate, 
            seqOfMotion
        );
        if (isCBP) rc.transfer(to, amt);
    }

}

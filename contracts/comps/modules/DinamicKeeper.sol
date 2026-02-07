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

import "./GeneralKeeper.sol";

contract DinamicKeeper is GeneralKeeper {

    // ---- Router  ----
    function _routeToKeeper() private {
        uint256 title;
        assembly {
            title := calldataload(4)
        }
        address keeper = _keepers[title];
        require(keeper != address(0), "DK: No keeper for func");

        bytes memory dataWithSender = abi.encodePacked(
            msg.sig,
            uint256(uint160(msg.sender)),
            msg.data[36:]
        );

        bytes memoryreturndata = 
            Address.functionCallWithValue(keeper, dataWithSender, msg.value);

        assembly {
            return(add(returndata, 0x20), mload(returndata))
        }
    }

    fallback () external payable {
        _routeToKeeper();
    }
}

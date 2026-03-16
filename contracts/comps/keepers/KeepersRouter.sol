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

import "./IKeepersRouter.sol";

contract KeepersRouter is IKeepersRouter {
    bytes4[90] public selectors = [
        bytes4(0x04726d7a), bytes4(0x04e417ef), bytes4(0x04f2c63d), bytes4(0x07124bcf), bytes4(0x07f2990e),
        bytes4(0x0a672cbc), bytes4(0x136439dd), bytes4(0x18c678aa), bytes4(0x1c3a1ce3), bytes4(0x1f6b2609),
        bytes4(0x1fbbd398), bytes4(0x202bc98a), bytes4(0x205969bd), bytes4(0x22675a27), bytes4(0x2463d9ba),
        bytes4(0x295dd720), bytes4(0x2c425acc), bytes4(0x2cd7aa21), bytes4(0x2dae6617), bytes4(0x2e04d0a5),
        bytes4(0x2e8310da), bytes4(0x326b0e08), bytes4(0x329c43c1), bytes4(0x34d1c581), bytes4(0x36dfcf94),
        bytes4(0x392c8cd6), bytes4(0x3c851592), bytes4(0x40d8d8d2), bytes4(0x4462f61b), bytes4(0x452558b0),
        bytes4(0x498ec436), bytes4(0x4b4b972f), bytes4(0x4d5931f0), bytes4(0x501d9cca), bytes4(0x50235307),
        bytes4(0x5233f2ff), bytes4(0x569e1006),                                         bytes4(0x5abba148),
        bytes4(0x610bd881), bytes4(0x61d65d55), bytes4(0x6555ff7a), bytes4(0x6998d28d), bytes4(0x6e8d3873),
        bytes4(0x6e93dcce), bytes4(0x71944b39), bytes4(0x73ce8858), bytes4(0x7504e5a0), bytes4(0x75daba71),
        bytes4(0x76f2736f), bytes4(0x77a9dfa0), bytes4(0x7cbc2373), bytes4(0x8506c43f), bytes4(0x851aa5a0),
        bytes4(0x88ca46ed), bytes4(0x8d74e9ab), bytes4(0x92bcd2e2), bytes4(0x92c2c3d3), bytes4(0x946088cd),
        bytes4(0x959efc85), bytes4(0x974b0a6b), bytes4(0x991a1c37), bytes4(0xa023707d), bytes4(0xa2333df0), bytes4(0xa6f93889),
        bytes4(0xaa22742b), bytes4(0xab4e66b6), bytes4(0xacf12377), bytes4(0xb3a9d19b), bytes4(0xb4c6a008),
        bytes4(0xb791f1f5), bytes4(0xbe29b077), bytes4(0xc0e4aecd), bytes4(0xc0f869c2), bytes4(0xc297ddd0),
        bytes4(0xcb385133), bytes4(0xcebb34a8), bytes4(0xd2f4dc25), bytes4(0xd6eb75ec), bytes4(0xd8d53890),
        bytes4(0xdc09fd29), bytes4(0xe0fcbcfa), bytes4(0xe322799d), bytes4(0xe5421a98), bytes4(0xf424672b), bytes4(0xf584accb),
        bytes4(0xf89f622e), bytes4(0xf8be81ac), bytes4(0xf8fb9e1d), bytes4(0xfa0be085), bytes4(0xfd95c4c0)
    ];

    uint8[90] public titles = [
        4,  10, 16,  9,  5, 
        11, 11, 6,   7,  1, 
        12, 2,  8,   11, 5, 
        10, 1,  11,  16, 7, 
        5,  3,  3,   5,  8, 
        6,  8,  9,   11, 6, 
        4,  4,  12,  10, 8, 
        12, 9,           11, 
        10, 8,  7,   2,  3, 
        5,  3,  16,  3,  3, 
        7,  9,  16,  6,  4, 
        1,  10, 5,   2,  6, 
        3,  5,  8,   8,  4,  6, 
        5,  6,  10,  12, 16, 
        5,  1,  9,   1,  5, 
        5,  4,  4,   11, 7,
        2,  10, 3,   3,  8,  9, 
        11, 2,  3,   6,  6
    ];

    /// @notice Get the title associated with a function selector.
    /// @param sig Function selector (first 4 bytes of calldata).
    /// @return title number (revert if not found).
    function getTitleBySelector(bytes4 sig) external view returns (uint8 title) {
        uint low = 0;
        uint high = selectors.length;
        while (low < high) {
            uint mid = low + (high - low) / 2;
            if (selectors[mid] == sig) {
                return titles[mid];
            } else if (selectors[mid] < sig) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        revert KeeprsRouter_WrongInput(bytes32("KR_SigNotRegistered"));
    }

}

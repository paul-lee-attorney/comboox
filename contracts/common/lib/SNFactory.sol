// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library SNFactory {
    function bytesToBytes32(bytes memory input)
        internal
        pure
        returns (bytes32 output)
    {
        assembly {
            output := mload(add(input, 0x20))
        }
    }

    function intToSN(
        bytes memory sn,
        uint256 pointer,
        uint256 input,
        uint256 len
    ) internal pure returns (bytes memory) {
        for (uint256 i = 0; i < len; i++) {
            uint256 bits = (len - i - 1) << 3;
            uint256 temp = input >> bits;

            sn[pointer + i] = bytes1(uint8(temp));
        }

        return sn;
    }

    function seqToSN(
        bytes memory sn,
        uint256 pointer,
        uint16 input
    ) internal pure returns (bytes memory) {
        sn[pointer] = bytes1(uint8(input >> 8));
        sn[pointer + 1] = bytes1(uint8(input));

        return sn;
    }

    function ssnToSN(
        bytes memory sn,
        uint256 pointer,
        uint32 input
    ) internal pure returns (bytes memory) {
        uint256 len = 4;
        return intToSN(sn, pointer, input, len);
    }

    function dateToSN(
        bytes memory sn,
        uint256 pointer,
        uint48 input
    ) internal pure returns (bytes memory) {
        uint256 len = 6;
        return intToSN(sn, pointer, input, len);
    }

    function acctToSN(
        bytes memory sn,
        uint256 pointer,
        uint40 input
    ) internal pure returns (bytes memory) {
        uint256 len = 5;
        return intToSN(sn, pointer, input, len);
    }

    function amtToSN(
        bytes memory sn,
        uint256 pointer,
        uint64 input
    ) internal pure returns (bytes memory) {
        uint256 len = 8;
        return intToSN(sn, pointer, input, len);
    }

    function addrToSN(
        bytes memory sn,
        uint256 pointer,
        address acct
    ) internal pure returns (bytes memory) {
        uint160 input = uint160(acct);
        uint256 len = 20;
        return intToSN(sn, pointer, input, len);
    }

    function boolToSN(
        bytes memory sn,
        uint256 pointer,
        bool input
    ) internal pure returns (bytes memory) {
        sn[pointer] = input ? bytes1(uint8(1)) : bytes1(uint8(0));

        return sn;
    }
}

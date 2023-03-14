// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library ArrayUtils {

    function mixCombine(uint40[] memory arrA, uint256[] memory arrB) 
        public pure 
        returns(uint256[] memory)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;

        uint256[] memory output = new uint256[](lenA + lenB);

        uint256 i;

        while (i < lenA) {
            output[i] = arrA[i];
            i++;
        }

        i=0;
        while (i < lenB) {
            output[lenA + i] = arrB[i];
            i++;
        }

        return output;
    }

    function combine(uint256[] memory arrA, uint256[] memory arrB)
        public
        pure
        returns (uint256[] memory)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;
        uint256 i;

        uint256[] memory arrC = new uint256[](lenA + lenB);

        for (i = 0; i < lenA; i++) arrC[i] = arrA[i];
        for (i = 0; i < lenB; i++) arrC[lenA + i] = arrB[i];

        return arrC;
    }

    function minus(uint256[] memory arrA, uint256[] memory arrB)
        public
        pure
        returns (uint256[] memory)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;

        uint256[] memory arrC = new uint256[](lenA);

        uint256 pointer;

        while (lenA > 0) {
            bool flag = false;
            lenB = arrB.length;
            while (lenB > 0) {
                if (arrB[lenB - 1] == arrA[lenA - 1]) {
                    flag = true;
                    break;
                }
                lenB--;
            }

            if (!flag) {
                arrC[pointer] = arrA[lenA - 1];
                pointer++;
            }

            lenA--;
        }

        uint256[] memory output = new uint256[](pointer);
        lenA = 0;

        while (lenA < pointer) {
            output[lenA] = arrC[lenA];
            lenA++;
        }

        return output;
    }

    function fullyCoveredBy(uint256[] memory arrA, uint256[] memory arrB)
        public
        pure
        returns (bool)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;

        for (uint256 i = 0; i < lenA; i++) {
            bool flag;
            for (uint256 j = 0; j < lenB; j++) {
                if (arrB[j] == arrA[i]) {
                    flag = true;
                    break;
                }
            }
            if (!flag) return false;
        }

        return true;
    }
}

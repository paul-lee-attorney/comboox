// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library DelegateMap {
    struct Map {
        mapping(uint256 => uint40) delegateOf;
        mapping(uint256 => uint40[]) principalsOf;
    }

    /*
    principalsOf[0] : all principals;
*/

    // #################
    // ##    Write    ##
    // #################

    function entrustDelegate(
        Map storage map,
        uint40 acct,
        uint40 delegate
    ) public returns (bool flag) {
        require(
            acct != delegate,
            "DM.entrustDelegate: self delegate not allowed"
        );

        if (map.delegateOf[acct] == 0 && map.delegateOf[delegate] == 0) {
            map.delegateOf[acct] = delegate;
            map.principalsOf[delegate].push(acct);

            flag = true;
        }
    }

    // #################
    // ##    Read     ##
    // #################

    // function isPrincipal(Map storage map, uint40 acct)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return map.delegateOf[acct] != 0;
    // }

    // function isDelegate(Map storage map, uint40 acct)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return map.principalsOf[acct].length != 0;
    // }

    // function getDelegate(Map storage map, uint40 acct)
    //     public
    //     view
    //     returns (uint40)
    // {
    //     return map.delegateOf[acct];
    // }

    // function getPrincipals(Map storage map, uint40 acct)
    //     public
    //     view
    //     returns (uint40[] memory)
    // {
    //     return map.principalsOf[acct];
    // }
}

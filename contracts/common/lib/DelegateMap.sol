// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/rom/IRegisterOfMembers.sol";

library DelegateMap {

    struct Voter {
        uint40 delegate;
        uint64 weight;
        uint64 repWeight;
        uint32 repHead;
        uint40[] principals;
    }

    struct Map {
        mapping(uint256 => Voter) voters;
    }

    // #################
    // ##    Write    ##
    // #################

    function entrustDelegate(
        Map storage map,
        uint40 principal,
        uint40 delegate,
        uint64 weight
    ) public returns (bool flag) {
        require(principal != 0, "DM.ED: zero principal");
        require(delegate != 0, "DM.ED: zero delegate");
        require(principal != delegate,"DM.ED: self delegate");

        if (map.voters[principal].delegate == 0 && 
            map.voters[delegate].delegate == 0) 
        {
            Voter storage p = map.voters[principal];
            Voter storage d = map.voters[delegate];

            p.delegate = delegate;
            p.weight = weight;
            p.repWeight += weight;
            p.repHead ++;

            d.repHead += p.repHead;
            d.repWeight += p.repWeight;
           
            d.principals.push(principal);

            flag = true;
        }
    }

    // #################
    // ##    Read     ##
    // #################

    function getDelegateOf(Map storage map, uint40 acct)
        public
        view
        returns (uint40 d)
    {
        while (acct > 0) {
            d = acct;
            acct = map.voters[d].delegate;
        }
    }

    function getLeavesWeightAtDate(Map storage map, uint256 acct, uint48 baseDate, IRegisterOfMembers _rom)
        public view returns(uint64 weight)
    {
        uint40[] memory leaves = map.voters[acct].principals;
        uint256 len = leaves.length;
        while (len > 0) {
            weight += getLeavesWeightAtDate(map, leaves[len-1], baseDate, _rom);
            len--;
        }
        weight += _rom.votesAtDate(acct, baseDate);
    }
}

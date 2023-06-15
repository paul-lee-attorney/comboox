// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/rom/IRegisterOfMembers.sol";
import "../../books/bod/IBookOfDirectors.sol";

library DelegateMap {

    struct LeavesInfo {
        uint64 weight;
        uint32 emptyHead;
    }

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
        uint principal,
        uint delegate,
        uint weight
    ) public returns (bool flag) {
        require(principal != 0, "DM.ED: zero principal");
        require(delegate != 0, "DM.ED: zero delegate");
        require(principal != delegate,"DM.ED: self delegate");

        if (map.voters[principal].delegate == 0 && 
            map.voters[delegate].delegate == 0) 
        {
            Voter storage p = map.voters[principal];
            Voter storage d = map.voters[delegate];

            p.delegate = uint40(delegate);
            p.weight = uint64(weight);
            p.repWeight += uint64(weight);
            p.repHead ++;

            d.repHead += p.repHead;
            d.repWeight += p.repWeight;
           
            d.principals.push(uint40(principal));

            flag = true;
        }
    }

    // #################
    // ##    Read     ##
    // #################

    function getDelegateOf(Map storage map, uint acct)
        public
        view
        returns (uint d)
    {
        while (acct > 0) {
            d = acct;
            acct = map.voters[d].delegate;
        }
    }

    function getLeavesWeightAtDate(Map storage map, uint256 acct, uint baseDate, IRegisterOfMembers _rom)
        public view returns(LeavesInfo memory info)
    {
        uint40[] memory leaves = map.voters[acct].principals;
        uint256 len = leaves.length;
        while (len > 0) {
            LeavesInfo memory lv = getLeavesWeightAtDate(map, leaves[len-1], baseDate, _rom);
            info.weight += lv.weight;
            info.emptyHead += lv.emptyHead;
            len--;
        }
        
        uint64 w = _rom.votesAtDate(acct, baseDate);
        if (w > 0) info.weight += w;
        else info.emptyHead ++;
    }

    function getLeavesHeadOfDirectors(Map storage map, uint256 acct, IBookOfDirectors _bod) 
        public view returns (uint32 head) 
    {
        uint40[] memory leaves = map.voters[acct].principals;
        uint256 len = leaves.length;
        while (len > 0) {
            head += getLeavesHeadOfDirectors(map, leaves[len-1], _bod);
            len--;
        }

        if (_bod.isDirector(acct)) head++;
    }
}

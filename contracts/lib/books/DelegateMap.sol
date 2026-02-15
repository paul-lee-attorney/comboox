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

import "../../comps/books/rom/IRegisterOfMembers.sol";
import "../../comps/books/rod/IRegisterOfDirectors.sol";

/// @title DelegateMap
/// @notice Library for managing delegation relationships and derived voting weight.
library DelegateMap {

    /// @notice Aggregated info for delegated leaves.
    struct LeavesInfo {
        uint64 weight;
        uint32 emptyHead;
    }

    /// @notice Voter delegation data.
    struct Voter {
        uint40 delegate;
        uint64 weight;
        uint64 repWeight;
        uint32 repHead;
        uint[] principals;
    }

    /// @notice Delegate map storage.
    struct Map {
        mapping(uint256 => Voter) voters;
    }

    // #################
    // ##    Error    ##
    // #################

    error DelegateMap_WrongInput(bytes32 reason);

    // #################
    // ##    Write    ##
    // #################

    /// @notice Entrust a delegate for a principal.
    /// @param map Storage map.
    /// @param principal Principal account id (> 0).
    /// @param delegate Delegate account id (> 0, != principal).
    /// @param weight Voting weight of principal (>= 0).
    function entrustDelegate(
        Map storage map,
        uint principal,
        uint delegate,
        uint weight
    ) public returns (bool flag) {
        if (principal == 0) {
            revert DelegateMap_WrongInput(bytes32("DM_ZeroPrincipal"));
        }
        if (delegate == 0) {
            revert DelegateMap_WrongInput(bytes32("DM_ZeroDelegate"));
        }
        if (principal == delegate) {
            revert DelegateMap_WrongInput(bytes32("DM_SelfDelegate"));
        }

        if (map.voters[principal].delegate == 0 && 
            map.voters[delegate].delegate == 0) 
        {
            Voter storage p = map.voters[principal];
            Voter storage d = map.voters[delegate];

            p.delegate = uint40(delegate);
            p.weight = uint64(weight);

            d.repHead += (p.repHead + 1);
            d.repWeight += (p.repWeight + p.weight);

            d.principals.push(uint40(principal));
            _consolidatePrincipals(p.principals, d);

            flag = true;
        }
    }

    /// @dev Append principals list to delegate record.
    function _consolidatePrincipals(uint[] memory principals, Voter storage d) private {
        uint len = principals.length;

        while (len > 0) {
            d.principals.push(principals[len-1]);
            len--;
        }        
    }

    // #################
    // ##    Read     ##
    // #################

    /// @notice Resolve the final delegate of an account (walks delegation chain).
    /// @param map Storage map.
    /// @param acct Account id (> 0).
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

    /// @notice Update delegate weights based on member votes at a date.
    /// @param map Storage map.
    /// @param acct Account id (> 0).
    /// @param baseDate Snapshot timestamp.
    /// @param _rom Register of members.
    function updateLeavesWeightAtDate(Map storage map, uint256 acct, uint baseDate, IRegisterOfMembers _rom)
        public
    {
        LeavesInfo memory info;
        Voter storage voter = map.voters[acct];

        uint[] memory leaves = voter.principals;
        uint256 len = leaves.length;

        while (len > 0) {
            uint64 w = _rom.votesAtDate(leaves[len-1], baseDate);
            if (w > 0) {
                info.weight += w;
            } else {
                info.emptyHead++;
            }
            len--;
        }
        
        voter.weight = _rom.votesAtDate(acct, baseDate);
        voter.repWeight = info.weight;
        voter.repHead = uint32(leaves.length) - info.emptyHead;
    }

    /// @notice Update delegate headcount based on director membership.
    /// @param map Storage map.
    /// @param acct Account id (> 0).
    /// @param _rod Register of directors.
    function updateLeavesHeadcountOfDirectors(Map storage map, uint256 acct, IRegisterOfDirectors _rod) 
        public 
    {
        uint[] memory leaves = map.voters[acct].principals;
        uint256 len = leaves.length;

        uint32 repHead;
        while (len > 0) {
            if (_rod.isDirector(leaves[len-1])) repHead++;
            len--;
        }

        map.voters[acct].repHead = repHead;
    }
}

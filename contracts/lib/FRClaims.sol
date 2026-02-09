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

pragma solidity ^0.8.8;

import "../comps/books/rom/IRegisterOfMembers.sol";

/// @title FRClaims
/// @notice Library for first-refusal claims tracking and allocation.
library FRClaims {

    /// @notice Claim record for a deal.
    struct Claim {
        uint16 seqOfDeal;
        uint40 claimer;
        uint64 weight;
        uint64 ratio;
        uint48 sigDate;
        bytes32 sigHash;
    }

    /// @notice Package of claims for a deal.
    struct Package {
        uint64 sumOfWeight;
        Claim[] claims;
        mapping(uint256 => bool) isClaimer;
    }

    // packages[0] {
    //     claims: deals;
    //     isClaimer: isClaimer;
    // }

    /// @notice Claims repository keyed by deal.
    struct Claims {
        // seqOfDeal => Package
        mapping(uint256 => Package) packages;
    }

    //##################
    //##  Write I/O  ##
    //##################

    /// @notice Submit a first-refusal claim.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence number (> 0).
    /// @param acct Claimer account id (> 0).
    /// @param sigHash Signature hash.
    function claimFirstRefusal(
        Claims storage cls,
        uint256 seqOfDeal,
        uint256 acct,
        bytes32 sigHash
    ) public {

        Claim memory cl = Claim({
            seqOfDeal: uint16(seqOfDeal),
            claimer: uint40(acct),
            weight: 0,
            ratio: 0,
            sigDate: uint48(block.timestamp),
            sigHash: sigHash
        });

        require(cl.seqOfDeal > 0, "FRClaims.exec: zero seqOfDeal");

        require(!isClaimerOfDeal(cls, cl.seqOfDeal, cl.claimer),
            "FRClaims.exec: double claim");

        if (!isDeal(cls, cl.seqOfDeal))
            cls.packages[0].claims.push(cl);
        
        Package storage p = cls.packages[cl.seqOfDeal];

        p.isClaimer[cl.claimer] = true;
        p.claims.push(cl);

        cls.packages[0].isClaimer[cl.claimer] = true;
    }

    /// @notice Compute claim weights and ratios.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence number (> 0).
    /// @param rom Register of members.
    function computeFirstRefusal(
        Claims storage cls,
        uint256 seqOfDeal,
        IRegisterOfMembers rom
    ) public returns (Claim[] memory output) {

        require(isDeal(cls, seqOfDeal), "FRClaims.accept: no claims received");

        Package storage p = cls.packages[seqOfDeal];

        if (p.sumOfWeight == 0) {
            uint256 len = p.claims.length;            
            uint256 i;

            while (i < len) {
                Claim storage cl = p.claims[i];

                uint64 weight = rom.votesInHand(cl.claimer);
                cl.weight = weight;
                p.sumOfWeight += weight;
                i++;
            }

            i = 0;
            uint256 sum;
            len--;

            while(i < len) {
                Claim storage cl = p.claims[i];

                cl.ratio = cl.weight * 10000 / p.sumOfWeight;
                sum += cl.ratio;
                i++; 
            }
            
            p.claims[len].ratio = 10000 - uint64(sum);

        } else revert("FRClaims: already created");

        output = p.claims;
    }

    //  ################################
    //  ##       Read I/O             ##
    //  ################################

    /// @notice Check whether an account has any claim.
    /// @param cls Storage claims.
    /// @param acct Account id (> 0).
    function isClaimer(Claims storage cls, uint acct) public view returns(bool) {
        return cls.packages[0].isClaimer[acct];
    }

    /// @notice Check whether an account claimed a deal.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence number (> 0).
    /// @param acct Account id (> 0).
    function isClaimerOfDeal(
        Claims storage cls, 
        uint seqOfDeal, 
        uint acct
    ) public view returns(bool) {
        return cls.packages[seqOfDeal].isClaimer[acct];
    }

    /// @notice Check whether a deal has claims.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence number (> 0).
    function isDeal(
        Claims storage cls,
        uint seqOfDeal
    ) public view returns(bool) {
        return cls.packages[seqOfDeal].claims.length > 0;
    }

    /// @notice Get list of deals with claims.
    /// @param cls Storage claims.
    function getDeals(Claims storage cls) public view returns(uint[] memory) {
        Claim[] memory claims = cls.packages[0].claims;
        uint len = claims.length;
        uint[] memory deals = new uint[](len);

        while (len > 0) {
            deals[len - 1] = claims[len - 1].seqOfDeal;
            len--;
        }

        return deals;
    }

    /// @notice Get claims of a deal.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence number (> 0).
    function getClaimsOfDeal(Claims storage cls, uint256 seqOfDeal)
        public view returns (Claim[] memory)
    {
        require(isDeal(cls, seqOfDeal), "FRD.COFR: not a targetDeal");
        return cls.packages[seqOfDeal].claims;
    }

    /// @notice Check whether all deals have computed allocations.
    /// @param cls Storage claims.
    function allAccepted(Claims storage cls) public view returns (bool) {

        uint[] memory deals = getDeals(cls);
        uint len = deals.length;

        while (len > 0) {
            if (cls.packages[deals[len - 1]].sumOfWeight == 0)
                return false;
            len--;
        }

        return true;
    }

}

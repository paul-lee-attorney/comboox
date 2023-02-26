// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "./EnumerableSet.sol";
import "../../books/rom/IRegisterOfMembers.sol";

library FRClaims {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Claim {
        uint16 seqOfDeal;
        uint40 rightholder;
        uint64 weight; // Claimer's voting weight
        uint64 ratio;
    }

    struct Package {
        uint64 sumOfWeight;
        // claimer => Claim
        // mapping(uint256 => Claim) claimOf;
        Claim[] claims;
        mapping(uint256 => bool) isClaimer;
        // EnumerableSet.UintSet claimers;
    }

    // ==== FRDeals ====

    struct Claims {
        // seqOfDeal => Package
        mapping(uint256 => Package) claimsFor;
    }

    //##################
    //##    写接口    ##
    //##################

    function execFirstRefusalRight(
        Claims storage cls,
        uint16 seqOfDeal,
        uint40 acct
    ) public returns (bool flag) {

        Package storage p = cls.claimsFor[seqOfDeal];

        if (!p.isClaimer[acct]){
            p.claims.push(
                Claim({
                    seqOfDeal: seqOfDeal,
                    rightholder: acct,
                    weight: 0,
                    ratio: 0
                })
            );

            p.isClaimer[acct] = true;
            flag = true;
        }
    }

    function acceptFirstRefusalClaims(
        Claims storage cls,
        uint16 seqOfDeal,
        IRegisterOfMembers rom
    ) public returns (Claim[] memory output) {

        require(isTargetDeal(cls, seqOfDeal), "FRD.AFRC: no claims received");

        Package storage p = cls.claimsFor[seqOfDeal];

        if (p.sumOfWeight == 0) {                    

            uint256 num = p.claims.length;
            uint256 i;

            while (i < num) {
                Claim storage cl = p.claims[i];

                uint64 weight = rom.votesInHand(cl.rightholder);
                cl.weight = weight;
                p.sumOfWeight += weight;
                i++;
            }

            i = 0;
            while(i < num) {
                Claim storage cl = p.claims[i];

                cl.ratio = cl.weight * 10000 / p.sumOfWeight;
                i++; 
            }

            output = p.claims;
        }
    }

    //  ################################
    //  ##       查询接口              ##
    //  ################################

    function isTargetDeal(Claims storage cls, uint256 seqOfDeal) public view returns (bool) {
        return cls.claimsFor[seqOfDeal].claims[0].rightholder > 0;
    }

    function claimsOfFR(Claims storage cls, uint256 seqOfDeal)
        public
        view
        returns (Claim[] memory)
    {
        require(isTargetDeal(cls, seqOfDeal), "FRD.COFR: not a targetDeal");                        
        return cls.claimsFor[seqOfDeal].claims;
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "../../books/rom/IRegisterOfMembers.sol";

library FRClaims {

    struct Claim {
        uint16 seqOfDeal;
        uint40 rightholder;
        uint64 weight;
        uint64 ratio;
        uint48 sigDate;
        bytes32 sigHash;
    }

    struct Package {
        uint64 sumOfWeight;
        Claim[] claims;
        mapping(uint256 => bool) isClaimer;
    }

    // ==== FRDeals ====

    struct Claims {
        // seqOfDeal => Package
        mapping(uint256 => Package) claimsFor;
        // acct => bool
        mapping(uint256 => bool) isClaimer;
    }

    //##################
    //##  Write I/O  ##
    //##################

    function execFirstRefusalRight(
        Claims storage cls,
        uint256 seqOfDeal,
        uint256 acct,
        bytes32 sigHash
    ) public returns (bool flag) {

        Package storage p = cls.claimsFor[seqOfDeal];

        if (!p.isClaimer[acct]){
            p.claims.push(Claim({
                    seqOfDeal: uint16(seqOfDeal),
                    rightholder: uint40(acct),
                    weight: 0,
                    ratio: 0,
                    sigDate: uint48(block.timestamp),
                    sigHash: sigHash
                }));
            p.isClaimer[acct] = true;

            cls.isClaimer[acct] = true;
            flag = true;
        }
    }

    function acceptFirstRefusalClaims(
        Claims storage cls,
        uint256 seqOfDeal,
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
        return cls.claimsFor[seqOfDeal].claims.length > 0;
    }

    function claimsOfFR(Claims storage cls, uint256 seqOfDeal)
        public
        view
        returns (Claim[] memory output)
    {
        require(isTargetDeal(cls, seqOfDeal), "FRD.COFR: not a targetDeal");
        output = cls.claimsFor[seqOfDeal].claims;
    }
}

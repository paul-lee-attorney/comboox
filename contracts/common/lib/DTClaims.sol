// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "./EnumerableSet.sol";

library DTClaims {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Head {
        uint16 seqOfDeal;
        bool dragAlong;
        uint32 seqOfShare;
        uint64 paid;
        uint64 par;
        uint40 caller;
        uint16 para;
        uint16 argu;
    }

    struct Claim {
        uint8 typeOfClaim;
        uint32 seqOfShare;
        uint64 paid;
        uint64 par;
        uint40 claimer;
        uint48 sigDate;
        bytes32 sigHash;
    }

    struct Pack {
        //seqOfShare => Claim
        mapping(uint256 => Claim) claims;
        EnumerableSet.UintSet shares;
    }

    struct Claims {
        // seqOfDeal => drag/tag/merged => Pack
        mapping(uint256 => mapping(uint256 => Pack)) packs;
        EnumerableSet.UintSet deals;
    }

    //#################
    //##    写接口    ##
    //#################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);
        head = Head({
            seqOfDeal: uint16(_sn >> 240),
            dragAlong: bool(uint8(_sn >> 232) == 1),
            seqOfShare: uint32(_sn >> 200),
            paid: uint64(_sn >> 136),
            par: uint64(_sn >> 72),
            caller: uint40(_sn >> 32),
            para: uint16(_sn >> 16),
            argu: uint16(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.seqOfDeal,
                            head.dragAlong,
                            head.seqOfShare,
                            head.paid,
                            head.par,
                            head.caller,
                            head.para,
                            head.argu
        );

        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function execAlongRight(
        Claims storage cls,
        bool dragAlong,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint256 claimer,
        // Head memory head,
        bytes32 sigHash
    ) public returns (bool flag) {

        uint8 cat = dragAlong ? 0 : 1;

        Pack storage p = cls.packs[seqOfDeal][cat];

        if (p.shares.add(seqOfShare)){

            Claim memory newClaim = Claim({
                    typeOfClaim: cat,
                    seqOfShare: uint32(seqOfShare),
                    paid: uint64(paid),
                    par: uint64(par),
                    claimer: uint40(claimer),
                    sigDate: uint48(block.timestamp),
                    sigHash: sigHash
                }); 

            p.claims[seqOfShare] = newClaim;

            cls.deals.add(seqOfDeal);

            Pack storage m = cls.packs[seqOfDeal][2];

            if (m.shares.add(seqOfShare))
            {
                m.claims[seqOfShare] = newClaim;
            } else {
                Claim storage mClaim = m.claims[seqOfShare];

                if (paid > mClaim.paid || par > mClaim.par)
                {
                    mClaim.paid = paid > mClaim.paid  ? newClaim.paid :  mClaim.paid;
                    mClaim.par = par > mClaim.par ? newClaim.par : mClaim.par;

                    Claim memory dClaim = cls.packs[seqOfDeal][0].claims[seqOfShare];
                    Claim memory tClaim = cls.packs[seqOfDeal][1].claims[seqOfShare];

                    if ((dClaim.paid > tClaim.paid || dClaim.par > tClaim.par) && 
                        mClaim.typeOfClaim != 0)
                    {
                        mClaim.typeOfClaim = 0;
                        mClaim.claimer = dClaim.claimer;
                        mClaim.sigDate = dClaim.sigDate;
                        mClaim.sigHash = dClaim.sigHash;
                    }
                }
            }

            flag = true;
        }
    }


    //  ################################
    //  ##       查询接口              ##
    //  ################################

    function claimsOfDT(Claims storage cls, uint256 seqOfDeal)
        external view returns (Claim[] memory)
    {

        Pack storage p = cls.packs[seqOfDeal][2];

        uint256 len = p.shares.length();
        Claim[] memory output = new Claim[](len);
        
        while (len > 0) {
            output[len-1] = p.claims[p.shares.at(len-1)];
            len--;
        }

        return output;
    }

}

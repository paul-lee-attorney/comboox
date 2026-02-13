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

import "../openzeppelin/utils/structs/EnumerableSet.sol";

/// @title DTClaims
/// @notice Library for drag-along/tag-along claims tracking.
library DTClaims {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Encoded claim head data.
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

    /// @notice Claim record for a share.
    struct Claim {
        uint8 typeOfClaim;
        uint32 seqOfShare;
        uint64 paid;
        uint64 par;
        uint40 claimer;
        uint48 sigDate;
        bytes32 sigHash;
    }

    /// @notice Pack of claims for a deal and claim type.
    struct Pack {
        //seqOfShare => Claim
        mapping(uint256 => Claim) claims;
        EnumerableSet.UintSet shares;
    }

    /// @notice Claims repository keyed by deal.
    struct Claims {
        // seqOfDeal => drag/tag/merged => Pack
        mapping(uint256 => mapping(uint256 => Pack)) packs;
        EnumerableSet.UintSet deals;
    }

    /// @dev Reverts if deal has no claims.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence.
    modifier dealExist(Claims storage cls, uint seqOfDeal) {
        require (hasClaim(cls, seqOfDeal), "DTClaims.mf.dealExist: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    /// @notice Parse encoded claim head.
    /// @param sn Encoded head bytes32.
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

    /// @notice Encode claim head into bytes32.
    /// @param head Claim head.
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

    /// @notice Register a drag-along or tag-along claim.
    /// @param cls Storage claims.
    // / @param dragAlong True for drag-along, false for tag-along.
    // / @param seqOfDeal Deal sequence number (> 0).
    // / @param seqOfShare Share sequence number (> 0).
    // / @param paid Paid amount (uint64 range).
    // / @param par Par amount (uint64 range).
    /// @param snOfClaim Encoded claim head.
    // / @param claimer Claimer account id (> 0).
    /// @param sigHash Signature hash.
    function execAlongRight(
        Claims storage cls,
        // bool dragAlong,
        // uint256 seqOfDeal,
        // uint256 seqOfShare,
        // uint paid,
        // uint par,
        bytes32 snOfClaim,
        // uint256 claimer,
        bytes32 sigHash
    ) public {

        Head memory head = snParser(snOfClaim);

        // uint16 intSeqOfDeal = uint16(seqOfDeal);
        require(head.seqOfDeal > 0, "DTClaims.exec: zero seqOfDeal");
    
        Claim memory newClaim = Claim({
            typeOfClaim: head.dragAlong ? 0 : 1,
            seqOfShare: head.seqOfShare,
            paid: head.paid,
            par: head.par,
            claimer: head.caller,
            sigDate: uint48(block.timestamp),
            sigHash: sigHash
        }); 

        require(newClaim.seqOfShare > 0, "DTClaims.exec: zero seqOfShare");

        Pack storage p = cls.packs[head.seqOfDeal][newClaim.typeOfClaim];

        if (p.shares.add(newClaim.seqOfShare)){

            p.claims[newClaim.seqOfShare] = newClaim;

            cls.deals.add(head.seqOfDeal);

            _consolidateClaimsOfShare(cls, head.seqOfDeal, newClaim);
        }
    }

    /// @dev Consolidate per-share claims into merged pack.
    function _consolidateClaimsOfShare(
        Claims storage cls,
        uint intSeqOfDeal,
        Claim memory newClaim
    ) private {
        Pack storage m = cls.packs[intSeqOfDeal][2];

        if (m.shares.add(newClaim.seqOfShare)) {
            m.claims[newClaim.seqOfShare] = newClaim;
        } else {
            Claim storage mClaim = m.claims[newClaim.seqOfShare];

            mClaim.paid = newClaim.paid > mClaim.paid  ? newClaim.paid :  mClaim.paid;
            mClaim.par = newClaim.par > mClaim.par ? newClaim.par : mClaim.par;

            if (mClaim.typeOfClaim == 0){

                Claim memory tClaim = cls.packs[intSeqOfDeal][1].claims[newClaim.seqOfShare];

                mClaim.typeOfClaim = 1;
                mClaim.claimer = tClaim.claimer;
                mClaim.sigDate = tClaim.sigDate;
                mClaim.sigHash = tClaim.sigHash;
            }
        }
    }

    /// @notice Mark claims of a deal as accepted.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence number (> 0).
    function acceptAlongClaims(
        Claims storage cls,
        uint seqOfDeal
    ) public returns (Claim[] memory) {
        cls.packs[seqOfDeal][2].claims[0].typeOfClaim = 1;
        return getClaimsOfDeal(cls, seqOfDeal);
    }

    //  ################################
    //  ##       Read I/O             ##
    //  ################################

    /// @notice Check whether a deal has any claims.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence number (> 0).
    function hasClaim(Claims storage cls, uint seqOfDeal) public view returns(bool) {
        return cls.deals.contains(seqOfDeal);
    }

    /// @notice Get list of deals with claims.
    /// @param cls Storage claims.
    function getDeals(Claims storage cls) public view returns(uint[] memory) {
        return cls.deals.values();
    }

    /// @notice Get all claims of a deal.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfDeal Deal sequence number (> 0).
    function getClaimsOfDeal(
        Claims storage cls,
        uint seqOfDeal
    ) public view dealExist(cls, seqOfDeal) returns(Claim[] memory) {

        Pack storage m = cls.packs[seqOfDeal][2];

        uint[] memory sharesList = m.shares.values();
        uint len = sharesList.length;

        Claim[] memory output = new Claim[](len);

        while (len > 0) {
            output[len - 1] = m.claims[sharesList[len - 1]];
            len --;
        }

        return output;
    }

    /// @notice Check whether a deal has a claim for a share.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfShare Share sequence.
    /// @param seqOfDeal Deal sequence number (> 0).
    /// @param seqOfShare Share sequence number (> 0).
    function hasShare(
        Claims storage cls,
        uint seqOfDeal,
        uint seqOfShare        
    ) public view dealExist(cls, seqOfDeal) returns(bool) {
        return cls.packs[seqOfDeal][2].shares.contains(seqOfShare);
    }

    /// @notice Get claim for a specific share.
    /// @param cls Storage claims.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfShare Share sequence.
    /// @param seqOfDeal Deal sequence number (> 0).
    /// @param seqOfShare Share sequence number (> 0).
    function getClaimForShare(
        Claims storage cls,
        uint seqOfDeal,
        uint seqOfShare
    ) public view returns (Claim memory) {
        require (hasShare(cls, seqOfDeal, seqOfShare), "DTClaims.getClaimsForShare: not exist");
        return cls.packs[seqOfDeal][2].claims[seqOfShare];
    }

    /// @notice Check whether all deals' claims are accepted.
    /// @param cls Storage claims.
    function allAccepted(Claims storage cls) public view returns(bool flag) {
        uint[] memory dealsList = cls.deals.values();
        uint len = dealsList.length;

        flag = true;
        while(len > 0) {
            if (cls.packs[dealsList[len - 1]][2].claims[0].typeOfClaim == 0) {
                flag = false;
                break;
            }
            len--;
        }
    }

}

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
import "../comps/books/rom/IRegisterOfMembers.sol";

/// @title RedemptionsRepo
/// @notice Repository for redemption requests grouped by class and pack.
library RedemptionsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Redemption request record.
    struct Request {
        uint16 class;
        uint32 seqOfShare;
        uint32 navPrice;
        uint40 shareholder;
        uint64 paid;
        uint64 value; 
        uint8 seqOfPacks;
    }


    /// @notice Pack of requests grouped by day.
    struct Pack {
        Request info;
        mapping (uint => Request) requests;
        EnumerableSet.UintSet sharesList;        
    }

    /// @notice Redemption data for a share class.
    struct Class {
        Request info;
        mapping (uint => Pack) packs;
        EnumerableSet.UintSet packsList;
    }

    /// @notice Repository of redeemable classes.
    struct Repo {
        mapping(uint => Class) classes;
        EnumerableSet.UintSet classesList;
    }

    //####################
    //##    Modifier    ##
    //####################

    /// @notice Ensure class is redeemable.
    /// @param repo Storage repo.
    /// @param class Share class.
    modifier redeemableClass(
        Repo storage repo,
        uint class
    ) {
        require(isRedeemable(repo, class),
            "RR.redeemableClass: not");
        _;
    }

    /// @notice Ensure pack exists under class.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param seqOfPack Pack sequence.
    modifier redeemablePack(
        Repo storage repo,
        uint class, uint seqOfPack
    ) {
        require(repo.classes[class].packsList.contains(seqOfPack),
            "RR.redeemablePack: not");
        _;
    }

    //#################
    //##    Write    ##
    //#################

    /// @notice Pack request info into bytes32.
    /// @param request Request record.
    function codifyHead(Request memory request) public pure returns (bytes32 sn)
    {
        bytes memory _sn = 
            abi.encodePacked(
                request.class,
                request.seqOfShare,
                request.navPrice,
                request.shareholder,
                request.paid,
                request.value,
                request.seqOfPacks
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }

    }

    // ==== Config ====

    /// @notice Add a redeemable share class.
    /// @param repo Storage repo.
    /// @param class Share class.
    function addRedeemableClass(
        Repo storage repo, uint class
    ) public {
        repo.classesList.add(class);
    }

    /// @notice Remove a redeemable share class.
    /// @param repo Storage repo.
    /// @param class Share class.
    function removeRedeemableClass(
        Repo storage repo, uint class
    ) public redeemableClass(repo, class) {
        repo.classesList.remove(class);
    }

    /// @notice Update NAV price for a class.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param price NAV price.
    function updateNavPrice(
        Repo storage repo, uint class, uint price
    ) public redeemableClass(repo, class) {
        repo.classes[class].info.navPrice = uint32(price);
    }

    // ==== Reqeust ====
    
    /// @notice Create a redemption request.
    /// @param repo Storage repo.
    /// @param caller Shareholder user number.
    /// @param class Share class.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount of shares.
    function requestForRedemption(
        Repo storage repo, uint caller, uint class, uint seqOfShare, uint paid
    ) public redeemableClass(repo, class) returns(
        Request memory request
    ) {
        Class storage cls = repo.classes[class];

        request.seqOfPacks = uint8(block.timestamp / 86400 % 256);

        cls.packsList.add(request.seqOfPacks);

        Pack storage pack = cls.packs[request.seqOfPacks];
        
        pack.sharesList.add(seqOfShare);

        request.class = uint16(class);
        request.seqOfShare = uint32(seqOfShare);
        request.navPrice = uint32(cls.info.navPrice);
        request.shareholder = uint40(caller);
        request.paid = uint64(paid);
        request.value = uint64(paid * cls.info.navPrice / 10 ** 4);

        pack.requests[request.seqOfShare] = request;

        pack.info.paid += request.paid;
        pack.info.value += request.value;
        
        cls.info.paid += request.paid;
        cls.info.value += request.value;
    }

    // ==== Redeem ====

    /// @notice Redeem a pack and return request list.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param seqOfPack Pack sequence.
    function redeem(
        Repo storage repo, uint class, uint seqOfPack
    ) public redeemableClass(repo, class) redeemablePack(repo, class, seqOfPack) returns(
        Request[] memory list, Request memory info
    ) {
        Class storage cls = repo.classes[class];
        Pack storage pack = cls.packs[seqOfPack];

        info = pack.info;

        require(info.value > 0,
            "RR.redeem: zero payables");

        cls.info.value -= pack.info.value;
        cls.info.paid -= pack.info.paid;

        delete pack.info;
        
        uint[] memory seqs = pack.sharesList.values();
        uint len = seqs.length;

        list = new Request[](len);
        
        while (len > 0) {
            uint seq = seqs[len-1];
            list[len-1] = pack.requests[seq];
            delete pack.requests[seq];
            pack.sharesList.remove(seq);
            len--;
        }

        cls.packsList.remove(seqOfPack);
        delete cls.packs[seqOfPack];

    }

    //#################
    //##    Read     ##
    //#################

    /// @notice Check whether a class is redeemable.
    /// @param repo Storage repo.
    /// @param class Share class.
    function isRedeemable(
        Repo storage repo, uint class
    ) public view returns(bool){
        return repo.classesList.contains(class);
    }

    /// @notice Get list of redeemable classes.
    /// @param repo Storage repo.
    function getClassesList(
        Repo storage repo
    ) public view returns(uint[] memory list) {
        list = repo.classesList.values();
    }

    // ==== Class ====

    /// @notice Get class redemption info.
    /// @param repo Storage repo.
    /// @param class Share class.
    function getInfoOfClass(
        Repo storage repo, uint class
    ) public redeemableClass(repo, class) view returns(
        Request memory info
    ) {
        info = repo.classes[class].info;
    }

    /// @notice Get pack list under class.
    /// @param repo Storage repo.
    /// @param class Share class.
    function getPacksList(
        Repo storage repo, uint class
    ) public redeemableClass(repo, class) view returns(
        uint[] memory list
    ) {
        list = repo.classes[class].packsList.values();
    }

    // ==== Pack ====

    /// @notice Get pack summary info.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param seqOfPack Pack sequence.
    function getInfoOfPack(
        Repo storage repo, uint class, uint seqOfPack
    ) public redeemableClass(repo, class) redeemablePack(repo, class, seqOfPack) view returns(
        Request memory info
    ) {
        info = repo.classes[class].packs[seqOfPack].info;
    }

    /// @notice Get share list in pack.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param seqOfPack Pack sequence.
    function getSharesList(
        Repo storage repo, uint class, uint seqOfPack
    ) public redeemableClass(repo, class) redeemablePack(repo, class, seqOfPack) view returns(
        uint[] memory list
    ) {
        list = repo.classes[class].packs[seqOfPack].sharesList.values();
    }

    /// @notice Get request by share sequence.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param seqOfPack Pack sequence.
    /// @param seqOfShare Share sequence.
    function getRequest(
        Repo storage repo, uint class, uint seqOfPack, uint seqOfShare
    ) public redeemableClass(repo, class) redeemablePack(repo, class, seqOfPack) view returns(
        Request memory request
    ) {
        require(repo.classes[class].packs[seqOfPack].sharesList.contains(seqOfShare),
            "RR.getRequest: wrong seqOfShare");
        request = repo.classes[class].packs[seqOfPack].requests[seqOfShare];
    }

    /// @notice Get all requests in pack.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param seqOfPack Pack sequence.
    function getRequests(
        Repo storage repo, uint class, uint seqOfPack
    ) public redeemableClass(repo, class) redeemablePack(repo, class, seqOfPack) view returns(
        Request[] memory requests
    ) {
        Pack storage pack = repo.classes[class].packs[seqOfPack];

        uint[] memory seqs = pack.sharesList.values();
        uint len = seqs.length;
        requests = new Request[](len);
        while (len > 0) {
            requests[len-1] = pack.requests[seqs[len-1]];
            len--;
        }
    }

}

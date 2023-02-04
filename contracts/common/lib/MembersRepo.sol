// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// pragma experimental ABIEncoderV2;

import "./TopChain.sol";
import "./Checkpoints.sol";
import "./EnumerableSet.sol";

library MembersRepo {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using TopChain for TopChain.Chain;

    struct Member {
        Checkpoints.History votesInHand;
        EnumerableSet.Bytes32Set sharesInHand;
    }

    /*
        members[0] {
            votesInHand: ownersEquity;
            sharesInHand: sharesList;
        }
    */

    /* Node[0] {
        prev: tail;
        next: head;
        ptr: qtyOfMembers;
        amt: maxQtyOfMembers;
        sum: totalVotes;
        cat: basedOnPar;
    } */

    struct GeneralMeeting {
        TopChain.Chain chain;
        mapping(uint256 => Member) members;
    }

    //##################
    //##    写接口    ##
    //##################

    function setVoteBase(GeneralMeeting storage gm, bool onPar)
        internal
        returns (bool)
    {
        return gm.chain.setVoteBase(onPar);
    }

    // ==== restore mapping ====

    function restoreChain(
        GeneralMeeting storage gm,
        TopChain.Node[] memory snapshot
    ) internal {
        gm.chain.restoreChain(snapshot);
    }

    // ==== Zero Node Setting ====

    function setMaxQtyOfMembers(GeneralMeeting storage gm, uint32 max)
        internal
    {
        gm.chain.setMaxQtyOfMembers(max);
    }

    function setAmtBase(GeneralMeeting storage gm, bool _basedOnPar)
        internal
        returns (bool flag)
    {
        if (basedOnPar(gm) != _basedOnPar) {
            uint40[] memory members = gm.chain.membersList();
            uint256 len = members.length;

            while (len > 0) {
                uint40 cur = members[len - 1];

                (uint64 paid, uint64 par) = gm
                    .members[cur]
                    .votesInHand
                    .latest();

                if (paid != par) {
                    if (_basedOnPar)
                        gm.chain.changeAmt(cur, (par - paid), true);
                    else gm.chain.changeAmt(cur, (par - paid), false);
                }

                len--;
            }

            gm.chain.setVoteBase(_basedOnPar);

            flag = true;
        }
    }

    // ==== Member ====

    function addMember(GeneralMeeting storage gm, uint40 acct)
        internal
        returns (bool flag)
    {
        flag = gm.chain.addNode(acct);
    }

    function delMember(GeneralMeeting storage gm, uint40 acct)
        internal
        returns (bool flag)
    {
        if (gm.chain.delNode(acct)) {
            delete gm.members[acct];
            flag = true;
        }
    }

    function addShareToMember(
        GeneralMeeting storage gm,
        bytes32 shareNumber,
        uint40 acct
    ) internal returns (bool flag) {
        if (addShareNumberToList(gm, shareNumber)) {
            flag = gm.members[acct].sharesInHand.add(shareNumber);
        }
    }

    function removeShareFromMember(
        GeneralMeeting storage gm,
        bytes32 shareNumber,
        uint40 acct
    ) internal returns (bool flag) {
        if (removeShareNumberFromList(gm, shareNumber)) {
            flag = gm.members[acct].sharesInHand.remove(shareNumber);
        }
    }

    function addMemberToGroup(
        GeneralMeeting storage gm,
        uint40 acct,
        uint40 root
    ) internal returns (bool flag) {
        flag = gm.chain.top2Sub(acct, root);
    }

    function removeMemberFromGroup(GeneralMeeting storage gm, uint40 acct)
        internal
        returns (bool flag)
    {
        flag = gm.chain.sub2Top(acct);
    }

    function changeAmtOfMember(
        GeneralMeeting storage gm,
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool increase
    ) internal returns (uint64 blocknumber) {
        uint64 deltaAmt = (basedOnPar(gm)) ? deltaPar : deltaPaid;
        gm.chain.changeAmt(acct, deltaAmt, increase);

        (uint64 paid, uint64 par) = gm.members[acct].votesInHand.latest();

        if (increase) {
            paid += deltaPaid;
            par += deltaPar;
        } else {
            paid -= deltaPaid;
            par -= deltaPar;
        }

        blocknumber = gm.members[acct].votesInHand.push(paid, par);
    }

    function changeAmtOfCap(
        GeneralMeeting storage gm,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool increase
    ) internal returns (uint64 blocknumber) {
        (uint64 paid, uint64 par) = ownersEquity(gm);

        if (increase) {
            paid += deltaPaid;
            par += deltaPar;
        } else {
            paid -= deltaPaid;
            par -= deltaPar;
        }

        blocknumber = updateOwnersEquity(gm, paid, par);
    }

    // ==== Zero Node Setting ====

    function addShareNumberToList(
        GeneralMeeting storage gm,
        bytes32 shareNumber
    ) internal returns (bool flag) {
        flag = gm.members[0].sharesInHand.add(shareNumber);
    }

    function removeShareNumberFromList(
        GeneralMeeting storage gm,
        bytes32 shareNumber
    ) internal returns (bool flag) {
        flag = gm.members[0].sharesInHand.remove(shareNumber);
    }

    function updateOwnersEquity(
        GeneralMeeting storage gm,
        uint64 paid,
        uint64 par
    ) internal returns (uint64 blocknumber) {
        blocknumber = gm.members[0].votesInHand.push(paid, par);
    }

    //##################
    //##    读接口    ##
    //##################

    function basedOnPar(GeneralMeeting storage gm)
        internal
        view
        returns (bool)
    {
        return gm.chain.basedOnPar();
    }

    // ==== Zero Node ====

    function maxQtyOfMembers(GeneralMeeting storage gm)
        internal
        view
        returns (uint32)
    {
        return gm.chain.maxQtyOfMembers();
    }

    function tailOfChain(GeneralMeeting storage gm)
        internal
        view
        returns (uint40)
    {
        return gm.chain.tail();
    }

    function controllor(GeneralMeeting storage gm)
        internal
        view
        returns (uint40)
    {
        return gm.chain.head();
    }

    function totalVotes(GeneralMeeting storage gm)
        internal
        view
        returns (uint64)
    {
        return gm.chain.totalVotes();
    }

    // ==== shares ====

    function sharesList(GeneralMeeting storage gm)
        internal
        view
        returns (bytes32[] memory)
    {
        return gm.members[0].sharesInHand.values();
    }

    function isShareNumber(GeneralMeeting storage gm, bytes32 sharenumber)
        internal
        view
        returns (bool)
    {
        return gm.members[0].sharesInHand.contains(sharenumber);
    }

    // ==== members ====

    function isMember(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (bool)
    {
        return gm.chain.isMember(acct);
    }

    function qtyOfMembers(GeneralMeeting storage gm)
        internal
        view
        returns (uint32 qty)
    {
        qty = gm.chain.qtyOfMembers();
    }

    function membersList(GeneralMeeting storage gm)
        internal
        view
        returns (uint40[] memory)
    {
        return gm.chain.membersList();
    }

    function nextMember(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint40 next)
    {
        return gm.chain.nextNode(acct);
    }

    // ==== member ====

    function paidOfMember(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint64 paid)
    {
        (paid, ) = gm.members[acct].votesInHand.latest();
    }

    function parOfMember(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint64 par)
    {
        (, par) = gm.members[acct].votesInHand.latest();
    }

    function votesInHand(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint64 votes)
    {
        votes = gm.chain.nodes[acct].amt;
    }

    function votesAtBlock(
        GeneralMeeting storage gm,
        uint40 acct,
        uint64 blocknumber
    ) internal view returns (uint64 vote) {
        if (basedOnPar(gm))
            (, vote) = gm.members[acct].votesInHand.getAtBlock(blocknumber);
        else (vote, ) = gm.members[acct].votesInHand.getAtBlock(blocknumber);
    }

    function sharesInHand(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (bytes32[] memory)
    {
        return gm.members[acct].sharesInHand.values();
    }

    function qtyOfSharesInHand(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint256)
    {
        return gm.members[acct].sharesInHand.length();
    }

    // ==== group ====

    function groupRep(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint40)
    {
        return gm.chain.rootOf(acct);
    }

    function qtyOfGroups(GeneralMeeting storage gm)
        internal
        view
        returns (uint32)
    {
        return gm.chain.qtyOfBranches();
    }

    function votesOfHead(GeneralMeeting storage gm)
        internal
        view
        returns (uint64)
    {
        uint40 head = controllor(gm);
        return gm.chain.nodes[head].sum;
    }

    function isGroupRep(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (bool)
    {
        return gm.chain.rootOf(acct) == acct;
    }

    function votesOfGroup(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint64)
    {
        return gm.chain.votesOfGroup(acct);
    }

    function membersOfGroup(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint40[] memory)
    {
        return gm.chain.membersOfGroup(acct);
    }

    function affiliated(
        GeneralMeeting storage gm,
        uint40 acct1,
        uint40 acct2
    ) internal view returns (bool) {
        return gm.chain.affiliated(acct1, acct2);
    }

    function deepOfGroup(GeneralMeeting storage gm, uint40 acct)
        internal
        view
        returns (uint32)
    {
        return gm.chain.deepOfBranch(acct);
    }

    function ownersEquity(GeneralMeeting storage gm)
        internal
        view
        returns (uint64 paid, uint64 par)
    {
        (paid, par) = gm.members[0].votesInHand.latest();
    }

    function paidCap(GeneralMeeting storage gm)
        internal
        view
        returns (uint64 paid)
    {
        (paid, ) = gm.members[0].votesInHand.latest();
    }

    function parCap(GeneralMeeting storage gm)
        internal
        view
        returns (uint64 par)
    {
        (, par) = gm.members[0].votesInHand.latest();
    }

    function capAtBlock(GeneralMeeting storage gm, uint64 blocknumber)
        internal
        view
        returns (uint64 paid, uint64 par)
    {
        (paid, par) = gm.members[0].votesInHand.getAtBlock(blocknumber);
    }

    function getSnapshot(GeneralMeeting storage gm)
        internal
        view
        returns (TopChain.Node[] memory)
    {
        return gm.chain.getSnapshot();
    }
}

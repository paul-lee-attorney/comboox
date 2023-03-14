// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// pragma experimental ABIEncoderV2;

import "../../books/boa/IInvestmentAgreement.sol";
// import "../../books/bos/IBookOfShares.sol";
// import "../../books/rom/IRegisterOfMembers.sol";

import "./TopChain.sol";
import "./Checkpoints.sol";
import "./EnumerableSet.sol";
// import "./RulesParser.sol";

library MembersRepo {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.UintSet;
    using TopChain for TopChain.Chain;

    struct Member {
        Checkpoints.History votesInHand;
        EnumerableSet.UintSet sharesInHand;
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

    // ==== Zero Node Setting ====

    function setAmtBase(GeneralMeeting storage gm, bool _basedOnPar)
        public
        returns (bool flag)
    {
        if (gm.chain.basedOnPar() != _basedOnPar) {
            uint256[] memory members = gm.chain.membersList();
            uint256 len = members.length;

            while (len > 0) {
                uint256 cur = members[len - 1];

                Checkpoints.Checkpoint memory cp = gm.members[cur].votesInHand.latest();

                if (cp.paid != cp.par) {
                    if (_basedOnPar)
                        gm.chain.changeAmt(cur, (cp.par - cp.paid), true);
                    else gm.chain.changeAmt(cur, (cp.par - cp.paid), false);
                }

                len--;
            }

            gm.chain.setVoteBase(_basedOnPar);

            flag = true;
        }
    }

    // ==== Member ====

    function delMember(GeneralMeeting storage gm, uint40 acct)
        public
        returns (bool flag)
    {
        if (gm.chain.delNode(acct)) {
            delete gm.members[acct];
            flag = true;
        }
    }

    function addShareToMember(
        GeneralMeeting storage gm,
        uint32 seqOfShare,
        uint40 acct
    ) public returns (bool flag) {
        if (addSeqOfShareToList(gm, seqOfShare)) {
            flag = gm.members[acct].sharesInHand.add(seqOfShare);
        }
    }

    function removeShareFromMember(
        GeneralMeeting storage gm,
        uint32 seqOfShare,
        uint40 acct
    ) public returns (bool flag) {
        if (removeSeqOfShareFromList(gm, seqOfShare)) {
            flag = gm.members[acct].sharesInHand.remove(seqOfShare);
        }
    }

    function changeAmtOfMember(
        GeneralMeeting storage gm,
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool increase
    ) public {
        uint64 deltaAmt = (gm.chain.basedOnPar()) ? deltaPar : deltaPaid;
        gm.chain.changeAmt(acct, deltaAmt, increase);

        Checkpoints.Checkpoint memory cp = gm.members[acct].votesInHand.latest();

        if (increase) {
            cp.paid += deltaPaid;
            cp.par += deltaPar;
        } else {
            cp.paid -= deltaPaid;
            cp.par -= deltaPar;
        }

        gm.members[acct].votesInHand.push(cp.paid, cp.par, cp.cleanPaid);
    }

    function changeAmtOfCap(
        GeneralMeeting storage gm,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool increase
    ) public {
        Checkpoints.Checkpoint memory cp = gm.members[0].votesInHand.latest();

        if (increase) {
            cp.paid += deltaPaid;
            cp.par += deltaPar;
        } else {
            cp.paid -= deltaPaid;
            cp.par -= deltaPar;
        }

        updateOwnersEquity(gm, cp);
    }

    // ==== Zero Node Setting ====

    function addSeqOfShareToList(
        GeneralMeeting storage gm,
        uint32 seqOfShare
    ) public returns (bool flag) {
        flag = gm.members[0].sharesInHand.add(seqOfShare);
    }

    function removeSeqOfShareFromList(
        GeneralMeeting storage gm,
        uint32 seqOfShare
    ) public returns (bool flag) {
        flag = gm.members[0].sharesInHand.remove(seqOfShare);
    }

    function updateOwnersEquity(
        GeneralMeeting storage gm,
        Checkpoints.Checkpoint memory cp
    ) public {
        gm.members[0].votesInHand.push(cp.paid, cp.par, cp.cleanPaid);
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== member ====

    function votesAtDate(
        GeneralMeeting storage gm,
        uint256 acct,
        uint48 date
    ) public view returns (uint64 vote) {
        Checkpoints.Checkpoint memory cp = gm.members[acct].votesInHand.getAtDate(date);
        vote = gm.chain.basedOnPar() ? cp.par : cp.paid;
    }
}

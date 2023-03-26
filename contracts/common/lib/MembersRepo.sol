// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ArrayUtils.sol";
import "./Checkpoints.sol";
import "./EnumerableSet.sol";
import "./SharesRepo.sol";
import "./TopChain.sol";

library MembersRepo {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.UintSet;
    using TopChain for TopChain.Chain;
    using SharesRepo for SharesRepo.Head;
    using ArrayUtils for uint256[];

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

    struct Repo {
        TopChain.Chain chain;
        mapping(uint256 => Member) members;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== Zero Node Setting ====

    function setAmtBase(Repo storage gm, bool _basedOnPar)
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

    function delMember(Repo storage gm, uint40 acct)
        public
        returns (bool flag)
    {
        if (gm.chain.delNode(acct)) {
            delete gm.members[acct];
            flag = true;
        }
    }

    function addShareToMember(
        Repo storage gm,
        SharesRepo.Head memory head
    ) public returns (bool flag) {
        uint256 shareNumber = head.codifyHead();
        if (addShareNumberToList(gm, shareNumber)) {
            flag = gm.members[head.shareholder].sharesInHand.add(shareNumber);
        }
    }

    function removeShareFromMember(
        Repo storage gm,
        SharesRepo.Head memory head
    ) public returns (bool flag) {
        uint256 shareNumber = head.codifyHead();
        if (removeShareNumberFromList(gm, shareNumber)) {
            flag = gm.members[head.shareholder].sharesInHand.remove(shareNumber);
        }
    }

    function changeAmtOfMember(
        Repo storage gm,
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
        Repo storage gm,
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

    function addShareNumberToList(
        Repo storage gm,
        uint256 shareNumber
    ) public returns (bool flag) {
        flag = gm.members[0].sharesInHand.add(shareNumber);
    }

    function removeShareNumberFromList(
        Repo storage gm,
        uint256 shareNumber
    ) public returns (bool flag) {
        flag = gm.members[0].sharesInHand.remove(shareNumber);
    }

    function updateOwnersEquity(
        Repo storage gm,
        Checkpoints.Checkpoint memory cp
    ) public {
        gm.members[0].votesInHand.push(cp.paid, cp.par, cp.cleanPaid);
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== member ====

    function votesAtDate(
        Repo storage gm,
        uint256 acct,
        uint48 date
    ) public view returns (uint64 vote) {
        Checkpoints.Checkpoint memory cp = gm.members[acct].votesInHand.getAtDate(date);
        vote = gm.chain.basedOnPar() ? cp.par : cp.paid;
    }

    function isClassMember(Repo storage gm, uint256 acct, uint16 class)
        public view returns (bool flag)
    {
        uint256[] memory shares = gm.members[acct].sharesInHand.values();
        uint256 len = shares.length;
        while (len > 0) {
            if (uint16(shares[len-1] >> 176) == class) {
                flag = true;
                return flag;
            }
            len--;
        }
    }

    function getMembersOfClass(Repo storage gm, uint16 class)
        public view returns(uint256[] memory output)
    {
        uint256[] memory shares = gm.members[0].sharesInHand.values();
        uint256 len = shares.length;

        uint256[] memory members = new uint256[](gm.chain.nodes[0].ptr);

        uint256 i;
        while (len > 0) {
            if (uint16(shares[len-1] >> 176) == class) {
                uint40 shareholder = uint40(shares[len-1] >> 40);

                uint256 j;
                while (j<i) {
                    if (members[j] == shareholder) break;
                    j++; 
                }
                if (j==i){
                    members[i] = shareholder;
                    i++;
                }
            }
            len--;
        }

        output = members.resize(i);
    }

}

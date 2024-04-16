// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

import "./Checkpoints.sol";
import "./EnumerableSet.sol";
import "./SharesRepo.sol";
import "./TopChain.sol";

import "../comps/books/ros/IRegisterOfShares.sol";

library MembersRepo {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.UintSet;
    using TopChain for TopChain.Chain;

    struct Member {
        Checkpoints.History votesInHand;
        // class => seqList
        mapping(uint => EnumerableSet.UintSet) sharesOfClass;
        EnumerableSet.UintSet classesBelonged;
    }

    /*
        members[0] {
            votesInHand: ownersEquity;
        }
    */

    /* Node[0] {
        prev: tail;
        next: head;
        ptr: pending;
        amt: pending;
        sum: totalVotes;
        cat: basedOnPar;
    } */

    struct Repo {
        TopChain.Chain chain;
        mapping(uint256 => Member) members;
        // class => membersList
        mapping(uint => EnumerableSet.UintSet) membersOfClass;
    }

    //###############
    //##  Modifer  ##
    //###############

    modifier memberExist(
        Repo storage repo,
        uint acct
    ) {
        require(isMember(repo, acct),
            "MR.memberExist: not");
        _;
    }

    //##################
    //##  Write I/O  ##
    //##################

    // ==== Zero Node Setting ====

    function setVoteBase(
        Repo storage repo,
        IRegisterOfShares ros,
        bool _basedOnPar
    ) public returns (bool flag) {

        if (repo.chain.basedOnPar() != _basedOnPar) {
            uint256[] memory members = 
                repo.membersOfClass[0].values();
            uint256 len = members.length;

            while (len > 0) {
                uint256 cur = members[len - 1];

                Member storage m = repo.members[cur];

                Checkpoints.Checkpoint memory cp = 
                    m.votesInHand.latest();

                if (cp.paid != cp.par) {

                    (uint sumOfVotes, uint sumOfDistrs) = _sortWeights(m, ros, _basedOnPar);

                    if (_basedOnPar) {
                        repo.chain.increaseAmt(cur, sumOfVotes - cp.points, true);
                    } else {
                        repo.chain.increaseAmt(cur, cp.points - sumOfVotes, false);
                    }

                    uint64 amt = _basedOnPar ? cp.par : cp.paid;

                    cp.rate = uint16(sumOfVotes * 100 / amt);
                    m.votesInHand.push(cp.rate, cp.paid, cp.par, cp.points);

                    cp.rate = uint16(sumOfDistrs * 100 / amt);
                    cp.points = uint64(sumOfDistrs);
                    m.votesInHand.updateDistrPoints(cp.rate, cp.paid, cp.par, cp.points);
                }

                len--;
            }

            repo.chain.setVoteBase(_basedOnPar);

            flag = true;
        }
    }

    function _sortWeights(
        Member storage m,
        IRegisterOfShares ros,
        bool basedOnPar
    ) private view returns(uint sumOfVotes, uint sumOfDistrs) { 

        uint[] memory ls = m.sharesOfClass[0].values();
        uint len = ls.length;

        while (len > 0) {
            SharesRepo.Share memory share = ros.getShare(ls[len-1]);

            uint amt = basedOnPar ? share.body.par : share.body.paid;

            sumOfVotes += amt * share.head.votingWeight / 100;
            sumOfDistrs += amt * share.body.distrWeight / 100;

            len--;            
        }
    }

    // ==== Member ====

    function addMember(
        Repo storage repo, 
        uint acct
    ) public returns (bool flag) {
        if (repo.membersOfClass[0].add(acct)) {
            repo.chain.addNode(acct);
            flag = true;
        }
    }

    function delMember(
        Repo storage repo, 
        uint acct
    ) public {
        if (repo.membersOfClass[0].remove(acct)) {
            repo.chain.delNode(acct);
            delete repo.members[acct];
        }
    }

    function addShareToMember(
        Repo storage repo,
        SharesRepo.Head memory head
    ) public {

        Member storage member = repo.members[head.shareholder];

        if (member.sharesOfClass[0].add(head.seqOfShare)
            && member.sharesOfClass[head.class].add(head.seqOfShare)
            && member.classesBelonged.add(head.class))
                repo.membersOfClass[head.class].add(head.shareholder);
    }

    function removeShareFromMember(
        Repo storage repo,
        SharesRepo.Head memory head
    ) public {

        Member storage member = 
            repo.members[head.shareholder];
        
        if (member.sharesOfClass[head.class].remove(head.seqOfShare)
            && member.sharesOfClass[0].remove(head.seqOfShare)) {

            if(member.sharesOfClass[head.class].length() == 0) {
                repo.membersOfClass[head.class].remove(head.shareholder);
                member.classesBelonged.remove(head.class);
            }
        }

    }

    function increaseAmtOfMember(
        Repo storage repo,
        uint acct,
        uint votingWeight,
        uint distrWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) public {
        _increaseAmtOfMember(repo, acct, votingWeight, distrWeight, deltaPaid, deltaPar, isIncrease);
    }

    function _increaseAmtOfMember(
        Repo storage repo,
        uint acct,
        uint votingWeight,
        uint distrWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) private {

        Member storage m = repo.members[acct];
        bool basedOnPar = repo.chain.basedOnPar();
        uint64 deltaAmt =  basedOnPar ? uint64(deltaPar) : uint64(deltaPaid);

        Checkpoints.Checkpoint memory delta = Checkpoints.Checkpoint({
            timestamp: 0,
            rate: 0,
            paid: uint64(deltaPaid),
            par: uint64(deltaPar),
            points: uint64(deltaAmt * votingWeight / 100)
        });

        if (acct > 0 && deltaAmt > 0) {
            repo.chain.increaseAmt(
                acct, 
                delta.points,
                isIncrease
            );
        }

        Checkpoints.Checkpoint memory cp = 
            m.votesInHand.latest();

        cp = _adjustCheckpoint(cp, delta, basedOnPar, isIncrease);

        m.votesInHand.push(cp.rate, cp.paid, cp.par, cp.points);

        Checkpoints.Checkpoint memory dp = 
            m.votesInHand.getDistrPoints();
        
        delta.points = deltaAmt * uint16(distrWeight) / 100;

        dp = _adjustCheckpoint(dp, delta, basedOnPar, isIncrease);

        m.votesInHand.updateDistrPoints(dp.rate, dp.paid, dp.par, dp.points);
    }

    function _adjustCheckpoint(
        Checkpoints.Checkpoint memory cp,
        Checkpoints.Checkpoint memory delta,
        bool basedOnPar,
        bool isIncrease
    ) private pure returns (Checkpoints.Checkpoint memory output) {

        if (isIncrease) {
            output.paid = cp.paid + delta.paid;
            output.par = cp.par + delta.par;
            output.points = cp.points + delta.points;
        } else {
            output.paid = cp.paid - delta.paid;
            output.par = cp.par - delta.par;
            output.points = cp.points - delta.points;
        }

        output.rate = basedOnPar
            ?  output.par > 0 ? uint16(output.points * 100 / output.par) : 0
            :  output.paid > 0 ? uint16(output.points * 100 / output.paid) : 0;
    }

    // function _calWeight(
    //     Checkpoints.Checkpoint memory cp,
    //     bool basedOnPar,
    //     Checkpoints.Checkpoint memory delta,
    //     bool isIncrease
    // ) private pure returns(uint16 output) {
        
    //     if (isIncrease) {
    //         output = basedOnPar
    //             ? uint16(((cp.votingWeight * cp.par + delta.votingWeight * delta.par) * 100 / (cp.par + delta.par) + 50) / 100)
    //             : uint16(((cp.votingWeight * cp.paid + delta.votingWeight * delta.paid) * 100 / (cp.paid + delta.paid) + 50) / 100);
    //     } else {
    //         output = basedOnPar
    //             ? uint16(((cp.votingWeight * cp.par - delta.votingWeight * delta.par) * 100 / (cp.par - delta.par) + 50) / 100)
    //             : uint16(((cp.votingWeight * cp.paid - delta.votingWeight * delta.paid) * 100 / (cp.paid - delta.paid) + 50) / 100);
    //     }
    // }

    function increaseAmtOfCap(
        Repo storage repo,
        uint votingWeight,
        uint distrWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) public {

        _increaseAmtOfMember(repo, 0, votingWeight, distrWeight, deltaPaid, deltaPar, isIncrease);
        
        bool basedOnPar = repo.chain.basedOnPar();

        if (basedOnPar && deltaPar > 0) {
            repo.chain.increaseTotalVotes(deltaPar * votingWeight / 100, isIncrease);
        } else if (!basedOnPar && deltaPaid > 0) {
            repo.chain.increaseTotalVotes(deltaPaid * votingWeight / 100, isIncrease);
        }
    }

    //##################
    //##    Read      ##
    //##################

    // ==== member ====

    function isMember(
        Repo storage repo,
        uint acct
    ) public view returns(bool) {
        return repo.membersOfClass[0].contains(acct);
    }
    
    function qtyOfMembers(
        Repo storage repo
    ) public view returns(uint) {
        return repo.membersOfClass[0].length();
    }

    function membersList(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.membersOfClass[0].values();
    }

    // ---- Votes ----

    function ownersEquity(
        Repo storage repo
    ) public view returns(Checkpoints.Checkpoint memory) {
        return repo.members[0].votesInHand.latest();
    }

    function ownersPoints(
        Repo storage repo
    ) public view returns(Checkpoints.Checkpoint memory) {
        return repo.members[0].votesInHand.getDistrPoints();
    }

    function capAtDate(
        Repo storage repo,
        uint date
    ) public view returns(Checkpoints.Checkpoint memory) {
        return repo.members[0].votesInHand.getAtDate(date);
    }

    function equityOfMember(
        Repo storage repo,
        uint acct
    ) public view memberExist(repo, acct) returns(
        Checkpoints.Checkpoint memory
    ) {
        return repo.members[acct].votesInHand.latest();
    }

    function pointsOfMember(
        Repo storage repo,
        uint acct
    ) public view memberExist(repo, acct) returns(
        Checkpoints.Checkpoint memory
    ) {
        return repo.members[acct].votesInHand.getDistrPoints();
    }

    function equityAtDate(
        Repo storage repo,
        uint acct,
        uint date
    ) public view memberExist(repo, acct) returns(
        Checkpoints.Checkpoint memory
    ) {
        return repo.members[acct].votesInHand.getAtDate(date);
    }

    function votesAtDate(
        Repo storage repo,
        uint256 acct,
        uint date
    ) public view returns (uint64) { 
        return repo.members[acct].votesInHand.getAtDate(date).points;
    }

    function votesHistory(
        Repo storage repo,
        uint acct
    ) public view memberExist(repo, acct) 
        returns (Checkpoints.Checkpoint[] memory) 
    {
        return repo.members[acct].votesInHand.pointsOfHistory();
    }

    // ---- Class ----

    function isClassMember(
        Repo storage repo, 
        uint256 acct, 
        uint class
    ) public view memberExist(repo, acct) returns (bool flag) {
        return repo.members[acct].classesBelonged.contains(class);
    }

    function classesBelonged(
        Repo storage repo, 
        uint256 acct
    ) public view memberExist(repo, acct) returns (uint[] memory) {
        return repo.members[acct].classesBelonged.values();
    }

    function qtyOfClassMember(
        Repo storage repo, 
        uint class
    ) public view returns(uint256) {
        return repo.membersOfClass[class].length();
    }

    function getMembersOfClass(
        Repo storage repo, 
        uint class
    ) public view returns(uint256[] memory) {
        return repo.membersOfClass[class].values();
    }

    // ---- Share ----

    function qtyOfSharesInHand(
        Repo storage repo, 
        uint acct
    ) public view memberExist(repo, acct) returns(uint) {
        return repo.members[acct].sharesOfClass[0].length();
    }

    function sharesInHand(
        Repo storage repo, 
        uint acct
    ) public view memberExist(repo, acct) returns(uint[] memory) {
        return repo.members[acct].sharesOfClass[0].values();
    }

    function qtyOfSharesInClass(
        Repo storage repo, 
        uint acct,
        uint class
    ) public view memberExist(repo, acct) returns(uint) {
        require(isClassMember(repo, acct, class), 
            "MR.qtyOfSharesInClass: not class member");
        return repo.members[acct].sharesOfClass[class].length();
    }

    function sharesInClass(
        Repo storage repo, 
        uint acct,
        uint class
    ) public view memberExist(repo, acct) returns(uint[] memory) {
        require(isClassMember(repo, acct, class),
            "MR.sharesInClass: not class member");
        return repo.members[acct].sharesOfClass[class].values();
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library BallotsBox {

    enum AttitudeOfVote {
        All,
        Support,
        Against,
        Abstain
    }

    struct Ballot {
        uint40 acct;
        uint8 attitude;
        uint32 head;
        uint64 weight;
        uint48 sigDate;
        uint64 blocknumber;
        bytes32 sigHash;
    }

    struct Case {
        uint32 sumOfHead;
        uint64 sumOfWeight;
        uint40[] voters;
    }

    struct Box {
        mapping(uint256 => Case) cases;
        mapping(uint256 => Ballot) ballots;
    }

    // #################
    // ##    Write    ##
    // #################

    function castVote(
        Box storage box,
        uint40 acct,
        uint8 attitude,
        uint32 head,
        uint64 weight,
        bytes32 sigHash
    ) public returns (bool flag) {        
        require(
            attitude == uint8(AttitudeOfVote.Support) ||
                attitude == uint8(AttitudeOfVote.Against) ||
                attitude == uint8(AttitudeOfVote.Abstain),
            "BB.CV: attitude overflow"
        );

        if (box.ballots[acct].sigDate == 0) {
            box.ballots[acct] = Ballot({
                acct: acct,
                attitude: attitude,
                head: head,
                weight: weight,
                sigDate: uint48(block.timestamp),
                blocknumber: uint64(block.number),
                sigHash: sigHash
            });

            box.cases[attitude].sumOfHead += head;
            box.cases[attitude].sumOfWeight += weight;
            box.cases[attitude].voters.push(acct);

            box.cases[uint8(AttitudeOfVote.All)].sumOfHead += head;
            box.cases[uint8(AttitudeOfVote.All)].sumOfWeight += weight;
            box.cases[uint8(AttitudeOfVote.All)].voters.push(acct);

            flag = true;
        }
    }

    // ################
    // ##    Read    ##
    // ################

    // function isVoted(Box storage box, uint40 acct) public view returns (bool) {
    //     return box.ballots[acct].sigDate > 0;
    // }

    // function isVotedFor(Box storage box, uint40 acct, uint8 attitude) public view returns (bool) {
    //     return box.ballots[acct].attitude == attitude;
    // }

    // function getCaseOfAttitude(Box storage box, uint8 attitude) 
    //     public view returns (Case memory) 
    // {
    //     return box.cases[attitude];
    // }

    // function getWeightOfAttitude(Box storage box, uint8 attitude) public view returns (uint64) {
    //     return box.cases[attitude].sumOfWeight;
    // }

    // function getHeadOfAttitude(Box storage box, uint8 attitude) public view returns (uint32) {
    //     return box.cases[attitude].sumOfHead;
    // }

    // function getBallot(Box storage box, uint40 acct) 
    //     public view 
    //     returns (Ballot memory b) 
    // {
    //     b = box.ballots[acct];
    // }
}

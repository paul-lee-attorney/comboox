// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library BallotsBox {
    using EnumerableSet for EnumerableSet.UintSet;

    enum AttitudeOfVote {
        All,
        Support,
        Against,
        Abstain
    }

    struct Ballot {
        uint8 attitude;
        uint64 weight;
        uint64 blocknumber;
        uint48 sigDate;
        bytes32 sigHash;
    }

    struct Case {
        uint64 sumOfWeight;
        EnumerableSet.UintSet voters;
    }

    struct Box {
        Case[4] cases;
        mapping(uint256 => Ballot) ballots;
    }

    // #################
    // ##    Write    ##
    // #################

    function castVote(
        Box storage box,
        uint40 acct,
        uint8 attitude,
        uint64 weight,
        bytes32 sigHash
    ) public returns (bool flag) {
        require(
            attitude == uint8(AttitudeOfVote.Support) ||
                attitude == uint8(AttitudeOfVote.Against) ||
                attitude == uint8(AttitudeOfVote.Abstain),
            "BB.castVote: attitude overflow"
        );

        if (box.ballots[acct].sigDate == 0) {
            box.ballots[acct] = Ballot({
                weight: weight,
                attitude: attitude,
                blocknumber: uint64(block.number),
                sigDate: uint48(block.timestamp),
                sigHash: sigHash
            });

            box.cases[attitude].sumOfWeight += weight;
            box.cases[attitude].voters.add(acct);

            box.cases[uint8(AttitudeOfVote.All)].sumOfWeight += weight;
            box.cases[uint8(AttitudeOfVote.All)].voters.add(acct);

            flag = true;
        }
    }
}

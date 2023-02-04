// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
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
    ) internal returns (bool flag) {
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

    // // #################
    // // ##    Read     ##
    // // #################

    // function votedYea(Box storage box, uint40 acct)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return box.supportVoters.contains(acct);
    // }

    // function votedNay(Box storage box, uint40 acct)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return box.againstVoters.contains(acct);
    // }

    // function votedAbs(Box storage box, uint40 acct)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return box.abstainVoters.contains(acct);
    // }

    // function getYea(Box storage box)
    //     internal
    //     view
    //     returns (uint40[] memory members, uint64 weights)
    // {
    //     members = box.supportVoters.valuesToUint40();
    //     weights = box.sumOfYea;
    // }

    // function qtyOfYea(Box storage box) internal view returns (uint256) {
    //     return box.supportVoters.length();
    // }

    // function getNay(Box storage box)
    //     internal
    //     view
    //     returns (uint40[] memory members, uint64 weights)
    // {
    //     members = box.againstVoters.valuesToUint40();
    //     weights = box.sumOfNay;
    // }

    // function qtyOfNay(Box storage box) internal view returns (uint256) {
    //     return box.againstVoters.length();
    // }

    // function getAbs(Box storage box)
    //     internal
    //     view
    //     returns (uint40[] memory members, uint64 weight)
    // {
    //     members = box.abstainVoters.valuesToUint40();
    //     weight = box.sumOfAbs;
    // }

    // function qtyOfAbs(Box storage box) internal view returns (uint256) {
    //     return box.abstainVoters.length();
    // }

    // function allVoters(Box storage box)
    //     internal
    //     view
    //     returns (uint40[] memory)
    // {
    //     return box.voters;
    // }

    // function qtyOfAllVoters(Box storage box) internal view returns (uint256) {
    //     return box.voters.length;
    // }

    // function isVoted(Box storage box, uint40 acct)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return box.ballots[acct].sigDate != 0;
    // }

    // function getVote(Box storage box, uint40 acct)
    //     internal
    //     view
    //     returns (
    //         uint40 voter,
    //         uint64 weight,
    //         uint8 attitude,
    //         uint64 blocknumber,
    //         uint48 sigDate,
    //         bytes32 sigHash
    //     )
    // {
    //     Ballot storage b = box.ballots[acct];

    //     voter = b.voter;
    //     weight = b.weight;
    //     attitude = b.attitude;
    //     blocknumber = b.blocknumber;
    //     sigDate = b.sigDate;
    //     sigHash = b.sigHash;
    // }
}

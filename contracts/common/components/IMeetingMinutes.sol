// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/MotionsRepo.sol";
import "../lib/DelegateMap.sol";
import "../lib/BallotsBox.sol";
import "../lib/RulesParser.sol";

import "./IRepoOfDocs.sol";

interface IMeetingMinutes {

    //##################
    //##    events    ##
    //##################

    event ProposeMotion(
        uint256 indexed motionId,
        uint256 seqOfRule,
        uint256 proposer,
        uint256 executor
    );

    event EntrustDelegate(
        uint256 indexed motionId,
        uint256 principal,
        uint256 delegate,
        uint64 weight
    );

    event CastVote(
        uint256 indexed motionId,
        uint256 caller,
        uint8 attitude,
        bytes32 sigHash
    );

    event VoteCounting(uint256 indexed motionId, uint8 state);

    event ExecuteAction(uint256 indexed motionId, bool flag);

    //##################
    //##    写接口    ##
    //##################

    function proposeMotion(
        uint256 motionId,
        uint256 seqOfVR,
        uint256 proposer,
        uint256 executor
    ) external;

    function nominateOfficer(
        uint256 seqOfVR,
        uint8 title, 
        uint256 nominator, 
        uint256 candidate
    ) external;

    function proposeDoc(
        address doc,
        uint256 seqOfVR,
        uint256 proposer,
        uint256 executor
    ) external;

    function proposeAction(
        uint256 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 proposer,
        uint256 executor
    ) external;

    // ==== delegate ====

    function entrustDelegate(
        uint256 motionId,
        uint256 principal,
        uint256 delegate
    ) external;

    function castVote(
        uint256 motionId,
        uint256 caller,
        uint8 attitude,
        bytes32 sigHash
    ) external;

    function voteCounting(uint256 motionId) external returns (bool flag);

    function motionExecuted(uint256 motionId) external;

    function execAction(
        uint256 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        uint256 caller,
        bytes32 desHash
    ) external returns (uint256);

    //##################
    //##    Read     ##
    //################

    // ==== delegate ====

    function getVoterOfDelegateMap(uint256 motionId, uint256 acct)
        external
        view
        returns (DelegateMap.Voter memory v);

    function getDelegateOf(uint256 motionId, uint256 acct)
        external
        view
        returns (uint40);

    // ==== motion ====

    function isProposed(uint256 motionId) external view returns (bool);

    function getHeadOfMotion(uint256 motionId)
        external
        view
        returns (MotionsRepo.Head memory head);

    function getVotingRuleOfMotion(uint256 motionId) external view returns (RulesParser.VotingRule memory);

    // ==== voting ====

    function isVoted(uint256 motionId, uint256 acct) 
        external 
        view 
        returns (bool);

    function isVotedFor(
        uint256 motionId,
        uint256 acct,
        uint8 atti
    ) external view returns (bool);

    function getCaseOfAttitude(uint256 motionId, uint8 atti)
        external
        view
        returns (BallotsBox.Case memory);

    function getBallot(uint256 motionId, uint256 acct)
        external
        view
        returns (BallotsBox.Ballot memory);

    function isPassed(uint256 motionId) external view returns (bool);

    function isExecuted(uint256 motionId) external view returns (bool);
}

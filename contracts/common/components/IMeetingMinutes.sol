// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/MotionsRepo.sol";
import "../lib/RulesParser.sol";

interface IMeetingMinutes {

    //##################
    //##    events    ##
    //##################

    event CreateMotion(uint256 indexed snOfMotion, uint256 indexed contents);

    event ProposeMotion(uint256 indexed seqOfMotion, uint256 indexed proposer);

    event EntrustDelegate(uint256 indexed seqOfMotion, uint256 delegate, uint256 principal, uint64 weight);

    event CastVote(uint256 indexed seqOfMotion, uint256 indexed caller, uint8 indexed attitude, bytes32 sigHash);    

    event VoteCounting(uint256 indexed seqOfMotion, uint8 indexed result);            

    event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);

    event ExecAction(uint256 indexed contents, bool result);

    //#################
    //##    写接口    ##
    //#################

    function createMotion(
        MotionsRepo.Head memory head,
        uint256 contents
    ) external returns (uint64);

    function nominateOfficer(
        uint256 seqOfPos,
        uint16 seqOfVR,
        uint40 canidate,
        uint40 nominator
    ) external returns(uint64);

    function proposeToRemoveOfficer(
        uint256 seqOfPos,
        uint16 seqOfVR,
        uint40 nominator    
    ) external returns(uint64);

    function proposeDoc(
        address doc,
        uint16 seqOfVR,
        uint40 executor,
        uint40 proposer    
    ) external returns(uint64);

    function proposeAction(
        uint16 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor,
        uint40 proposer
    ) external returns(uint64);

    function proposeMotion(
        uint256 seqOfMotion,
        uint40 proposer
    ) external;

    function entrustDelegate(
        uint256 seqOfMotion,
        uint40 delegate, 
        uint40 principal,
        uint64 weight
    ) external;

    // ==== Vote ====

    function castVote(
        uint256 seqOfMotion,
        uint8 attitude,
        bytes32 sigHash,
        IRegisterOfMembers _rom,
        uint256 caller
    ) external;

    // ==== UpdateVoteResult ====

    function voteCounting(uint256 seqOfMotion, MotionsRepo.VoteCalBase memory base) external;

    // ==== ExecResolution ====

    function execResolution(uint256 seqOfMotion, uint256 contents, uint40 caller)
        external;

    function execAction(
        uint16 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint40 caller
    ) external;

    //################
    //##    Read    ##
    //################


    // ==== Motions ====

    function isProposed(uint256 seqOfMotion) external view returns (bool);

    function voteStarted(uint256 seqOfMotion) external view returns (bool);

    function voteEnded(uint256 seqOfMotion) external view returns (bool);

    // ==== Delegate ====

    function getVoterOfDelegateMap(uint256 seqOfMotion, uint256 acct)
        external view returns (DelegateMap.Voter memory);

    function getDelegateOf(uint256 seqOfMotion, uint40 acct)
        external view returns (uint40);

    function getLeavesWeightAtDate(
        uint256 seqOfMotion, 
        uint40 caller,
        uint48 baseDate, 
        IRegisterOfMembers _rom 
    ) external view returns(uint64 weight);

    // ==== motion ====

    function getMotion(uint256 seqOfMotion)
        external view returns (MotionsRepo.Motion memory motion);

    // ==== voting ====

    function isVoted(uint256 seqOfMotion, uint256 acct) external view returns (bool);

    function isVotedFor(
        uint256 seqOfMotion,
        uint256 acct,
        uint8 atti
    ) external view returns (bool);

    function getCaseOfAttitude(uint256 seqOfMotion, uint8 atti)
        external view returns (BallotsBox.Case memory );

    function getBallot(uint256 seqOfMotion, uint256 acct)
        external view returns (BallotsBox.Ballot memory);

    function isPassed(uint256 seqOfMotion) external view returns (bool);

}

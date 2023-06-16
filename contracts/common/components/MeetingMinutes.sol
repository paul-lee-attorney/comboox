// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../access/AccessControl.sol";

import "./IMeetingMinutes.sol";

contract MeetingMinutes is IMeetingMinutes, AccessControl {
    using MotionsRepo for MotionsRepo.Repo;
    using RulesParser for bytes32;

    MotionsRepo.Repo private _repo;

    //##################
    //##    Write     ##
    //##################

    function addMotion(
        MotionsRepo.Head memory head,
        uint256 contents
    ) public onlyDirectKeeper returns (uint64) {
        head = _repo.addMotion(head, contents);
        emit CreateMotion(MotionsRepo.codifyHead(head), contents);
        return head.seqOfMotion;
    }

    function nominateOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint candidate,
        uint nominator    
    ) external onlyDirectKeeper returns(uint64) {
        MotionsRepo.Head memory head;

        head.typeOfMotion = uint8(MotionsRepo.TypeOfMotion.ElectOfficer);
        head.seqOfVR = uint16(seqOfVR);
        head.creator = uint40(nominator);
        head.executor = uint40(candidate);

        return addMotion(head, seqOfPos);
    }

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint nominator    
    ) external onlyDirectKeeper returns(uint64) {
        MotionsRepo.Head memory head;

        head.typeOfMotion = uint8(MotionsRepo.TypeOfMotion.RemoveOfficer);
        head.seqOfVR = uint16(seqOfVR);
        head.creator = uint40(nominator);
        head.executor = uint40(nominator);

        return addMotion(head, seqOfPos);
    }

    function createMotionToApproveDoc(
        address doc,
        uint seqOfVR,
        uint executor,
        uint proposer    
    ) external onlyDirectKeeper returns(uint64) {
        MotionsRepo.Head memory head;

        head.typeOfMotion = uint8(MotionsRepo.TypeOfMotion.ApproveDoc);
        head.seqOfVR = uint16(seqOfVR);
        head.creator = uint40(proposer);
        head.executor = uint40(executor);

        return addMotion(head, uint256(uint160(doc)));
    }

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external onlyDirectKeeper returns (uint64){
        MotionsRepo.Head memory head;

        head.typeOfMotion = uint8(MotionsRepo.TypeOfMotion.ApproveAction);
        head.seqOfVR = uint16(seqOfVR);
        head.creator = uint40(proposer);
        head.executor = uint40(executor);

        uint256 contents = _hashAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash
        );

        return addMotion(head, contents);
    }

    function _hashAction(
        uint256 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(seqOfVR, targets, values, params, desHash)
                )
            );
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        uint proposer
    ) public onlyDirectKeeper {
        _repo.proposeMotionToGeneralMeeting(seqOfMotion, _gk.getSHA(), _gk.getROM(), _gk.getBOD(), proposer);
        emit ProposeMotionToGeneralMeeting(seqOfMotion, proposer);
    }

    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external onlyDirectKeeper {
        _repo.proposeMotionToBoard(seqOfMotion, _gk.getSHA(), _gk.getBOD(), caller);
        emit ProposeMotionToBoard(seqOfMotion, caller);
    }

    // ==== delegate ====

    function entrustDelegate(
        uint256 seqOfMotion,
        uint delegate, 
        uint principal
    ) external onlyDirectKeeper {
        _repo.entrustDelegate(seqOfMotion, delegate, principal, _gk.getROM(), _gk.getBOD());
        emit EntrustDelegate(seqOfMotion, delegate, principal);
    }

    // ==== Vote ====

    function castVoteInGeneralMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper {
        _repo.castVoteInGeneralMeeting(seqOfMotion, caller, attitude, sigHash, _gk.getROM());
        emit CastVoteInGeneralMeeting(seqOfMotion, caller, attitude, sigHash);
    }

    function castVoteInBoardMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper {
        _repo.castVoteInBoardMeeting(seqOfMotion, caller, attitude, sigHash, _gk.getBOD());
        emit CastVoteInBoardMeeting(seqOfMotion, caller, attitude, sigHash);
    }

    // ==== UpdateVoteResult ====

    function voteCounting(uint256 seqOfMotion, MotionsRepo.VoteCalBase memory base) 
        external onlyDirectKeeper returns(uint8 result)
    {
        result = _repo.voteCounting(seqOfMotion, base);
        emit VoteCounting(seqOfMotion, result);            
    }

    // ==== ExecResolution ====

    function execResolution(uint256 seqOfMotion, uint256 contents, uint caller)
        public onlyKeeper 
    {
        _repo.execResolution(seqOfMotion, contents, caller);
        emit ExecResolution(seqOfMotion, caller);
    }

    function execAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external onlyDirectKeeper returns (uint contents) {

        MotionsRepo.Motion memory motion =  
            _repo.getMotion(seqOfMotion);

        require(motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveAction), 
            "MM.EA: wrong typeOfMotion");

        contents = _hashAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash
        );

        execResolution(seqOfMotion, contents, caller);

        // if (_execute(targets, values, params)) {
        //     emit ExecAction(contents, true);
        // } else emit ExecAction(contents, false);
    }

    // function _execute(
    //     address[] memory targets,
    //     uint256[] memory values,
    //     bytes[] memory params
    // ) private returns (bool success) {
    //     for (uint256 i = 0; i < targets.length; i++) {
    //         (success, ) = targets[i].call{value: values[i]}(params[i]);
    //         if (!success) return success;
    //     }
    // }

    //################
    //##    Read    ##
    //################

    // ==== Motions ====

    function isProposed(uint256 seqOfMotion) public view returns (bool) {
        return _repo.isProposed(seqOfMotion);
    }

    function voteStarted(uint256 seqOfMotion) external view returns (bool) {
        return _repo.voteStarted(seqOfMotion);
    }

    function voteEnded(uint256 seqOfMotion) external view returns (bool){
        return _repo.voteEnded(seqOfMotion);
    }

    // ==== Delegate ====

    function getVoterOfDelegateMap(uint256 seqOfMotion, uint256 acct)
        external view returns (DelegateMap.Voter memory)
    {
        return _repo.getVoterOfDelegateMap(seqOfMotion, acct);
    }

    function getDelegateOf(uint256 seqOfMotion, uint acct)
        external view returns (uint)
    {
        return _repo.getDelegateOf(seqOfMotion, acct);
    }

    function getLeavesWeightAtDate(
        uint256 seqOfMotion, 
        uint caller,
        uint baseDate, 
        IRegisterOfMembers _rom 
    ) external view returns(DelegateMap.LeavesInfo memory info)
    {
        info = _repo.getLeavesWeightAtDate(seqOfMotion, caller, baseDate, _rom);
    }

    function getLeavesHeadcountOfDirectors(
        uint256 seqOfMotion, 
        uint caller,
        IBookOfDirectors _bod 
    ) external view returns(uint32 head)
    {
        head = _repo.getLeavesHeadcountOfDirectors(seqOfMotion, caller, _bod);
    }

    // ==== motion ====

    function getMotion(uint256 seqOfMotion)
        external view returns (MotionsRepo.Motion memory motion)
    {
        motion = _repo.getMotion(seqOfMotion);
    }

    // ==== voting ====

    function isVoted(uint256 seqOfMotion, uint256 acct) external view returns (bool) 
    {
        return _repo.isVoted(seqOfMotion, acct);
    }

    function isVotedFor(
        uint256 seqOfMotion,
        uint256 acct,
        uint atti
    ) external view returns (bool) {
        return _repo.isVotedFor(seqOfMotion, acct, atti);
    }

    function getCaseOfAttitude(uint256 seqOfMotion, uint atti)
        external view returns (BallotsBox.Case memory )
    {
        return _repo.getCaseOfAttitude(seqOfMotion, atti);
    }

    function getBallot(uint256 seqOfMotion, uint256 acct)
        external view returns (BallotsBox.Ballot memory)
    {
        return _repo.getBallot(seqOfMotion, acct);
    }

    function isPassed(uint256 seqOfMotion) external view returns (bool) {
        return _repo.isPassed(seqOfMotion);
    }

    // ==== SnList ====

    function getSeqList() external view returns (uint[] memory) {
        return _repo.getSeqList();
    }
    
}

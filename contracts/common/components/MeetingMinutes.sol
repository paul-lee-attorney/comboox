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
    using RulesParser for uint256;

    MotionsRepo.Repo private _repo;

    //##################
    //##    Write     ##
    //##################

    function createMotion(
        MotionsRepo.Head memory head,
        uint256 contents
    ) public onlyDirectKeeper returns (uint64) {
        head = _repo.createMotion(head, contents);
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

        return createMotion(head, seqOfPos);
    }

    function proposeToRemoveOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint nominator    
    ) external onlyDirectKeeper returns(uint64) {
        MotionsRepo.Head memory head;

        head.typeOfMotion = uint8(MotionsRepo.TypeOfMotion.RemoveOfficer);
        head.seqOfVR = uint16(seqOfVR);
        head.creator = uint40(nominator);
        head.executor = uint40(nominator);

        return createMotion(head, seqOfPos);
    }

    function proposeDoc(
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

        return createMotion(head, uint256(uint160(doc)));
    }

    function proposeAction(
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

        return createMotion(head, contents);
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


    function proposeMotion(
        uint256 seqOfMotion,
        uint proposer
    ) public onlyDirectKeeper {
        MotionsRepo.Motion memory m = _repo.motions[seqOfMotion];
        RulesParser.VotingRule memory rule = 
            _gk.getSHA().getRule(m.head.seqOfVR).votingRuleParser();
        m.body = _repo.proposeMotion(seqOfMotion, rule, proposer);
        emit ProposeMotion(seqOfMotion, proposer);
    }



    // ==== delegate ====

    function entrustDelegate(
        uint256 seqOfMotion,
        uint delegate, 
        uint principal,
        uint weight
    ) external onlyDirectKeeper {
        _repo.entrustDelegate(seqOfMotion, delegate, principal, weight);
        emit EntrustDelegate(seqOfMotion, delegate, principal, weight);
    }

    // ==== Vote ====

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        IRegisterOfMembers _rom,
        uint256 caller
    ) external onlyDirectKeeper {
        if (_repo.castVote(seqOfMotion, caller, attitude, sigHash, _rom))
            emit CastVote(seqOfMotion, caller, attitude, sigHash);    
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
    ) external onlyDirectKeeper {

        MotionsRepo.Motion memory motion =  
            _repo.getMotion(seqOfMotion);

        require(motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveAction), 
            "MM.EA: wrong typeOfMotion");

        uint256 contents = _hashAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash
        );

        execResolution(seqOfMotion, contents, caller);

        if (_execute(targets, values, params)) {
            emit ExecAction(contents, true);
        } else emit ExecAction(contents, false);
    }

    function _execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params
    ) private returns (bool success) {
        for (uint256 i = 0; i < targets.length; i++) {
            (success, ) = targets[i].call{value: values[i]}(params[i]);
            if (!success) return success;
        }
    }

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
    ) external view returns(uint64 weight)
    {
        weight = _repo.getLeavesWeightAtDate(seqOfMotion, caller, baseDate, _rom);
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
}

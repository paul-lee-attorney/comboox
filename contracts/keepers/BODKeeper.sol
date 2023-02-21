// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/bod/BookOfDirectors.sol";
import "../books/bog/IBookOfGM.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOGSetting.sol";
import "../common/ruting/BOHSetting.sol";

import "../common/lib/MotionsRepo.sol";
import "../common/lib/SNParser.sol";

import "./IBODKeeper.sol";

contract BODKeeper is
    IBODKeeper,
    BODSetting,
    BOGSetting,
    BOHSetting,
    AccessControl
{
    using SNParser for bytes32;

    function appointOfficer(
        bytes32 bsRule,
        uint8 seqOfTitle,
        uint40 nominator,
        uint40 candidate
    ) external onlyDirectKeeper {
        require(bsRule.rightholderOfBSR() == nominator, 
            "BOGK.AO: nominator not rightholder");

        uint16 seqOfVR = bsRule.vrSeqOfNomination(seqOfTitle);
        require(seqOfVR > 10 && seqOfVR < 21, "BOGK.AO: not Board voting issue");

        uint8 title = bsRule.nominateTitle(seqOfTitle);

        _getBOD().appointOfficer(seqOfVR, title, nominator, candidate);
    }

    function takePosition(
        bytes32 bsRule, 
        uint8 seqOfTitle,
        uint256 motionId, 
        uint40 candidate 
    ) external onlyDirectKeeper {

        uint16 seqOfVR = bsRule.vrSeqOfNomination(seqOfTitle);
        bytes32 vrRule = _getSHA().getRule(seqOfVR);
        uint8 title = bsRule.nominateTitle(seqOfTitle);

        IBookOfGM _bog = _getBOG();

        MotionsRepo.Head memory head = (vrRule.authorityOfVR() % 2 == 1) ? 
            _bog.getHeadOfMotion(motionId) : _getBOD().getHeadOfMotion(motionId);

        require(motionId == uint256(
            keccak256(
                abi.encode(seqOfVR, title, head.proposer, candidate, head.proposeDate)
            )
        ), "BODK.TP: incorrect motionId");

        require(head.state == uint8(MotionsRepo.StateOfMotion.Passed), 
            "BODK.TP: candidate not be approved or already in position");

        require(
            head.executor == candidate,
            "BODK.TP: caller is not the candidate"
        );

        if (vrRule.authorityOfVR() % 2 == 1) _bog.motionExecuted(motionId);
        else _getBOD().motionExecuted(motionId);
        
        _getBOD().takePosition(bsRule, title, candidate, head.proposer);
    }

    function removeDirector(uint40 director, uint40 appointer) external onlyDirectKeeper {
        require(
            _getBOD().isDirector(director),
            "BODKeeper.removeDirector: appointer is not a member"
        );
        require(
            _getBOD().getDirector(director).appointer == appointer,
            "BODKeeper.reoveDirector: caller is not appointer"
        );

        _getBOD().removeDirector(director);
    }

    function quitPosition(uint40 director) external onlyDirectKeeper {
        require(
            _getBOD().isDirector(director),
            "BODKeeper.quitPosition: appointer is not a member"
        );

        _getBOD().removeDirector(director);
    }

    // ==== resolution ====

    function entrustDelegate(
        uint40 caller,
        uint40 delegate,
        uint256 motionId
    ) external onlyDirectKeeper directorExist(caller) directorExist(delegate) {
        _getBOD().entrustDelegate(motionId, caller, delegate);
    }

    function proposeAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter,
        uint40 executor
    ) external onlyDirectKeeper directorExist(submitter) {
        _getBOD().proposeAction(
            actionType,
            targets,
            values,
            params,
            desHash,
            submitter,
            executor
        );
    }

    function castVote(
        uint256 actionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper directorExist(caller) {
        _getBOD().castVote(actionId, caller, attitude, sigHash);
    }

    function voteCounting(uint256 motionId, uint40 caller)
        external
        onlyDirectKeeper
        directorExist(caller)
    {
        _getBOD().voteCounting(motionId);
    }

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 caller
    ) external directorExist(caller) returns (uint256) {
        require(!_rc.isCOA(caller), "caller is not an EOA");
        return
            _getBOD().execAction(
                actionType,
                targets,
                values,
                params,
                caller,
                desHash
            );
    }
}

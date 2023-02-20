// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/bod/BookOfDirectors.sol";

import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOHSetting.sol";

import "../common/lib/MotionsRepo.sol";
import "../common/lib/SNParser.sol";

import "./IBODKeeper.sol";

contract BODKeeper is
    IBODKeeper,
    BODSetting,
    BOHSetting,
    BOMSetting,
    BOSSetting
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

        _bod.appointOfficer(seqOfVR, title, nominator, candidate);
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

        MotionsRepo.Head memory head = (vrRule.authorityOfVR() == 1) ? 
            _bog.getHeadOfMotion(motionId) : _bod.getHeadOfMotion(motionId);

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

        if (vrRule.authorityOfVR() == 1) _bog.motionExecuted(motionId);
        else _bod.motionExecuted(motionId);
        
        _bod.takePosition(bsRule, title, candidate, head.proposer);
    }

    function removeDirector(uint40 director, uint40 appointer) external onlyDirectKeeper {
        require(
            _bod.isDirector(director),
            "BODKeeper.removeDirector: appointer is not a member"
        );
        require(
            _bod.getDirector(director).appointer == appointer,
            "BODKeeper.reoveDirector: caller is not appointer"
        );

        _bod.removeDirector(director);
    }

    function quitPosition(uint40 director) external onlyDirectKeeper {
        require(
            _bod.isDirector(director),
            "BODKeeper.quitPosition: appointer is not a member"
        );

        _bod.removeDirector(director);
    }

    // ==== resolution ====

    function entrustDelegate(
        uint40 caller,
        uint40 delegate,
        uint256 motionId
    ) external onlyDirectKeeper directorExist(caller) directorExist(delegate) {
        _bod.entrustDelegate(motionId, caller, delegate);
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
        _bod.proposeAction(
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
        _bod.castVote(actionId, caller, attitude, sigHash);
    }

    function voteCounting(uint256 motionId, uint40 caller)
        external
        onlyDirectKeeper
        directorExist(caller)
    {
        _bod.voteCounting(motionId);
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
            _bod.execAction(
                actionType,
                targets,
                values,
                params,
                caller,
                desHash
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOGSetting.sol";
import "../common/ruting/BOHSetting.sol";

import "./IBODKeeper.sol";

contract BODKeeper is
    IBODKeeper,
    BODSetting,
    BOGSetting,
    BOHSetting,
    AccessControl
{
    using RulesParser for uint256;

    function appointOfficer(
        uint256 seqOfBSR,
        uint256 seqOfTitle,
        uint256 nominator,
        uint256 candidate
    ) external onlyDirectKeeper {
        
        RulesParser.BoardSeatsRule memory bsr = 
            _getSHA().getRule(seqOfBSR).boardSeatsRuleParser();

        require(bsr.rightholder == nominator, 
            "BOGK.AO: nominator not rightholder");

        uint256 seqOfVR = bsr.vrSeqOfNomination[seqOfTitle];
        require(seqOfVR > 10 && seqOfVR < 21, "BOGK.AO: not Board voting issue");

        uint8 title = bsr.nominationTitle[seqOfTitle];

        _bod.appointOfficer(seqOfVR, title, nominator, candidate);
    }

    function takePosition(
        uint256 seqOfBSR, 
        uint256 seqOfTitle,
        uint256 motionId, 
        uint256 candidate 
    ) external onlyDirectKeeper {

        RulesParser.BoardSeatsRule memory bsr = 
            _getSHA().getRule(seqOfBSR).boardSeatsRuleParser();

        uint256 seqOfVR = bsr.vrSeqOfNomination[seqOfTitle];

        RulesParser.VotingRule memory vr = 
            _getSHA().getRule(seqOfVR).votingRuleParser();

        // bytes32 vrRule = _getSHA().getRule(seqOfVR);

        uint8 title = bsr.nominationTitle[seqOfTitle];

        MotionsRepo.Head memory head = (vr.authority % 2 == 1) ? 
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

        if (vr.authority % 2 == 1) _bog.motionExecuted(motionId);
        else _bod.motionExecuted(motionId);
        
        _bod.takePosition(seqOfBSR, title, candidate, head.proposer);
    }

    function removeDirector(uint256 director, uint256 appointer) external onlyDirectKeeper {

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

    function quitPosition(uint256 director) external onlyDirectKeeper {

        require(
            _bod.isDirector(director),
            "BODKeeper.quitPosition: appointer is not a member"
        );

        _bod.removeDirector(director);
    }

    // ==== resolution ====

    function entrustDelegate(
        uint256 caller,
        uint256 delegate,
        uint256 motionId
    ) external onlyDirectKeeper directorExist(caller) directorExist(delegate) {
        _bod.entrustDelegate(motionId, caller, delegate);
    }

    function proposeAction(
        uint8 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter,
        uint40 executor
    ) external onlyDirectKeeper directorExist(submitter) {
        _bod.proposeAction(
            typeOfAction,
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
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper directorExist(caller) {
        _bod.castVote(actionId, caller, attitude, sigHash);
    }

    function voteCounting(uint256 motionId, uint256 caller)
        external
        onlyDirectKeeper
        directorExist(caller)
    {
        _bod.voteCounting(motionId);
    }

    function execAction(
        uint8 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 caller
    ) external directorExist(caller) returns (uint256) {
        require(!_rc.isCOA(caller), "caller is not an EOA");
        return
            _bod.execAction(
                typeOfAction,
                targets,
                values,
                params,
                caller,
                desHash
            );
    }
}

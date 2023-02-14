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

    function appointDirector(
        uint16 seqOfRule,
        uint8 seqOfTitle,
        uint40 candidate,
        uint40 appointer
    ) external onlyDirectKeeper {
        bytes32 rule = _getSHA().getRule(seqOfRule);
        require(rule.rightholderOfBSR() == appointer, "BODKeeper.ad: caller not rightholder");

        uint8 title = rule.appointTitle(seqOfTitle);
        require(title > 0 && title < 4, "BODKeeper.ad: title overflow");

        _bod.appointDirector(rule, candidate, title, appointer);
    }

    function takePosition(bytes32 rule, uint40 candidate, uint256 motionId) external onlyDirectKeeper {
        require(
            _bom.isPassed(motionId),
            "BODKeeper.takePosition: candidate not be approved"
        );

        MotionsRepo.Head memory head = _bom.headOf(motionId);

        require(
            head.executor == candidate,
            "BODKeeper.takePosition: caller is not the candidate"
        );

        _bod.takePosition(rule, candidate, head.executor);
    }

    function removeDirector(uint40 director, uint40 appointer) external onlyDirectKeeper {
        require(
            _bod.isDirector(director),
            "BODKeeper.removeDirector: appointer is not a member"
        );
        require(
            _bod.appointerOfDirector(director) == appointer,
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
        uint256 actionId
    ) external onlyDirectKeeper directorExist(caller) directorExist(delegate) {
        _bod.entrustDelegate(caller, delegate, actionId);
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
        _bod.castVote(actionId, attitude, caller, sigHash);
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

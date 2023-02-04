// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/bod/BookOfDirectors.sol";

import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOHSetting.sol";

import "../common/lib/MotionsRepo.sol";

import "./IBODKeeper.sol";

contract BODKeeper is
    IBODKeeper,
    BODSetting,
    BOHSetting,
    BOMSetting,
    BOSSetting
{
    function appointDirector(
        uint40 candidate,
        uint8 title,
        uint40 appointer
    ) external onlyDK {
        require(
            _getSHA().boardSeatsOf(appointer) >
                _bod.appointmentCounter(appointer),
            "BODKeeper.appointDirector: board seats quota used out"
        );

        if (title == uint8(BookOfDirectors.TitleOfDirectors.Chairman)) {
            require(
                _getSHA().appointerOfOfficer(0) == appointer,
                "BODKeeper.appointDirector: has no appointment right"
            );

            require(
                _bod.whoIs(title) == 0 || _bod.whoIs(title) == candidate,
                "BODKeeper.appointDirector: current Chairman shall quit first"
            );
        } else if (
            title == uint8(BookOfDirectors.TitleOfDirectors.ViceChairman)
        ) {
            require(
                _getSHA().appointerOfOfficer(1) == appointer,
                "BODKeeper.appointDirector: has no appointment right"
            );
            require(
                _bod.whoIs(title) == 0 || _bod.whoIs(title) == candidate,
                "BODKeeper.appointDirector: current ViceChairman shall quit first"
            );
        } else if (title != uint8(BookOfDirectors.TitleOfDirectors.Director)) {
            revert(
                "BODKeeper.appointDirector: there is not such title for candidate"
            );
        }

        _bod.appointDirector(candidate, title, appointer);
    }

    function takePosition(uint40 candidate, uint256 motionId) external onlyDK {
        require(
            _bom.isPassed(motionId),
            "BODKeeper.takePosition: candidate not be approved"
        );

        MotionsRepo.Head memory head = _bom.headOf(motionId);

        require(
            head.executor == candidate,
            "BODKeeper.takePosition: caller is not the candidate"
        );

        _bod.takePosition(candidate, head.executor);
    }

    function removeDirector(uint40 director, uint40 appointer) external onlyDK {
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

    function quitPosition(uint40 director) external onlyDK {
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
    ) external onlyDK directorExist(caller) directorExist(delegate) {
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
    ) external onlyDK directorExist(submitter) {
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
    ) external onlyDK directorExist(caller) {
        _bod.castVote(actionId, attitude, caller, sigHash);
    }

    function voteCounting(uint256 motionId, uint40 caller)
        external
        onlyDK
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

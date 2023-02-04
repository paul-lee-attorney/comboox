// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/ruting/BOHSetting.sol";
import "../../common/ruting/ROMSetting.sol";

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/SNParser.sol";
import "../../common/lib/MotionsRepo.sol";
import "../../common/lib/DelegateMap.sol";
import "../../common/lib/BallotsBox.sol";

import "./IMeetingMinutes.sol";

contract MeetingMinutes is IMeetingMinutes, BOHSetting, ROMSetting {
    using SNParser for bytes32;
    using MotionsRepo for MotionsRepo.Repo;
    using DelegateMap for DelegateMap.Map;
    using BallotsBox for BallotsBox.Box;
    using EnumerableSet for EnumerableSet.UintSet;

    enum StateOfMotion {
        Pending,
        Proposed,
        Passed,
        Rejected,
        Rejected_NotToBuy,
        Rejected_ToBuy,
        Executed
    }

    MotionsRepo.Repo internal _mm;

    modifier allowedAtti(uint8 atti) {
        require(atti > 0 && atti < 4, "MM.votedFor: attitude overflow");
        _;
    }

    //##################
    //##    Write     ##
    //##################

    // ==== delegate ====

    function entrustDelegate(
        uint40 authorizer,
        uint40 delegate,
        uint256 motionId
    ) external onlyDK {
        if (_mm.entrustDelegate(authorizer, delegate, motionId))
            emit EntrustDelegate(motionId, authorizer, delegate);
    }

    // ==== propose ====

    function _hashAction(
        uint16 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(actionType, targets, values, params, desHash)
                )
            );
    }

    function proposeAction(
        uint16 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter,
        uint40 executor
    ) external onlyDK {
        uint256 actionId = _hashAction(
            actionType,
            targets,
            values,
            params,
            desHash
        );

        require(
            _proposalWeight(actionId, submitter) >=
                _getSHA().proposalThreshold(),
            "insufficient voting weight"
        );

        bytes32 rule = _getSHA().votingRules(actionType);

        if (_mm.proposeMotion(actionId, rule, executor, _rc.blocksPerHour()))
            emit ProposeAction(actionId, actionType, submitter);
    }

    function _proposalWeight(uint256 actionId, uint40 acct)
        private
        view
        returns (uint64)
    {
        uint40[] memory principals = _mm.motions[actionId].map.principalsOf[
            acct
        ];
        uint256 len = principals.length;
        uint64 weight = _rom.votesInHand(acct);

        while (len != 0) {
            weight += _rom.votesInHand(principals[len - 1]);
            len--;
        }

        return (weight * 10000) / _rom.totalVotes();
    }

    // ==== cast vote ====

    function castVote(
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK {
        if (_mm.castVote(motionId, attitude, caller, sigHash, _rom))
            emit CastVote(motionId, attitude, caller, sigHash);
    }

    // ==== counting ====

    function voteCounting(uint256 motionId) external onlyDK {
        if (
            _mm.motions[motionId].head.state ==
            uint8(MotionsRepo.StateOfMotion.Proposed) &&
            _mm.voteCounting(motionId, _rom)
        ) emit VoteCounting(motionId, _mm.motions[motionId].head.state);
    }

    // ==== execute ====

    function execAction(
        uint16 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        uint40 caller,
        bytes32 desHash
    ) external onlyDK returns (uint256) {
        uint256 motionId = _hashAction(
            actionType,
            targets,
            values,
            params,
            desHash
        );

        require(
            _mm.motions[motionId].head.state ==
                uint8(MotionsRepo.StateOfMotion.Passed),
            "BOD.execAction: voting NOT end"
        );

        require(
            _mm.motions[motionId].head.executor == caller,
            "BOD.execAction: voting NOT end"
        );

        _mm.motions[motionId].head.state = uint8(
            MotionsRepo.StateOfMotion.Executed
        );

        if (_execute(targets, values, params))
            emit ExecuteAction(motionId, true);
        else emit ExecuteAction(motionId, false);

        return motionId;
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

    //##################
    //##    Read     ##
    //################

    // ==== delegate ====

    function isPrincipal(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].map.delegateOf[acct] != 0;
    }

    function isDelegate(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].map.principalsOf[acct].length != 0;
    }

    function delegateOf(uint256 motionId, uint40 acct)
        external
        view
        returns (uint40)
    {
        return _mm.motions[motionId].map.delegateOf[acct];
    }

    function principalsOf(uint256 motionId, uint40 acct)
        external
        view
        returns (uint40[] memory)
    {
        return _mm.motions[motionId].map.principalsOf[acct];
    }

    // ==== motion ====

    function isProposed(uint256 motionId) external view returns (bool) {
        return _mm.motionIds.contains(motionId);
    }

    function headOf(uint256 motionId)
        external
        view
        returns (MotionsRepo.Head memory)
    {
        return _mm.motions[motionId].head;
    }

    function votingRule(uint256 motionId) external view returns (bytes32) {
        return _mm.motions[motionId].votingRule;
    }

    function state(uint256 motionId) external view returns (uint8) {
        return _mm.motions[motionId].head.state;
    }

    // ==== voting ====

    function votedFor(
        uint256 motionId,
        uint40 acct,
        uint8 atti
    ) external view allowedAtti(atti) returns (bool) {
        return _mm.motions[motionId].box.cases[atti].voters.contains(acct);
    }

    function getCaseOf(uint256 motionId, uint8 atti)
        external
        view
        allowedAtti(atti)
        returns (uint40[] memory voters, uint64 sumOfWeight)
    {
        voters = _mm.motions[motionId].box.cases[atti].voters.valuesToUint40();
        sumOfWeight = _mm.motions[motionId].box.cases[atti].sumOfWeight;
    }

    function qtyOfVotersFor(uint256 motionId, uint8 atti)
        external
        view
        allowedAtti(atti)
        returns (uint256)
    {
        return _mm.motions[motionId].box.cases[atti].voters.length();
    }

    function allVoters(uint256 motionId)
        external
        view
        returns (uint40[] memory)
    {
        return _mm.motions[motionId].box.cases[0].voters.valuesToUint40();
    }

    function qtyOfAllVoters(uint256 motionId) external view returns (uint256) {
        return _mm.motions[motionId].box.cases[0].voters.length();
    }

    function sumOfVoteAmt(uint256 motionId) external view returns (uint64) {
        return _mm.motions[motionId].box.cases[0].sumOfWeight;
    }

    function isVoted(uint256 motionId, uint40 acct)
        external
        view
        returns (bool)
    {
        return _mm.motions[motionId].box.cases[0].voters.contains(acct);
    }

    function getVote(uint256 motionId, uint40 acct)
        external
        view
        returns (
            uint8 attitude,
            uint64 weight,
            uint64 blocknumber,
            uint48 sigDate,
            bytes32 sigHash
        )
    {
        BallotsBox.Ballot storage b = _mm.motions[motionId].box.ballots[acct];

        attitude = b.attitude;
        weight = b.weight;
        blocknumber = b.blocknumber;
        sigDate = b.sigDate;
        sigHash = b.sigHash;
    }

    function isPassed(uint256 motionId) external view returns (bool) {
        return
            _mm.motions[motionId].head.state == uint8(StateOfMotion.Passed) ||
            _mm.motions[motionId].head.state == uint8(StateOfMotion.Executed);
    }

    function isExecuted(uint256 motionId) external view returns (bool) {
        return
            _mm.motions[motionId].head.state == uint8(StateOfMotion.Executed);
    }

    function isRejected(uint256 motionId) external view returns (bool) {
        return
            _mm.motions[motionId].head.state == uint8(StateOfMotion.Rejected) ||
            _mm.motions[motionId].head.state ==
            uint8(StateOfMotion.Rejected_NotToBuy) ||
            _mm.motions[motionId].head.state ==
            uint8(StateOfMotion.Rejected_ToBuy);
    }
}

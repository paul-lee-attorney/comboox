// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../access/AccessControl.sol";

import "../ruting/BODSetting.sol";
import "../ruting/BOHSetting.sol";
import "../ruting/ROMSetting.sol";

import "./IMeetingMinutes.sol";

contract MeetingMinutes is IMeetingMinutes, BODSetting, BOHSetting, ROMSetting, AccessControl {
    using DelegateMap for DelegateMap.Map;
    using EnumerableSet for EnumerableSet.UintSet;
    using MotionsRepo for MotionsRepo.Motion;
    using MotionsRepo for MotionsRepo.Repo;
    using RulesParser for uint256;

    MotionsRepo.Repo private _repo;

    //##################
    //##    Write     ##
    //##################

    // ==== propose ====

    function proposeMotion(
        uint256 motionId,
        uint256 seqOfVR,
        uint40 proposer,
        uint40 executor
    ) public onlyKeeper {           
        RulesParser.VotingRule memory rule = _getSHA().getRule(seqOfVR).votingRuleParser();

        if (_repo.proposeMotion(motionId, rule, proposer, executor))
            emit ProposeMotion(motionId, seqOfVR, proposer, executor);    
        else revert ("MM.PM: motion already proposed");
    }

    function nominateOfficer(uint256 seqOfVR, uint8 title, uint40 nominator, uint40 candidate)
        external
        onlyKeeper
    {
        uint256 motionId = uint256(
            keccak256(
                abi.encode(seqOfVR, title, nominator, candidate, uint48(block.timestamp))
            )
        );

        proposeMotion(motionId, seqOfVR, nominator, candidate);
    }

    function proposeDoc(
        address doc,
        uint256 seqOfVR,
        uint40 proposer,
        uint40 executor
    ) external onlyDirectKeeper {
        uint256 motionId = (seqOfVR << 160) + uint256(uint160(doc));
        proposeMotion(motionId, seqOfVR, proposer, executor);
    }

    function proposeAction(
        uint256 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 proposer,
        uint40 executor
    ) external onlyDirectKeeper {
        uint256 motionId = _hashAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash
        );

        proposeMotion(motionId, seqOfVR, proposer, executor);
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

    // ==== delegate ====

    function entrustDelegate(
        uint256 motionId,
        uint256 principal,
        uint256 delegate
    ) external onlyDirectKeeper {

        MotionsRepo.Motion storage m = _repo.motions[motionId];

        require(m.head.proposer > 0, "MM.ED: motion not proposed");
        require(m.head.shareRegDate <= block.timestamp, "MM.ED: not reach shareRegDate");

        uint64 weight = _getWeight(m, principal);

        emit EntrustDelegate(motionId, principal, delegate, weight);
        m.map.entrustDelegate(principal, delegate, weight);
    }

    function _getWeight(MotionsRepo.Motion storage m, uint256 acct) private view returns(uint64 weight) {
        if (m.votingRule.authority % 2 == 1)
            weight = _rom.votesAtDate(acct, m.head.shareRegDate);
    }

    // ==== cast vote ====

    function castVote(
        uint256 motionId,
        uint256 caller,
        uint8 attitude,
        bytes32 sigHash
    ) external onlyDirectKeeper {
        MotionsRepo.Motion storage m = _repo.motions[motionId];

        uint64 weight = _getWeight(m, caller);

        if (m.castVote(caller, attitude, weight, sigHash))
            emit CastVote(motionId, caller, attitude, sigHash);    
    }

    // ==== counting ====

    function voteCounting(uint256 motionId) external onlyDirectKeeper returns(bool flag) {

        MotionsRepo.Motion storage m = _repo.motions[motionId];

        if (_isDocApproval(motionId)) {
            flag = m.getDocApproval(motionId, _rom, _bod);
        } else {
            flag = m.getVoteResult(_rom, _bod);
        }
        
        m.head.state = flag ? 
            uint8(MotionsRepo.StateOfMotion.Passed) : 
            m.votingRule.againstShallBuy ?
                uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy) :
                uint8(MotionsRepo.StateOfMotion.Rejected_NotToBuy);

        emit VoteCounting(motionId, m.head.state);            
    }

    function _isDocApproval(uint256 motionId) private pure returns(bool flag) {
        uint16 seqOfVR = uint16 (motionId >> 160);
        flag == (motionId > 0 ) && (seqOfVR > 0) 
            && (seqOfVR <= 16) && ((motionId >> 176) == 0); 
    }

    function _getDocRepo(uint256 motionId) private view returns(IFilesFolder _rod) {
        uint16 seqOfVR = uint16(motionId >> 160);
        if (seqOfVR == 8 || seqOfVR == 16) _rod = IFilesFolder(_gk.getBook(uint8(TitleOfBooks.BookOfSHA)));
        else _rod = IFilesFolder(_gk.getBook(uint8(TitleOfBooks.BookOfIA)));
    }

    // ==== execute ====

    function motionExecuted(uint256 motionId) external onlyKeeper {
        _repo.motions[motionId].head.state = uint8(MotionsRepo.StateOfMotion.Executed);
    }

    function execAction(
        uint256 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        uint256 caller,
        bytes32 desHash
    ) external onlyDirectKeeper returns (uint256) {
        uint256 motionId = _hashAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash
        );

        MotionsRepo.Motion storage m = _repo.motions[motionId];

        require(
            m.head.state == uint8(MotionsRepo.StateOfMotion.Passed),
            "MM.EA: voting NOT passed"
        );

        require(
            m.head.executor == caller,
            "MM.EA: caller not executor"
        );

        if (_execute(targets, values, params)) {
            emit ExecuteAction(motionId, true);
            m.head.state = uint8(MotionsRepo.StateOfMotion.Executed);
        } else emit ExecuteAction(motionId, false);

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

    function getVoterOfDelegateMap(uint256 motionId, uint256 acct)
        external
        view
        returns (DelegateMap.Voter memory)
    {
        return _repo.motions[motionId].map.voters[acct];
    }

    function getDelegateOf(uint256 motionId, uint256 acct)
        external
        view
        returns (uint40)
    {
        return _repo.motions[motionId].map.getDelegateOf(uint40(acct));
    }

    // ==== motion ====

    function isProposed(uint256 motionId) external view returns (bool) {
        return _repo.motionIds.contains(motionId);
    }

    function getHeadOfMotion(uint256 motionId)
        external
        view
        returns (MotionsRepo.Head memory head)
    {
        head = _repo.motions[motionId].head;
    }

    function getVotingRuleOfMotion(uint256 motionId) external view returns (RulesParser.VotingRule memory m) {
        return _repo.motions[motionId].votingRule;
    }

    // ==== voting ====

    function isVoted(uint256 motionId, uint256 acct) 
        public 
        view 
        returns (bool) 
    {
        return _repo.motions[motionId].box.ballots[acct].sigDate > 0;
    }

    function isVotedFor(
        uint256 motionId,
        uint256 acct,
        uint8 atti
    ) external view returns (bool) {
        return _repo.motions[motionId].box.ballots[acct].attitude == atti;
    }

    function getCaseOfAttitude(uint256 motionId, uint8 atti)
        external
        view
        returns (BallotsBox.Case memory )
    {
        return _repo.motions[motionId].box.cases[atti];
    }

    function getBallot(uint256 motionId, uint256 acct)
        external
        view
        returns (BallotsBox.Ballot memory)
    {
        return _repo.motions[motionId].box.ballots[acct];
    }

    function isPassed(uint256 motionId) external view returns (bool) {
        return
            _repo.motions[motionId].head.state == uint8(MotionsRepo.StateOfMotion.Passed);
    }

    function isExecuted(uint256 motionId) external view returns (bool) {
        return
            _repo.motions[motionId].head.state == uint8(MotionsRepo.StateOfMotion.Executed);
    }
}

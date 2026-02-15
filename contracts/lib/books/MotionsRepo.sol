// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
 *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "./BallotsBox.sol";
import "./DelegateMap.sol";
import "../../openzeppelin/utils/structs/EnumerableSet.sol";
import "./RulesParser.sol";

import "../../comps/books/roc/IShareholdersAgreement.sol";

/// @title MotionsRepo
/// @notice Repository for motions, voting, and delegate maps.
library MotionsRepo {
    using BallotsBox for BallotsBox.Box;
    using DelegateMap for DelegateMap.Map;
    using EnumerableSet for EnumerableSet.UintSet;
    using RulesParser for bytes32;

    /// @notice Motion types.
    enum TypeOfMotion {
        ZeroPoint,
        ElectOfficer,
        RemoveOfficer,
        ApproveDoc,
        ApproveAction,
        TransferFund,
        DistributeProfits,
        DecreaseCapital
    }

    /// @notice Motion lifecycle states.
    enum StateOfMotion {
        ZeroPoint,          // 0
        Created,            // 1
        Proposed,           // 2
        Passed,             // 3
        Rejected,           // 4
        Rejected_NotToBuy,  // 5
        Rejected_ToBuy,     // 6
        Executed            // 7
    }

    /// @notice Motion head fields.
    struct Head {
        uint16 typeOfMotion;
        uint64 seqOfMotion;
        uint16 seqOfVR;
        uint40 creator;
        uint40 executor;
        uint48 createDate;        
        uint32 data;
    }

    /// @notice Motion body fields.
    struct Body {
        uint40 proposer;
        uint48 proposeDate;
        uint48 shareRegDate;
        uint48 voteStartDate;
        uint48 voteEndDate;
        uint16 para;
        uint8 state;
    }

    /// @notice Full motion record.
    struct Motion {
        Head head;
        Body body;
        RulesParser.VotingRule votingRule;
        uint contents;
    }

    /// @notice Vote record: delegates and ballots.
    struct Record {
        DelegateMap.Map map;
        BallotsBox.Box box;
    }

    /// @notice Vote calculation base inputs.
    struct VoteCalBase {
        uint32 totalHead;
        uint64 totalWeight;
        uint32 supportHead;
        uint64 supportWeight;
        uint16 attendHeadRatio;
        uint16 attendWeightRatio;
        uint16 para;
        uint8 state;            
        bool unaniConsent;
    }

    /// @notice Repository of motions and vote records.
    struct Repo {
        mapping(uint256 => Motion) motions;
        mapping(uint256 => Record) records;
        EnumerableSet.UintSet seqList;
    }

    //#############
    //##  Error  ##
    //#############

    error MR_WrongInput(bytes32 reason);

    error MR_WrongState(bytes32 reason);

    error MR_WrongParty(bytes32 reason);



    //#################
    //##  Write I/O  ##
    //#################

    // ==== snParser ====

    /// @notice Parse motion head from bytes32.
    /// @param sn Packed motion head.
    function snParser (bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            typeOfMotion: uint16(_sn >> 240),
            seqOfMotion: uint64(_sn >> 176),
            seqOfVR: uint16(_sn >> 160),
            creator: uint40(_sn >> 120),
            executor: uint40(_sn >> 80),
            createDate: uint48(_sn >> 32),
            data: uint32(_sn)
        });
    }

    /// @notice Pack motion head into bytes32.
    /// @param head Motion head.
    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfMotion,
                            head.seqOfMotion,
                            head.seqOfVR,
                            head.creator,
                            head.executor,
                            head.createDate,
                            head.data);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    } 
    
    // ==== addMotion ====

    /// @notice Create or update a motion.
    /// @param repo Storage repo.
    /// @param head Motion head.
    /// @param contents Motion contents.
    function addMotion(
        Repo storage repo,
        Head memory head,
        uint256 contents
    ) public returns (Head memory) {

        if (head.typeOfMotion == 0) {
            revert MR_WrongInput(bytes32("MR_ZeroTypeOfMotion"));
        }
        if (head.seqOfVR == 0) {
            revert MR_WrongInput(bytes32("MR_ZeroSeqOfVR"));
        }
        if (head.creator == 0) {
            revert MR_WrongInput(bytes32("MR_ZeroCaller"));
        }

        if (!repo.seqList.contains(head.seqOfMotion)) {
            head.seqOfMotion = _increaseCounterOfMotion(repo);
            head.createDate = uint48(block.timestamp);
            repo.seqList.add(head.seqOfMotion);
        }
    
        Motion storage m = repo.motions[head.seqOfMotion];

        m.head = head;
        m.contents = contents;
        m.body.state = uint8(StateOfMotion.Created);

        return head;
    } 

    function _increaseCounterOfMotion (Repo storage repo) private returns (uint64 seq) {
        repo.motions[0].head.seqOfMotion++;
        seq = repo.motions[0].head.seqOfMotion;
    }

    // ==== entrustDelegate ====

    /// @notice Entrust delegate for a motion.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param delegate Delegate user number.
    /// @param principal Principal user number.
    /// @param _rom Register of members.
    /// @param _rod Register of directors.
    function entrustDelegate(
        Repo storage repo,
        uint256 seqOfMotion,
        uint delegate,
        uint principal,
        IRegisterOfMembers _rom,
        IRegisterOfDirectors _rod
    ) public returns (bool flag) {
        Motion storage m = repo.motions[seqOfMotion];

        if (m.body.state != uint8(StateOfMotion.Created) &&
            m.body.state != uint8(StateOfMotion.Proposed)) {
            revert MR_WrongState(bytes32("MR_MotionNotInVoting"));
        }

        if (m.head.seqOfVR < 11 && _rom.isMember(delegate) && _rom.isMember(principal)) {
            uint64 weight;
            if (m.body.shareRegDate > 0 && block.timestamp >= m.body.shareRegDate) 
                weight = _rom.votesAtDate(principal, m.body.shareRegDate);    
            return repo.records[seqOfMotion].map.entrustDelegate(principal, delegate, weight);
        } else if (_rod.isDirector(delegate) && _rod.isDirector(principal)) {
            return repo.records[seqOfMotion].map.entrustDelegate(principal, delegate, 0);
        } else revert MR_WrongParty(bytes32("MR_NotBothMembersOrDirectors"));        
    }

    // ==== propose ====

    /// @notice Propose motion to general meeting.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param _sha Shareholders agreement.
    /// @param _rom Register of members.
    /// @param _rod Register of directors.
    /// @param caller Proposer user number.
    function proposeMotionToGeneralMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        IShareholdersAgreement _sha,
        IRegisterOfMembers _rom,
        IRegisterOfDirectors _rod,
        uint caller
    ) public {

        RulesParser.GovernanceRule memory gr =
            _sha.getRule(0).governanceRuleParser();

        if ( !_memberProposalRightCheck(repo, seqOfMotion, gr, caller, _rom) &&
             !_directorProposalRightCheck(repo, seqOfMotion, caller, gr.proposeHeadRatioOfDirectorsInGM, _rod)
        ) {
            revert MR_WrongParty(bytes32("MR_NoProposalRight"));
        }

        _proposeMotion(repo, seqOfMotion, _sha, caller, _rom.qtyOfMembers() == 1);
    } 

    function _proposeMotion(
        Repo storage repo,
        uint seqOfMotion,
        IShareholdersAgreement _sha,
        uint caller,
        bool soleMember
    ) private {

        if (caller == 0) {
            revert MR_WrongInput(bytes32("MR_ZeroCaller"));
        }

        if (repo.records[seqOfMotion].map.voters[caller].delegate != 0) {
            revert MR_WrongParty(bytes32("MR_EntrustedDelegate"));
        }

        Motion storage m = repo.motions[seqOfMotion];
        if (m.body.state != uint8(StateOfMotion.Created)) {
            revert MR_WrongState(bytes32("MR_MotionNotInCreatedState"));
        }

        RulesParser.VotingRule memory vr = 
            _sha.getRule(m.head.seqOfVR).votingRuleParser();

        uint48 timestamp = uint48(block.timestamp);

        Body memory body = Body({
            proposer: uint40(caller),
            proposeDate: timestamp,
            shareRegDate: soleMember ? timestamp : timestamp + uint48(vr.invExitDays) * 86400,
            voteStartDate: soleMember ? timestamp : timestamp + uint48(vr.invExitDays + vr.votePrepareDays) * 86400,
            voteEndDate: soleMember ? timestamp + 86400 : timestamp + uint48(vr.invExitDays + vr.votePrepareDays + vr.votingDays) * 86400,
            para: 0,
            state: uint8(StateOfMotion.Proposed)
        });

        m.body = body;
        m.votingRule = vr;
    }

    function _memberProposalRightCheck(
        Repo storage repo,
        uint seqOfMotion,
        RulesParser.GovernanceRule memory gr,
        uint caller,
        IRegisterOfMembers _rom
    ) private returns(bool) {
        if (!_rom.isMember(caller)) return false;

        Motion memory motion = repo.motions[seqOfMotion];
        if (motion.head.typeOfMotion == uint8(TypeOfMotion.ApproveDoc) ||
            motion.head.typeOfMotion == uint8(TypeOfMotion.ElectOfficer))
            return true;

        uint totalVotes = _rom.totalVotes();

        if (gr.proposeWeightRatioOfGM > 0 &&
            _rom.votesInHand(caller) * 10000 / totalVotes >= gr.proposeWeightRatioOfGM)
                return true;

        Record storage r = repo.records[seqOfMotion];
        r.map.updateLeavesWeightAtDate(caller, uint48(block.timestamp), _rom);

        DelegateMap.Voter memory voter = r.map.voters[caller];


        if (gr.proposeWeightRatioOfGM > 0 && 
            (voter.weight + voter.repWeight) * 10000 / totalVotes >= gr.proposeWeightRatioOfGM)
                return true;

        if (gr.proposeHeadRatioOfMembers > 0 &&
            (voter.repHead + 1) * 10000 / _rom.qtyOfMembers() >= 
                gr.proposeHeadRatioOfMembers)
                    return true;
        
        return false;
    }

    function _directorProposalRightCheck(
        Repo storage repo,
        uint seqOfMotion,
        uint caller,
        uint16 proposalThreshold,
        IRegisterOfDirectors _rod
    ) private returns (bool) {
        if (!_rod.isDirector(caller)) return false;

        uint totalHead = _rod.getNumOfDirectors();
        repo.records[seqOfMotion].map.updateLeavesHeadcountOfDirectors(caller, _rod);

        if (proposalThreshold > 0 &&
            (repo.records[seqOfMotion].map.voters[caller].repHead + 1) * 10000 / totalHead >=
                proposalThreshold)
                    return true;

        return false;
    } 

    /// @notice Propose motion to board meeting.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param _sha Shareholders agreement.
    /// @param _rod Register of directors.
    /// @param caller Proposer user number.
    function proposeMotionToBoard(
        Repo storage repo,
        uint256 seqOfMotion,
        IShareholdersAgreement _sha,
        IRegisterOfDirectors _rod,
        uint caller
    ) public {

        RulesParser.GovernanceRule memory gr = 
            _sha.getRule(0).governanceRuleParser();

        if (
            !_directorProposalRightCheck(
                repo, seqOfMotion, caller, 
                gr.proposeHeadRatioOfDirectorsInBoard, 
                _rod
            )
        ) {
            revert MR_WrongParty(bytes32("MR_NoProposalRight"));
        }

        _proposeMotion(repo, seqOfMotion, _sha, caller, _rod.getNumOfDirectors() == 1);
    } 

    // ==== vote ====

    /// @notice Cast vote in general meeting.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param acct Voter user number.
    /// @param attitude Vote attitude.
    /// @param sigHash Signature hash.
    /// @param _rom Register of members.
    function castVoteInGeneralMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        bytes32 sigHash,
        IRegisterOfMembers _rom
    ) public {

        if (!_rom.isMember(acct)) {
            revert MR_WrongParty(bytes32("MR_NotMember"));
        }

        Motion storage m = repo.motions[seqOfMotion];
        Record storage r = repo.records[seqOfMotion];
        DelegateMap.Voter storage voter = r.map.voters[acct];

        r.map.updateLeavesWeightAtDate(acct, m.body.shareRegDate, _rom);

        _castVote(repo, seqOfMotion, acct, attitude, voter.repHead + 1, voter.weight + voter.repWeight, sigHash);
    }

    /// @notice Cast vote in board meeting.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param acct Voter user number.
    /// @param attitude Vote attitude.
    /// @param sigHash Signature hash.
    /// @param _rod Register of directors.
    function castVoteInBoardMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        bytes32 sigHash,
        IRegisterOfDirectors _rod
    ) public {
        if (!_rod.isDirector(acct)) {
            revert MR_WrongParty(bytes32("MR_NotDirector"));
        }

        Record storage r = repo.records[seqOfMotion];

        DelegateMap.Voter storage voter = r.map.voters[acct];

        r.map.updateLeavesHeadcountOfDirectors(acct, _rod);

        _castVote(repo, seqOfMotion, acct, attitude, voter.repHead + 1, 0, sigHash);
    }

    function _castVote(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        uint headcount,
        uint weight,
        bytes32 sigHash
    ) private {
        if (seqOfMotion == 0) {
            revert MR_WrongInput(bytes32("MR_ZeroSeqOfMotion"));
        }
        if (!voteStarted(repo, seqOfMotion)) {
            revert MR_WrongState(bytes32("MR_VoteNotStarted"));
        }
        if (voteEnded(repo, seqOfMotion)) {
            revert MR_WrongState(bytes32("MR_VoteEnded"));
        }

        Record storage r = repo.records[seqOfMotion];
        DelegateMap.Voter storage voter = r.map.voters[acct];

        if (voter.delegate != 0) {
            revert MR_WrongParty(bytes32("MR_EntrustedDelegate"));
        }

        r.box.castVote(acct, attitude, headcount, weight, sigHash, voter.principals);
    }


    // ==== counting ====

    /// @notice Count votes and update motion state.
    /// @param repo Storage repo.
    /// @param flag0 Pass base condition.
    /// @param seqOfMotion Motion sequence.
    /// @param base Vote calculation base.
    function voteCounting(
        Repo storage repo,
        bool flag0,
        uint256 seqOfMotion,
        VoteCalBase memory base
    ) public returns (uint8) {

        Motion storage m = repo.motions[seqOfMotion];
        Record storage r = repo.records[seqOfMotion];

        if (m.body.state != uint8(StateOfMotion.Proposed)) {
            revert MR_WrongState(bytes32("MR_MotionNotInVoting"));  
        }

        if (base.unaniConsent) {
            m.body.state = uint8(MotionsRepo.StateOfMotion.Passed);
        } else {
            if (!voteEnded(repo, seqOfMotion)) {
                revert MR_WrongState(bytes32("MR_VoteNotEnded"));
            }

            bool flag1 = m.votingRule.headRatio == 0;
            bool flag2 = m.votingRule.amountRatio == 0;

            bool flag = (flag1 && flag2);

            if (!flag && flag0 && !_isVetoed(r, m.votingRule.vetoers[0]) &&
                !_isVetoed(r, m.votingRule.vetoers[1])) {
                flag1 = flag1 ? true : base.totalHead > 0
                    ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                        .sumOfHead + base.supportHead) * 10000) /
                        base.totalHead >
                        m.votingRule.headRatio
                    : false;

                flag2 = flag2 ? true : base.totalWeight > 0
                    ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                        .sumOfWeight + base.supportWeight) * 10000) /
                        base.totalWeight >
                        m.votingRule.amountRatio
                    : false;
            }

            m.body.state =  flag || (flag0 && flag1 && flag2) 
                    ? uint8(MotionsRepo.StateOfMotion.Passed) 
                    : m.votingRule.againstShallBuy 
                        ? uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy)
                        : uint8(MotionsRepo.StateOfMotion.Rejected_NotToBuy);
        }

        return m.body.state;
    }

    function _isVetoed(Record storage r, uint256 vetoer)
        private
        view
        returns (bool)
    {
        return vetoer > 0 && (r.box.ballots[vetoer].sigDate == 0 ||
            r.box.ballots[vetoer].attitude != uint8(BallotsBox.AttitudeOfVote.Support));
    }

    // ==== ExecResolution ====

    /// @notice Execute a passed resolution.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param contents Motion contents.
    /// @param executor Executor user number.
    function execResolution(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 contents,
        uint executor
    ) public {
        Motion storage m = repo.motions[seqOfMotion];
        if (m.contents != contents) {
            revert MR_WrongInput(bytes32("MR_WrongContents"));
        }
        if (m.body.state != uint8(StateOfMotion.Passed)) {
            revert MR_WrongState(bytes32("MR_MotionNotPassed"));
        }
        if (m.head.executor != uint40(executor)) {
            revert MR_WrongParty(bytes32("MR_NotExecutor"));
        }

        m.body.state = uint8(StateOfMotion.Executed);
    }
    
    //#################
    //##    Read     ##
    //#################

    // ==== VoteState ====

    /// @notice Check if motion is proposed.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    function isProposed(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return repo.motions[seqOfMotion].body.state == uint8(StateOfMotion.Proposed);
    }

    /// @notice Check if voting has started.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    function voteStarted(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return isProposed(repo, seqOfMotion) && 
            repo.motions[seqOfMotion].body.voteStartDate <= block.timestamp;
    }

    /// @notice Check if voting has ended.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    function voteEnded(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return isProposed(repo, seqOfMotion) && 
            repo.motions[seqOfMotion].body.voteEndDate <= block.timestamp;
    }

    // ==== Delegate ====

    /// @notice Get delegate map voter data.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param acct Voter user number.
    function getVoterOfDelegateMap(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (DelegateMap.Voter memory)
    {
        return repo.records[seqOfMotion].map.voters[acct];
    }

    /// @notice Get delegate of an account.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param acct Voter user number.
    function getDelegateOf(Repo storage repo, uint256 seqOfMotion, uint acct)
        public view returns (uint)
    {
        return repo.records[seqOfMotion].map.getDelegateOf(acct);
    }

    // ==== motion ====

    /// @notice Get motion by sequence.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    function getMotion(Repo storage repo, uint256 seqOfMotion)
        public view returns (Motion memory motion)
    {
        motion = repo.motions[seqOfMotion];
    }

    // ==== voting ====

    /// @notice Check if account has voted.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param acct Voter user number.
    function isVoted(Repo storage repo, uint256 seqOfMotion, uint256 acct) 
        public view returns (bool) 
    {
        return repo.records[seqOfMotion].box.isVoted(acct);
    }

    /// @notice Check if account voted for an attitude.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param acct Voter user number.
    /// @param atti Attitude value.
    function isVotedFor(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint256 atti
    ) public view returns (bool) {
        return repo.records[seqOfMotion].box.isVotedFor(acct, atti);
    }

    /// @notice Get aggregate case for attitude.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param atti Attitude value.
    function getCaseOfAttitude(Repo storage repo, uint256 seqOfMotion, uint256 atti)
        public view returns (BallotsBox.Case memory )
    {
        return repo.records[seqOfMotion].box.getCaseOfAttitude(atti);
    }

    /// @notice Get ballot for account.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    /// @param acct Voter user number.
    function getBallot(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (BallotsBox.Ballot memory)
    {
        return repo.records[seqOfMotion].box.getBallot(acct);
    }

    /// @notice Check if motion passed.
    /// @param repo Storage repo.
    /// @param seqOfMotion Motion sequence.
    function isPassed(Repo storage repo, uint256 seqOfMotion) public view returns (bool) {
        return repo.motions[seqOfMotion].body.state == uint8(MotionsRepo.StateOfMotion.Passed);
    }

    // ==== snList ====

    /// @notice Get motion sequence list.
    /// @param repo Storage repo.
    function getSeqList(Repo storage repo) public view returns (uint[] memory) {
        return repo.seqList.values();
    }

}

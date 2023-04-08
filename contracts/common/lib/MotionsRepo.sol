// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./BallotsBox.sol";
import "./DelegateMap.sol";
import "./EnumerableSet.sol";
import "./RulesParser.sol";

// import "../components/ISigPage.sol";

// import "../../keepers/IGeneralKeeper.sol";

// import "../../books/rom/IRegisterOfMembers.sol";
// import "../../books/bod/IBookOfDirectors.sol";

library MotionsRepo {
    using BallotsBox for BallotsBox.Box;
    using EnumerableSet for EnumerableSet.UintSet;
    using DelegateMap for DelegateMap.Map;
    using RulesParser for uint256;

    enum TypeOfMotion {
        ZeroPoint,
        // UpdateSHA,
        // ApproveIA,
        // ApproveDocOfGM,
        // IncreaseCapital,
        // DecreaseCapital,
        // ElectDirector,
        // RemoveDirector,
        // ApproveActionOfGM,
        ElectOfficer,
        RemoveOfficer,
        ApproveDoc,
        ApproveAction
    }

    enum StateOfMotion {
        ZeroPoint,
        Created,
        Proposed,
        Passed,
        Rejected,
        Rejected_NotToBuy,
        Rejected_ToBuy,
        Executed
    }

    struct Head {
        uint16 typeOfMotion;
        uint64 seqOfMotion;
        uint16 seqOfVR;
        uint40 creator;
        uint40 executor;
        uint48 createDate;        
        uint32 data;
    }

    struct Body {
        uint40 proposer;
        uint48 proposeDate;
        uint48 shareRegDate;
        uint48 voteStartDate;
        uint48 voteEndDate;
        uint16 para;
        uint8 state;
    }

    struct Motion {
        Head head;
        Body body;
        RulesParser.VotingRule votingRule;
        uint256 contents;
    }

    struct Record {
        DelegateMap.Map map;
        BallotsBox.Box box;        
    }

    struct VoteCalBase {
        uint64 totalHead;
        uint64 totalWeight;
        uint64 supportHead;
        uint64 supportWeight;            
    }

    struct Repo {
        mapping(uint256 => Motion) motions;
        mapping(uint256 => Record) records;
        EnumerableSet.UintSet snList;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== snParser ====

    function snParser (uint256 sn) public pure returns(Head memory head) {
        head = Head({
            typeOfMotion: uint16(sn >> 240),
            seqOfMotion: uint64(sn >> 176),
            seqOfVR: uint16(sn >> 160),
            creator: uint40(sn >> 120),
            executor: uint40(sn >> 80),
            createDate: uint48(sn >> 32),
            data: uint32(sn)
        });
    }

    function codifyHead(Head memory head) public pure returns(uint256 sn) {
        sn = (uint256(head.typeOfMotion) << 240) + 
            (uint256(head.seqOfMotion) << 176) +
            (uint256(head.seqOfVR) << 160) +
            (uint256(head.creator) << 120) +
            (uint256(head.executor) << 80) +
            (uint256(head.createDate) << 32) + 
            head.data;
    } 
    
    // ==== create ====

    function createMotion(
        Repo storage repo,
        Head memory head,
        uint256 contents
        // uint40 caller
    ) public returns (Head memory) {
        // head = snParser(snOfMotion);

        require(head.typeOfMotion > 0, "MR.CM: zero typeOfMotion");
        require(head.seqOfVR > 0, "MR.CM: zero seqOfVR");
        require(head.creator > 0, "MR.CM: zero caller");

        head.seqOfMotion = _increaseCounterOfMotion(repo);
        head.createDate = uint48(block.timestamp);
        
        uint256 snOfMotion = codifyHead(head);
        repo.snList.add(snOfMotion);

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

    function entrustDelegate(
        Repo storage repo,
        uint256 seqOfMotion,
        uint40 delegate,
        uint40 principal,
        uint64 weight
    ) public returns (bool flag) {
        Motion storage m = repo.motions[seqOfMotion];

        require(m.body.state == uint8(StateOfMotion.Created) ||
            m.body.state == uint8(StateOfMotion.Proposed), 
            "MR.ED: wrong state");

        flag = repo.records[seqOfMotion].map.entrustDelegate(principal, delegate, weight);
    }

    // ==== propose ====

    function proposeMotion(
        Repo storage repo,
        uint256 seqOfMotion,
        RulesParser.VotingRule memory vr,
        uint40 caller 
    ) public returns (Body memory body) {

        // require(seqOfMotion > 0, "MR.PM: zero seqOfMotion");
        require(caller > 0, "MR.PM: zero caller");

        Motion storage m = repo.motions[seqOfMotion];

        require(m.head.seqOfVR == vr.seqOfRule, "MR.PM: wrong seqOfVR");
        require(m.body.state == uint8(StateOfMotion.Created), 
            "MR.PM: wrong state");

        uint48 timestamp = uint48(block.timestamp);

        body = Body({
            proposer: caller,
            proposeDate: timestamp,
            shareRegDate: timestamp + uint48(vr.shaExecDays) * 86400,
            voteStartDate: timestamp + uint48(vr.reviewDays) * 86400,
            voteEndDate: timestamp + uint48(vr.votingDays) * 86400,
            para: 0,
            state: uint8(StateOfMotion.Proposed)
        });

        m.body = body;
        m.votingRule = vr;
    } 

    // ==== vote ====

    function castVote(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint8 attitude,
        bytes32 sigHash,
        IRegisterOfMembers _rom
    ) public returns (bool flag) {

        require(seqOfMotion > 0, "MR.CV: zero seqOfMotion");
        require(acct > 0, "MR.CV: zero acct");

        Motion storage m = repo.motions[seqOfMotion];
        Record storage r = repo.records[seqOfMotion];
        DelegateMap.Voter storage voter = r.map.voters[acct];

        if (voteStarted(repo, seqOfMotion) && 
            !voteEnded(repo, seqOfMotion) &&
            voter.delegate == 0)
        {
            if (voter.repHead > 0 &&
                voter.repWeight == 0)
            {
                voter.repWeight = 
                r.map.getLeavesWeightAtDate(acct, m.body.shareRegDate, _rom);
            } else {
                voter.repWeight +=
                _rom.votesAtDate(acct, m.body.shareRegDate);
            }

            voter.repHead++;

            r.box.castVote(acct, attitude, voter.repHead, voter.repWeight, sigHash);

            flag = true;
        }
    }

    // ==== counting ====

    function voteCounting(
        Repo storage repo,
        uint256 seqOfMotion,
        VoteCalBase memory base
    ) public returns (uint8) {

        Motion storage m = repo.motions[seqOfMotion];
        Record storage r = repo.records[seqOfMotion];

        require (m.body.state == uint8(StateOfMotion.Proposed) , "MR.VT: wrong state");
        require (voteEnded(repo, seqOfMotion), "MR.VT: vote not ended yet");

        bool flag1;
        bool flag2;

        if (!_isVetoed(r, m.votingRule.vetoers[0]) &&
            !_isVetoed(r, m.votingRule.vetoers[1])) {
            flag1 = m.votingRule.headRatio > 0
                ? base.totalHead > 0
                    ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                        .sumOfHead + base.supportHead) * 10000) /
                        base.totalHead >=
                        m.votingRule.headRatio
                    : false
                : true;

            flag2 = m.votingRule.amountRatio > 0
                ? base.totalWeight > 0
                    ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                        .sumOfWeight + base.supportWeight) * 10000) /
                        base.totalWeight >=
                        m.votingRule.amountRatio
                    : false
                : true;
        }

        m.body.state = (flag1 && flag2) ? 
            uint8(MotionsRepo.StateOfMotion.Passed) : 
            m.votingRule.againstShallBuy ?
                uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy) :
                uint8(MotionsRepo.StateOfMotion.Rejected_NotToBuy);

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

    function execResolution(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 contents,
        uint40 executor
    ) public {
        Motion storage m = repo.motions[seqOfMotion];
        require (m.contents == contents, "MR.ER: wrong contents");
        require (m.body.state == uint8(StateOfMotion.Passed), 
            "MR.ER: motion not passed");
        require (m.head.executor == executor, "MR.ER: not executor");

        m.body.state = uint8(StateOfMotion.Executed);
    }
    
    //#################
    //##    Read     ##
    //#################

    // ==== VoteState ====

    function isProposed(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return repo.motions[seqOfMotion].body.state == uint8(StateOfMotion.Proposed);
    }

    function voteStarted(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return isProposed(repo, seqOfMotion) && 
            repo.motions[seqOfMotion].body.voteStartDate <= block.timestamp;
    }

    function voteEnded(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return isProposed(repo, seqOfMotion) && 
            repo.motions[seqOfMotion].body.voteEndDate <= block.timestamp;
    }

    // ==== Delegate ====

    function getVoterOfDelegateMap(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (DelegateMap.Voter memory)
    {
        return repo.records[seqOfMotion].map.voters[acct];
    }

    function getDelegateOf(Repo storage repo, uint256 seqOfMotion, uint40 acct)
        public view returns (uint40)
    {
        return repo.records[seqOfMotion].map.getDelegateOf(acct);
    }

    function getLeavesWeightAtDate(
        Repo storage repo, 
        uint256 seqOfMotion, 
        uint40 acct,
        uint48 baseDate, 
        IRegisterOfMembers _rom
    ) public view returns(uint64 weight)
    {
        weight = repo.records[seqOfMotion].map.getLeavesWeightAtDate(acct, baseDate, _rom);
    }

    // ==== motion ====

    function getMotion(Repo storage repo, uint256 seqOfMotion)
        public view returns (Motion memory motion)
    {
        motion = repo.motions[seqOfMotion];
    }

    // ==== voting ====

    function isVoted(Repo storage repo, uint256 seqOfMotion, uint256 acct) 
        public view returns (bool) 
    {
        return repo.records[seqOfMotion].box.ballots[acct].sigDate > 0;
    }

    function isVotedFor(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint8 atti
    ) public view returns (bool) {
        return repo.records[seqOfMotion].box.ballots[acct].attitude == atti;
    }

    function getCaseOfAttitude(Repo storage repo, uint256 seqOfMotion, uint8 atti)
        public view returns (BallotsBox.Case memory )
    {
        return repo.records[seqOfMotion].box.cases[atti];
    }

    function getBallot(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (BallotsBox.Ballot memory)
    {
        return repo.records[seqOfMotion].box.ballots[acct];
    }

    function isPassed(Repo storage repo, uint256 seqOfMotion) public view returns (bool) {
        return repo.motions[seqOfMotion].body.state == uint8(MotionsRepo.StateOfMotion.Passed);
    }

}

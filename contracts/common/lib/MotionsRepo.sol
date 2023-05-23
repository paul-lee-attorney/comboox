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

import "../../books/boh/IShareholdersAgreement.sol";

library MotionsRepo {
    using BallotsBox for BallotsBox.Box;
    using DelegateMap for DelegateMap.Map;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using RulesParser for bytes32;

    enum TypeOfMotion {
        ZeroPoint,
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
        EnumerableSet.Bytes32Set snList;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== snParser ====

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

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encode(
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
    
    // ==== create ====

    function createMotion(
        Repo storage repo,
        Head memory head,
        uint256 contents
    ) public returns (Head memory) {

        require(head.typeOfMotion > 0, "MR.CM: zero typeOfMotion");
        require(head.seqOfVR > 0, "MR.CM: zero seqOfVR");
        require(head.creator > 0, "MR.CM: zero caller");

        head.seqOfMotion = _increaseCounterOfMotion(repo);
        head.createDate = uint48(block.timestamp);
        
        bytes32 snOfMotion = codifyHead(head);
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
        uint delegate,
        uint principal,
        uint weight
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
        IShareholdersAgreement _sha,
        // RulesParser.VotingRule memory vr,
        uint caller 
    ) public {

        // require(seqOfMotion > 0, "MR.PM: zero seqOfMotion");
        require(caller > 0, "MR.PM: zero caller");

        Motion storage m = repo.motions[seqOfMotion];
        RulesParser.VotingRule memory vr = 
            address(_sha) == address(0) 
            ? RulesParser.SHA_INIT_VR.votingRuleParser()
            : _sha.getRule(m.head.seqOfVR).votingRuleParser();

        // require(m.head.seqOfVR == vr.seqOfRule, "MR.PM: wrong seqOfVR");
        require(m.body.state == uint8(StateOfMotion.Created), 
            "MR.PM: wrong state");

        uint48 timestamp = uint48(block.timestamp);

        Body memory body = Body({
            proposer: uint40(caller),
            proposeDate: timestamp,
            shareRegDate: timestamp + uint48(vr.reconsiderDays) * 86400,
            voteStartDate: timestamp + (uint48(vr.reconsiderDays) + uint48(vr.votePrepareDays)) * 86400,
            voteEndDate: timestamp + (uint48(vr.reconsiderDays) + uint48(vr.votingDays)) * 86400,
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
        uint attitude,
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
                        base.totalHead >
                        m.votingRule.headRatio
                    : false
                : true;

            flag2 = m.votingRule.amountRatio > 0
                ? base.totalWeight > 0
                    ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                        .sumOfWeight + base.supportWeight) * 10000) /
                        base.totalWeight >
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
        uint executor
    ) public {
        Motion storage m = repo.motions[seqOfMotion];
        require (m.contents == contents, "MR.ER: wrong contents");
        require (m.body.state == uint8(StateOfMotion.Passed), 
            "MR.ER: motion not passed");
        require (m.head.executor == uint40(executor), "MR.ER: not executor");

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
            repo.motions[seqOfMotion].body.voteEndDate < block.timestamp;
    }

    // ==== Delegate ====

    function getVoterOfDelegateMap(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (DelegateMap.Voter memory)
    {
        return repo.records[seqOfMotion].map.voters[acct];
    }

    function getDelegateOf(Repo storage repo, uint256 seqOfMotion, uint acct)
        public view returns (uint)
    {
        return repo.records[seqOfMotion].map.getDelegateOf(acct);
    }

    function getLeavesWeightAtDate(
        Repo storage repo, 
        uint256 seqOfMotion, 
        uint acct,
        uint baseDate, 
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
        return repo.records[seqOfMotion].box.isVoted(acct);
    }

    function isVotedFor(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint256 atti
    ) public view returns (bool) {
        return repo.records[seqOfMotion].box.isVotedFor(acct, atti);
    }

    function getCaseOfAttitude(Repo storage repo, uint256 seqOfMotion, uint256 atti)
        public view returns (BallotsBox.Case memory )
    {
        return repo.records[seqOfMotion].box.getCaseOfAttitude(atti);
    }

    function getBallot(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (BallotsBox.Ballot memory)
    {
        return repo.records[seqOfMotion].box.getBallot(acct);
    }

    function isPassed(Repo storage repo, uint256 seqOfMotion) public view returns (bool) {
        return repo.motions[seqOfMotion].body.state == uint8(MotionsRepo.StateOfMotion.Passed);
    }

}

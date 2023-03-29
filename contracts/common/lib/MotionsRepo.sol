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

import "../components/ISigPage.sol";

import "../../books/rom/IRegisterOfMembers.sol";
import "../../books/bod/IBookOfDirectors.sol";

library MotionsRepo {
    using BallotsBox for BallotsBox.Box;
    using EnumerableSet for EnumerableSet.UintSet;

    enum StateOfMotion {
        ZeroPoint,
        Proposed,
        Passed,
        Rejected,
        Rejected_NotToBuy,
        Rejected_ToBuy,
        Executed
    }

    struct Head {
        uint8 state;
        uint40 proposer;
        uint40 executor;
        uint48 proposeDate;
        uint48 shareRegDate;
        uint48 voteStartDate;
    }

    struct Motion {
        Head head;
        RulesParser.VotingRule votingRule;
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
        EnumerableSet.UintSet motionIds;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== propose ====

    function proposeMotion(Repo storage repo, uint256 motionId, RulesParser.VotingRule memory rule, uint40 proposer, uint40 executor)
        public returns (bool flag)
    {
        if (repo.motionIds.add(motionId)) {
            Motion storage m = repo.motions[motionId];

            uint48 timestamp = uint48(block.timestamp);

            m.head = Head({
                state: uint8(StateOfMotion.Proposed),
                proposer: proposer,
                executor: executor,
                proposeDate: timestamp,
                shareRegDate: timestamp + rule.shaExecDays * 86400,
                voteStartDate: timestamp + (rule.shaExecDays + rule.reviewDays) * 86400
            });

            m.votingRule = rule; 

            flag = true;            
        }
    } 

    // ==== vote ====

    function castVote(
        Motion storage m,
        uint256 acct,
        uint8 attitude,
        uint64 weight,
        bytes32 sigHash
    ) public returns (bool flag) {
        if (
            voteStarted(m) &&
            !voteEnded(m) &&
            m.map.voters[acct].delegate == 0
        )
        {
            uint32 head = (m.map.voters[acct].repHead + 1);
            weight += m.map.voters[acct].repWeight;

            m.box.castVote(acct, attitude, head, weight, sigHash);

            flag = true;
        }
    }

    //#################
    //##    Read     ##
    //#################

    function isProposed(Motion storage m)
        public
        view
        returns (bool)
    {
        return m.head.proposer > 0;
    }

    function voteStarted(Motion storage m)
        public
        view
        returns (bool)
    {
        return isProposed(m) && m.head.voteStartDate <= block.timestamp;
    }

    function voteEnded(Motion storage m)
        public
        view
        returns (bool)
    {
        return isProposed(m) && m.head.voteStartDate + 
            m.votingRule.votingDays * 86400 
            < block.timestamp;
    }

    // ==== counting ====

    function getVoteResult(
        Motion storage m,
        IRegisterOfMembers _rom,
        IBookOfDirectors _bod
    ) public view returns (bool flag) {
        VoteCalBase memory base = _getVoteBase(m, _rom, _bod);
        flag = _getVoteResult(m, base);
    }

    function getDocApproval(
        Motion storage m,
        uint256 motionId,
        IRegisterOfMembers _rom,
        IBookOfDirectors _bod
    ) public view returns (bool flag) {
        VoteCalBase memory base = _getVoteBase(m, _rom, _bod);
        base = _getDocApprovalBase(m, motionId, _rom, _bod, base);
        flag = _getVoteResult(m, base);
    }

    function _getVoteBase(
        Motion storage m,
        IRegisterOfMembers _rom,
        IBookOfDirectors _bod
    )
        private
        view
        returns (VoteCalBase memory base)
    {
        require (voteEnded(m), "MR.VC: vote not ended yet");

        if (m.votingRule.onlyAttendance) {
            BallotsBox.Case memory caseOfAll = m.box.cases[uint8(BallotsBox.AttitudeOfVote.All)];
            base.totalHead = caseOfAll.sumOfHead;
            base.totalWeight = caseOfAll.sumOfWeight;
        } else {
            if (m.votingRule.authority == 1) {
                base.totalHead = _rom.qtyOfMembers();
                base.totalWeight = _rom.votesAtDate(0, m.head.shareRegDate);
            } else if (m.votingRule.authority == 0) {
                base.totalHead = _bod.qtyOfDirectors();
            }                
            // members not cast vote
            if (m.votingRule.impliedConsent) {
                base.supportHead = (base.totalHead -
                    m.box.cases[uint8(BallotsBox.AttitudeOfVote.Against)].sumOfHead -
                    m.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)].sumOfHead);
                base.supportWeight = (base.totalWeight -
                    (m.box.cases[uint8(BallotsBox.AttitudeOfVote.Against)].sumOfWeight) -
                    m.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)].sumOfWeight);
            }
        }
    }

    function _getDocApprovalBase(
        Motion storage m,
        uint256 motionId,
        IRegisterOfMembers _rom,
        IBookOfDirectors _bod,
        VoteCalBase memory base
    ) private view returns (VoteCalBase memory)
    {
        if (!m.votingRule.onlyAttendance) {

            uint256[] memory parties =  ISigPage((address(uint160(motionId)))).getParties();
            uint256 len = parties.length;

            if (m.votingRule.seq < 9) {

                while (len > 0) {
                    uint64 voteAmt = _rom.votesAtDate(
                        parties[len - 1],
                        m.head.shareRegDate
                    );

                    // party has voting right at block
                    if (voteAmt > 0) {
                        if (m.votingRule.partyAsConsent) {
                            if (!m.votingRule.impliedConsent) {
                                base.supportHead++;
                                base.supportWeight += voteAmt;
                            }
                        } else {
                                base.totalHead--;
                                base.totalWeight -= voteAmt;

                            if (m.votingRule.impliedConsent) {
                                base.supportHead--;
                                base.supportWeight -= voteAmt;
                            }
                        }
                    }

                    len--;
                }
                return base;

            } else if (m.votingRule.seq < 17) {

                while (len > 0) {
                    uint32 voteHead = uint32(_bod.boardSeatsOf(parties[len - 1]));

                    // party has voting right
                    if (voteHead > 0) {
                        if (m.votingRule.partyAsConsent) {
                            if (!m.votingRule.impliedConsent) {
                                base.supportHead += voteHead;
                            }
                        } else {
                            base.totalHead--;

                            if (m.votingRule.impliedConsent) {
                                base.supportHead -= voteHead;
                            }
                        }
                    }
                    len--;
                }
                return base;   
            }
        }

        return base;
    }

    function _getVoteResult(
        Motion storage m,
        VoteCalBase memory base
    ) private view returns (bool flag) {

        bool flag1;
        bool flag2;

        if (
            !_isVetoed(m, m.votingRule.vetoers[0]) &&
            !_isVetoed(m, m.votingRule.vetoers[1]) &&
            !_isVetoed(m, m.votingRule.vetoers[2])
        ) {
            flag1 = m.votingRule.headRatio > 0
                ? base.totalHead > 0
                    ? ((m.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                        .sumOfHead + base.supportHead) * 10000) /
                        base.totalHead >=
                        m.votingRule.headRatio
                    : false
                : true;

            flag2 = m.votingRule.amountRatio > 0
                ? base.totalWeight > 0
                    ? ((m.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                        .sumOfWeight + base.supportWeight) * 10000) /
                        base.totalWeight >=
                        m.votingRule.amountRatio
                    : false
                : true;
        }

        flag = flag1 && flag2;
    }

    function _isVetoed(Motion storage m, uint256 vetoer)
        private
        view
        returns (bool)
    {
        return
            vetoer > 0 &&
            m.box.ballots[vetoer].attitude == uint8(BallotsBox.AttitudeOfVote.Against);
    }



}

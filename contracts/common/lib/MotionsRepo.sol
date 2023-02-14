// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./SNParser.sol";
import "./EnumerableSet.sol";
import "./BallotsBox.sol";
import "./DelegateMap.sol";

// import "../access/IRegCenter.sol";
import "../components/ISigPage.sol";
import "../components/IRepoOfDocs.sol";

import "../../books/rom/IRegisterOfMembers.sol";
import "../../books/boh/IShareholdersAgreement.sol";

library MotionsRepo {
    using BallotsBox for BallotsBox.Box;
    using DelegateMap for DelegateMap.Map;
    using EnumerableSet for EnumerableSet.UintSet;
    using SNParser for bytes32;

    enum StateOfMotion {
        Pending,
        Proposed,
        Passed,
        Rejected,
        Rejected_NotToBuy,
        Rejected_ToBuy,
        Executed
    }

    enum AttitudeOfVote {
        All,
        Support,
        Against,
        Abstain
    }

    struct Head {
        uint16 typeOfVote;
        uint8 state; // 0-pending 1-proposed  2-passed 3-rejected(not to buy) 4-rejected (to buy)
        uint40 executor;
        uint48 proposeDate;
        uint48 voteStartDate;
        uint48 voteEndDate;
    }

    struct Motion {
        Head head;
        bytes32 votingRule;
        BallotsBox.Box box;
        DelegateMap.Map map;
    }

    struct Repo {
        mapping(uint256 => Motion) motions;
        EnumerableSet.UintSet motionIds;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== delegate ====

    function entrustDelegate(
        Repo storage repo,
        uint40 acct,
        uint40 delegate,
        uint256 motionId
    ) public returns (bool flag) {
        Motion storage m = repo.motions[motionId];

        if (
            m.box.ballots[acct].sigDate == 0 &&
            block.timestamp < m.head.voteStartDate
        ) {
            flag = repo.motions[motionId].map.entrustDelegate(acct, delegate);
        }
    }

    // ==== propose ====

    function proposeMotion(
        Repo storage repo,
        uint256 motionId,
        bytes32 rule,
        uint40 executor
    ) public returns (bool flag) {
        if (repo.motionIds.add(motionId)) {

            uint48 reviewDays = rule.reviewDaysOfVR();
            uint48 votingDays = rule.votingDaysOfVR();
            uint48 timestamp = uint48(block.timestamp);

            Motion storage m = repo.motions[motionId];

            m.votingRule = rule;

            m.head = Head({
                typeOfVote: rule.seqOfRule(),
                state: uint8(StateOfMotion.Proposed),
                executor: executor,
                proposeDate: timestamp,
                voteStartDate: timestamp + reviewDays * 86400,
                voteEndDate: timestamp + (reviewDays + votingDays) * 86400
            });
            
            flag = true;
        }
    }

    // ==== vote ====

    function castVote(
        Repo storage repo,
        uint256 motionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash,
        IRegisterOfMembers _rom
    ) public returns (bool flag) {
        Motion storage m = repo.motions[motionId];

        require(
            block.timestamp >= m.head.voteStartDate,
            "MR. castVote: vote not start"
        );
        require(
            block.timestamp <= m.head.voteEndDate ||
                m.head.voteEndDate == m.head.voteStartDate,
            "MR.castVote: vote closed"
        );
        require(
            m.map.delegateOf[caller] == 0,
            "MR.castVote: entrused delegate"
        );

        uint64 voteWeight;

        if (m.map.principalsOf[caller].length > 0)
            voteWeight = _voteWeight(m.map, caller, m.head.voteStartDate, _rom);
        else voteWeight = _rom.votesAtDate(caller, m.head.voteStartDate);

        flag = m.box.castVote(caller, attitude, voteWeight, sigHash);
    }

    function _voteWeight(
        DelegateMap.Map storage map,
        uint40 acct,
        uint48 blockdate,
        IRegisterOfMembers _rom
    ) private view returns (uint64) {
        uint40[] memory principals = map.principalsOf[acct];
        uint256 len = principals.length;
        uint64 weight = _rom.votesAtDate(acct, blockdate);

        while (len > 0) {
            weight += _rom.votesAtDate(principals[len - 1], blockdate);
            len--;
        }

        return weight;
    }

    // ==== counting ====

    function voteCounting(
        Repo storage repo,
        uint256 motionId,
        IRepoOfDocs _rod,
        IRegisterOfMembers _rom
    ) public returns (bool flag) {
        if (repo.motions[motionId].head.voteEndDate < block.number) {
            (
                uint64 totalHead,
                uint64 totalAmt,
                uint64 consentHead,
                uint64 consentAmt
            ) = _getParas(repo, motionId, _rod, _rom);

            bool flag1;
            bool flag2;

            Motion storage m = repo.motions[motionId];

            if (
                !_isVetoed(m, m.votingRule.vetoerOfVR()) &&
                !_isVetoed(m, m.votingRule.vetoer2OfVR()) &&
                !_isVetoed(m, m.votingRule.vetoer3OfVR())
            ) {
                flag1 = m.votingRule.ratioHeadOfVR() > 0
                    ? totalHead > 0
                        ? ((m
                            .box
                            .cases[uint8(AttitudeOfVote.Support)]
                            .voters
                            .length() + consentHead) * 10000) /
                            totalHead >=
                            m.votingRule.ratioHeadOfVR()
                        : false
                    : true;

                flag2 = m.votingRule.ratioAmountOfVR() > 0
                    ? totalAmt > 0
                        ? ((m
                            .box
                            .cases[uint8(AttitudeOfVote.Support)]
                            .sumOfWeight + consentAmt) * 10000) /
                            totalAmt >=
                            m.votingRule.ratioAmountOfVR()
                        : false
                    : true;
            }

            m.head.state = flag1 && flag2
                ? uint8(StateOfMotion.Passed)
                : m.votingRule.againstShallBuyOfVR()
                ? uint8(StateOfMotion.Rejected_ToBuy)
                : uint8(StateOfMotion.Rejected_NotToBuy);

            flag = true;
        }
    }

    function _isVetoed(Motion storage m, uint40 vetoer)
        public
        view
        returns (bool)
    {
        return
            vetoer > 0 &&
            m.box.cases[uint8(AttitudeOfVote.Against)].voters.contains(vetoer);
    }

    function _getParas(
        Repo storage repo,
        uint256 motionId,
        IRepoOfDocs _rod,
        IRegisterOfMembers _rom
    )
        private
        view
        returns (
            uint64 totalHead,
            uint64 totalAmt,
            uint64 consentHead,
            uint64 consentAmt
        )
    {
        Motion storage m = repo.motions[motionId];

        if (m.votingRule.onlyAttendanceOfVR()) {
            totalHead = uint64(
                m.box.cases[uint8(AttitudeOfVote.All)].voters.length()
            );
            totalAmt = m.box.cases[uint8(AttitudeOfVote.All)].sumOfWeight;
        } else {
            // members hold voting rights at block
            totalHead = _rom.qtyOfMembers();
            totalAmt = _rom.votesAtDate(0, m.head.voteStartDate);

            if (m.head.typeOfVote < 8) {
                // 1-7 typeOfIA; 8-external deal

                // minus parties of doc;
                uint40[] memory parties = _rod.partiesOfDoc((address(uint160(motionId))));
                uint256 len = parties.length;

                while (len > 0) {
                    uint64 voteAmt = _rom.votesAtDate(
                        parties[len - 1],
                        m.head.voteStartDate
                    );

                    // party has voting right at block
                    if (voteAmt != 0) {
                        if (m.votingRule.partyAsConsentOfVR()) {
                            consentHead++;
                            consentAmt += voteAmt;
                        } else {
                            totalHead--;
                            totalAmt -= voteAmt;
                        }
                    }

                    len--;
                }
            }

            // members not cast vote
            if (m.votingRule.impliedConsentOfVR()) {
                consentHead += (totalHead -
                    uint64(
                        m.box.cases[uint8(AttitudeOfVote.All)].voters.length()
                    ));
                consentAmt += (totalAmt -
                    (m.box.cases[uint8(AttitudeOfVote.All)].sumOfWeight));
            }
        }
    }

    //##################
    //##    Read     ##
    //################

    // function beforeVoteStart(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return repo.motions[motionId].head.voteStartDate > block.number;
    // }

    // function afterVoteEnd(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return repo.motions[motionId].head.voteEndDate < block.number;
    // }

    // function onVoting(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return
    //         repo.motions[motionId].head.voteStartDate <= block.number &&
    //         block.number <= repo.motions[motionId].head.voteEndDate;
    // }

    // function isProposed(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return repo.motionIds.contains(motionId);
    // }

    // function headOf(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (Head memory)
    // {
    //     return repo.motions[motionId].head;
    // }

    // function votingRule(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (bytes32)
    // {
    //     return repo.motions[motionId].votingRule;
    // }

    // function state(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (uint8)
    // {
    //     return repo.motions[motionId].head.state;
    // }

    // function isPassed(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return repo.motions[motionId].head.state == uint8(StateOfMotion.Passed);
    // }

    // function isExecuted(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return
    //         repo.motions[motionId].head.state == uint8(StateOfMotion.Executed);
    // }

    // function isRejected(Repo storage repo, uint256 motionId)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return (repo.motions[motionId].head.state ==
    //         uint8(StateOfMotion.Rejected_NotToBuy) ||
    //         repo.motions[motionId].head.state ==
    //         uint8(StateOfMotion.Rejected_ToBuy));
    // }
}

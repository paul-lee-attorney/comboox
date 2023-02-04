// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./SNParser.sol";
import "./EnumerableSet.sol";
import "./BallotsBox.sol";
import "./DelegateMap.sol";

// import "../access/IRegCenter.sol";
import "../components/ISigPage.sol";

import "../../books/rom/IRegisterOfMembers.sol";
import "../../books/boh/IShareholdersAgreement.sol";

library MotionsRepo {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using BallotsBox for BallotsBox.Box;
    using DelegateMap for DelegateMap.Map;

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
        // uint40 submitter;
        uint40 executor;
        uint64 proposeBN;
        // uint64 voteStartBN;
        uint64 voteStartBN;
        uint64 voteEndBN;
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
    ) internal returns (bool flag) {
        Motion storage m = repo.motions[motionId];

        if (
            m.box.ballots[acct].sigDate == 0 &&
            block.number < m.head.voteStartBN
        ) {
            flag = repo.motions[motionId].map.entrustDelegate(acct, delegate);
        }
    }

    // ==== propose ====

    function proposeMotion(
        Repo storage repo,
        uint256 motionId,
        bytes32 rule,
        uint40 executor,
        uint64 blocksPerHour
    ) internal returns (bool flag) {
        if (repo.motionIds.add(motionId)) {
            Motion storage m = repo.motions[motionId];

            uint64 reviewDays = rule.reviewDaysOfVR();
            uint64 votingDays = rule.votingDaysOfVR();

            m.votingRule = rule;

            m.head.typeOfVote = rule.seqOfRule();
            m.head.executor = executor;

            m.head.proposeBN = uint64(block.number);
            m.head.voteStartBN =
                m.head.proposeBN +
                reviewDays *
                24 *
                blocksPerHour;
            m.head.voteEndBN =
                m.head.voteStartBN +
                votingDays *
                24 *
                blocksPerHour;

            m.head.state = uint8(StateOfMotion.Proposed);

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
    ) internal returns (bool flag) {
        Motion storage m = repo.motions[motionId];

        require(
            block.number >= m.head.voteStartBN,
            "MR. castVote: vote not start"
        );
        require(
            block.number <= m.head.voteEndBN ||
                m.head.voteEndBN == m.head.voteStartBN,
            "MR.castVote: vote closed"
        );
        require(
            m.map.delegateOf[caller] == 0,
            "MR.castVote: entrused delegate"
        );

        uint64 voteWeight;

        if (m.map.principalsOf[caller].length > 0)
            voteWeight = _voteWeight(m.map, caller, m.head.voteStartBN, _rom);
        else voteWeight = _rom.votesAtBlock(caller, m.head.voteStartBN);

        flag = m.box.castVote(caller, attitude, voteWeight, sigHash);
    }

    function _voteWeight(
        DelegateMap.Map storage map,
        uint40 acct,
        uint64 blocknumber,
        IRegisterOfMembers _rom
    ) private view returns (uint64) {
        uint40[] memory principals = map.principalsOf[acct];
        uint256 len = principals.length;
        uint64 weight = _rom.votesAtBlock(acct, blocknumber);

        while (len > 0) {
            weight += _rom.votesAtBlock(principals[len - 1], blocknumber);
            len--;
        }

        return weight;
    }

    // ==== counting ====

    function voteCounting(
        Repo storage repo,
        uint256 motionId,
        IRegisterOfMembers _rom
    ) internal returns (bool flag) {
        if (repo.motions[motionId].head.voteEndBN < block.number) {
            (
                uint64 totalHead,
                uint64 totalAmt,
                uint64 consentHead,
                uint64 consentAmt
            ) = _getParas(repo, motionId, _rom);

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
        internal
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
            totalAmt = _rom.votesAtBlock(0, m.head.voteStartBN);

            if (m.head.typeOfVote < 8) {
                // 1-7 typeOfIA; 8-external deal

                // minus parties of IA;
                uint40[] memory parties = ISigPage(address(uint160(motionId)))
                    .partiesOfDoc();
                uint256 len = parties.length;

                while (len != 0) {
                    uint64 voteAmt = _rom.votesAtBlock(
                        parties[len - 1],
                        m.head.voteStartBN
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
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return repo.motions[motionId].head.voteStartBN > block.number;
    // }

    // function afterVoteEnd(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return repo.motions[motionId].head.voteEndBN < block.number;
    // }

    // function onVoting(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return
    //         repo.motions[motionId].head.voteStartBN <= block.number &&
    //         block.number <= repo.motions[motionId].head.voteEndBN;
    // }

    // function isProposed(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return repo.motionIds.contains(motionId);
    // }

    // function headOf(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (Head memory)
    // {
    //     return repo.motions[motionId].head;
    // }

    // function votingRule(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (bytes32)
    // {
    //     return repo.motions[motionId].votingRule;
    // }

    // function state(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (uint8)
    // {
    //     return repo.motions[motionId].head.state;
    // }

    // function isPassed(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return repo.motions[motionId].head.state == uint8(StateOfMotion.Passed);
    // }

    // function isExecuted(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return
    //         repo.motions[motionId].head.state == uint8(StateOfMotion.Executed);
    // }

    // function isRejected(Repo storage repo, uint256 motionId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     return (repo.motions[motionId].head.state ==
    //         uint8(StateOfMotion.Rejected_NotToBuy) ||
    //         repo.motions[motionId].head.state ==
    //         uint8(StateOfMotion.Rejected_ToBuy));
    // }
}

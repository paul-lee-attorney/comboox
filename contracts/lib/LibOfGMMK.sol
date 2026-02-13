// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
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

import "./ArrayUtils.sol";
import "./BallotsBox.sol";
import "./InterfacesHub.sol";
import "./MotionsRepo.sol";
import "./SharesRepo.sol";
import "./RulesParser.sol";

import "../comps/common/components/IMeetingMinutes.sol";
import "../comps/common/components/ISigPage.sol";
import "../comps/books/rom/IRegisterOfMembers.sol";
import "../openzeppelin/utils/Address.sol";

library LibOfGMMK {
    using RulesParser for bytes32;
    using ArrayUtils for uint[];
    using InterfacesHub for address;
    using Address for address;

    /// @notice Emitted when a general meeting action is executed.
    /// @param targets Target contract address.
    /// @param values ETH value.
    /// @param params Encoded parameters blob.
    /// @param seqOfMotion Motion sequence.
    /// @param caller Caller user number.
    event ExecAction(address indexed targets, uint indexed values, bytes indexed params, uint seqOfMotion, uint caller);

    function voteCountingOfGM(uint256 seqOfMotion) external {
        address gk = address(this);
        IRegisterOfMembers _rom = gk.getROM();
        IMeetingMinutes _gmm = gk.getGMM();

        MotionsRepo.Motion memory motion =
            _gmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;

        BallotsBox.Case memory case0 = _gmm.getCaseOfAttitude(motion.head.seqOfMotion, 0);

        if (_allConsent(_gmm, _rom, motion, case0)) {
            base.unaniConsent = true;
        } else {
            base = _calBase(_gmm, _rom, motion, base, case0);
        }

        bool quorumFlag = (address(gk.getSHA()) == address(0) ||
            base.attendWeightRatio >=
            gk.getSHA().getRule(0).governanceRuleParser().quorumOfGM);

        bool approved = _gmm.voteCounting(quorumFlag, seqOfMotion, base) ==
            uint8(MotionsRepo.StateOfMotion.Passed);

        if (motion.head.seqOfVR < 9) {
            address doc = address(uint160(motion.contents));

            if (motion.head.seqOfVR == 8) {
                gk.getROC().voteCountingForFile(doc, approved);
            } else {
                gk.getROA().voteCountingForFile(doc, approved);
            }
        }
    }

    function execActionOfGM(
        uint caller,
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) public {
        require(
            targets.length == values.length && targets.length == params.length,
            "GMVK.execAction: length mismatch"
        );

        uint len = targets.length;
        while (len > 0) {
            targets[len - 1].functionCallWithValue(params[len - 1], values[len - 1]);
            emit ExecAction(targets[len - 1], values[len - 1], params[len - 1], seqOfMotion, caller);
            len--;
        }

        address(this).getGMM().execAction(
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            caller
        );
    }

    function _allConsent(
        IMeetingMinutes _gmm,
        IRegisterOfMembers _rom,
        MotionsRepo.Motion memory motion,
        BallotsBox.Case memory case0
    ) private view returns(bool) {
        BallotsBox.Case memory case1 = _gmm.getCaseOfAttitude(motion.head.seqOfMotion, 1);
        uint[] memory consentVoters = case1.voters.combine(case1.principals);

        uint[] memory allVoters = case0.voters.combine(case0.principals);

        if (allVoters.length > consentVoters.length) return false;

        uint[] memory members = motion.votingRule.class == 0
            ? _rom.membersList()
            : _rom.getMembersOfClass(motion.votingRule.class);

        uint[] memory restMembers = members.minus(consentVoters);

        if (restMembers.length == 0) return true;

        if (motion.head.typeOfMotion ==
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) {

            uint256[] memory parties =
                ISigPage(address(uint160(motion.contents))).getParties();

            uint[] memory vetoMembers = restMembers.minus(parties);

            uint len = vetoMembers.length;

            while (len > 0) {
                if (_rom.votesAtDate(vetoMembers[len - 1], motion.body.shareRegDate) > 0) return false;
                len--;
            }

            return true;
        }

        return false;
    }

    function _calBase(
        IMeetingMinutes _gmm,
        IRegisterOfMembers _rom,
        MotionsRepo.Motion memory motion,
        MotionsRepo.VoteCalBase memory base,
        BallotsBox.Case memory case0
    ) private view returns (MotionsRepo.VoteCalBase memory) {
        address gk = address(this);
        BallotsBox.Case memory case3 = _gmm.getCaseOfAttitude(motion.head.seqOfMotion, 3);

        uint64 votesOfMembers;
        if (motion.votingRule.class == 0) {
            votesOfMembers = _rom.totalVotes();
        } else {
            SharesRepo.Share memory classInfo =
                gk.getROS().getInfoOfClass(motion.votingRule.class);
            votesOfMembers = _rom.basedOnPar()
                ? classInfo.head.votingWeight * classInfo.body.par
                : classInfo.head.votingWeight * classInfo.body.paid;
        }

        base.attendWeightRatio = uint16(case0.sumOfWeight * 10000 / votesOfMembers);

        if (motion.votingRule.onlyAttendance) {

            base.totalHead = (case0.sumOfHead - case3.sumOfHead);
            base.totalWeight = (case0.sumOfWeight - case3.sumOfWeight);

        } else {

            base.totalHead = motion.votingRule.class == 0
                ? uint32(_rom.qtyOfMembers())
                : uint32(_rom.qtyOfClassMember(motion.votingRule.class));

            base.totalWeight = votesOfMembers;

            if (motion.votingRule.impliedConsent) {

                base.supportHead = base.totalHead - case0.sumOfHead;
                base.supportWeight = base.totalWeight > case0.sumOfWeight
                        ? (base.totalWeight - case0.sumOfWeight)
                        : 0;
                base.attendWeightRatio = 10000;
            }

            base.totalHead -= case3.sumOfHead;
            base.totalWeight = base.totalWeight > case3.sumOfWeight
                    ? base.totalWeight - case3.sumOfWeight
                    : 0 ;
        }

        if (motion.head.typeOfMotion ==
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) {

            uint256[] memory parties =
                ISigPage(address(uint160(motion.contents))).getParties();
            uint256 len = parties.length;

            while (len > 0) {
                uint64 votesAtDate =
                    _rom.votesAtDate(parties[len - 1], motion.body.shareRegDate);

                if (votesAtDate > 0) {
                    if (motion.votingRule.partyAsConsent) {

                        if (motion.votingRule.onlyAttendance) {
                            base.totalHead++;
                            base.totalWeight += votesAtDate;
                        }

                        if (!motion.votingRule.impliedConsent) {
                            base.supportHead ++;
                            base.supportWeight += votesAtDate;

                            base.attendWeightRatio += uint16(votesAtDate * 10000 / votesOfMembers);
                        }

                    } else {

                        if (!motion.votingRule.onlyAttendance) {
                            base.totalHead --;

                            base.totalWeight = base.totalWeight > votesAtDate
                                    ? base.totalWeight - votesAtDate
                                    : 0;
                        }

                        if (motion.votingRule.impliedConsent) {
                            base.supportHead --;

                            base.supportWeight = base.supportWeight > votesAtDate
                                    ? base.supportWeight - votesAtDate
                                    : 0;
                        } else {
                            base.attendWeightRatio += uint16(votesAtDate * 10000 / votesOfMembers);
                        }
                    }
                }

                len--;
            }
        }

        return base;
    }
}

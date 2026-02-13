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

import "./RulesParser.sol";
import "./ArrayUtils.sol";
import "./InterfacesHub.sol";
import "../openzeppelin/utils/Address.sol";

library LibOfBMMK {
    using RulesParser for bytes32;
    using ArrayUtils for uint[];
    using InterfacesHub for address;
    using Address for address;


    /// @notice Emitted when a board motion executes an action.
    /// @param targets Target contract address.
    /// @param values ETH value.
    /// @param params Encoded parameters blob.
    /// @param seqOfMotion Motion sequence.
    /// @param caller Caller user number.
    event ExecAction(
        address indexed targets, 
        uint indexed values, 
        bytes indexed params, 
        uint seqOfMotion, 
        uint caller
    );
    
    //###############
    //##   Write   ##
    //###############

    // ==== Vote Counting ====

    function _nominators(IRegisterOfDirectors _rod, uint director) private view returns(uint[] memory) {
        OfficersRepo.Position[] memory poses = 
            _rod.getFullPosInfoInHand(director);
        
        uint len = poses.length;
        uint[] memory nominators = new uint[](len);

        while (len > 0) {
            nominators[len-1] = poses[len-1].nominator;
            len--;
        }

        return nominators;
    }


    function _allConsent(
        IMeetingMinutes _bmm, 
        IRegisterOfDirectors _rod, 
        MotionsRepo.Motion memory motion,
        BallotsBox.Case memory case0
    ) private view returns(bool) {

        BallotsBox.Case memory case1 = _bmm.getCaseOfAttitude(motion.head.seqOfMotion, 1);         
        uint[] memory consentVoters = case1.voters.combine(case1.principals);

        // BallotsBox.Case memory case0 = _bmm.getCaseOfAttitude(motion.head.seqOfMotion, 0);         
        uint[] memory allVoters = case0.voters.combine(case0.principals);

        if (allVoters.length > consentVoters.length) return false;

        uint[] memory directors = _rod.getDirectorsList();
        uint[] memory restDirectors = directors.minus(consentVoters);

        if (restDirectors.length == 0) return true;
        
        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc) &&
            motion.head.seqOfVR < 9) {

            uint256[] memory parties = 
                ISigPage(address(uint160(motion.contents))).getParties();

            uint[] memory affiDirectors = restDirectors.minus(parties);
            
            uint len = affiDirectors.length;

            while (len > 0) {
                uint[] memory nominators = _nominators(_rod, affiDirectors[len-1]);
                if (nominators.noOverlapWith(parties)) return false;
                len--;
            }

            return true;
        }

        return false;
    } 

    function _calBase(
        IMeetingMinutes _bmm, 
        IRegisterOfDirectors _rod, 
        MotionsRepo.Motion memory motion,
        MotionsRepo.VoteCalBase memory base,
        BallotsBox.Case memory case0
    ) private view returns(MotionsRepo.VoteCalBase memory) {

        BallotsBox.Case memory case3 = _bmm.getCaseOfAttitude(motion.head.seqOfMotion, 3);

        uint32 numOfDirectors = uint32(_rod.getNumOfDirectors());
        base.attendHeadRatio = uint16(case0.sumOfHead * 10000 / numOfDirectors);

        if (motion.votingRule.onlyAttendance) {
            base.totalHead = case0.sumOfHead - case3.sumOfHead;
        } else {
            base.totalHead = numOfDirectors - case3.sumOfHead;
            if (motion.votingRule.impliedConsent) {
                base.supportHead = (base.totalHead - case0.sumOfHead);
                base.attendHeadRatio = 10000;
            }
        }

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
        {
            uint256[] memory parties = 
                ISigPage((address(uint160(motion.contents)))).getParties();
            uint256 len = parties.length;

            while (len > 0) {
                uint32 voteHead = 
                    uint32(_rod.getBoardSeatsOccupied(uint40(parties[len - 1])));

                if (voteHead > 0) {
                    if (motion.votingRule.partyAsConsent) {

                        if (motion.votingRule.onlyAttendance) {
                            base.totalHead += voteHead;
                        }

                        if (!motion.votingRule.impliedConsent) {
                            base.supportHead += voteHead;

                            base.attendHeadRatio += uint16(voteHead * 10000 / numOfDirectors);
                        }
                    } else {
                        if (!motion.votingRule.onlyAttendance) {
                            base.totalHead -= voteHead;
                        }
                        
                        if (motion.votingRule.impliedConsent) {
                            base.supportHead -= voteHead;
                        } else {
                            base.attendHeadRatio += uint16(voteHead * 10000 / numOfDirectors);
                        }

                        if (base.totalHead == 0)
                            base.unaniConsent = true;
                    }
                }

                len--;
            }                
        }
        
        return base;
    }

    function voteCounting(uint256 seqOfMotion) public {        
        address gk = address(this);

        IRegisterOfDirectors _rod = gk.getROD();
        IMeetingMinutes _bmm = gk.getBMM();
        
        MotionsRepo.Motion memory motion = 
            _bmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;

        BallotsBox.Case memory case0 = _bmm.getCaseOfAttitude(motion.head.seqOfMotion, 0);         

        if (_allConsent(_bmm, _rod, motion, case0)) {
            base.unaniConsent = true;
        } else {
            base = _calBase(_bmm, _rod, motion, base, case0);
        }

        IShareholdersAgreement _sha = gk.getSHA();

        bool quorumFlag = (address(_sha) == address(0) || 
            base.attendHeadRatio >= 
            _sha.getRule(0).governanceRuleParser().quorumOfBoardMeeting);

        _bmm.voteCounting(quorumFlag, seqOfMotion, base);
    }

    function execAction(
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
            "BMVK.execAction: length mismatch"
        );

        uint len = targets.length;
        while (len > 0) {
            targets[len-1].functionCallWithValue(params[len-1], values[len-1]);
            emit ExecAction(targets[len-1], values[len-1], params[len-1], seqOfMotion, caller);
            len--;
        }

        address(this).getBMM().execAction(
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            caller
        );
    }
}

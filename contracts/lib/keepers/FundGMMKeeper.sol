// SPDX-License-Identifier: UNLICENSED

/* *
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

import "../books/RulesParser.sol";
import "../utils/ArrayUtils.sol";
import "../InterfacesHub.sol";
import "../utils/RoyaltyCharge.sol";
import "../../openzeppelin/utils/Address.sol";

library FundGMMKeeper {
    using RulesParser for bytes32;
    using ArrayUtils for uint[];
    using InterfacesHub for address;
    using RoyaltyCharge for address;
    using Address for address;

    // uint32(uint(keccak256("FundGMMKeeper")));
    uint public constant TYPE_OF_DOC = 0x6c88e247;
    uint public constant VERSION = 1;

    //######################
    //##   Error & Event  ##
    //######################

    error FundGMMK_WrongParty(bytes32 reason);

    error FundGMMK_WrongState(bytes32 reason);

    error FundGMMK_WrongInput(bytes32 reason);

    /// @notice Emitted when a general meeting action is executed.
    /// @param targets Target contract address.
    /// @param values ETH value.
    /// @param params Encoded parameters blob.
    /// @param seqOfMotion Motion sequence.
    /// @param caller Caller user number.
    event ExecAction(address indexed targets, uint indexed values, bytes indexed params, uint seqOfMotion, uint caller);

    modifier onlyDK() {
        address _gk = address(this);

        if( msg.sender != IAccessControl(_gk).getDK() )
            revert FundGMMK_WrongParty(bytes32("FundGMMK_NotDK"));
        _;
    }

    // ==== Function Modifiers ====

    function _gpOrManager(uint caller) private view{
        address _gk = address(this);
        if( !_gk.getROM().isClassMember(caller, 1) && 
            !_gk.getROD().isDirector(caller)
        ) revert FundGMMK_WrongParty(bytes32("FundGMMK_NotGPOrManager"));
    }

    function _onlyGP(uint caller) private view{
        address _gk = address(this);
        if( !_gk.getROM().isClassMember(caller, 1) ) 
            revert FundGMMK_WrongParty(bytes32("FundGMMK_NotGP"));
    }

    // ==== CreateMotion ====

    // ---- Officers ----
    function nominateDirector(
        uint256 seqOfPos,
        uint candidate
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 72000);

        _onlyGP(caller);

        _gk.getGMM().nominateOfficer(
            seqOfPos, 
            _gk.getROD().getPosition(seqOfPos).seqOfVR, 
            candidate, 
            caller
        );
    }

    function createMotionToRemoveDirector(
        uint256 seqOfPos
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 116000);

        if(!_gk.getROM().isMember(caller))
            revert FundGMMK_WrongParty(bytes32("FundGMMK_NotMember"));

        uint seqOfVR = _gk.getROD().getPosition(seqOfPos).seqOfVR;

        _gk.getGMM().createMotionToRemoveOfficer(
            seqOfPos, 
            seqOfVR, 
            caller
        );
    }

    function proposeDocOfGM(
        uint doc,
        uint seqOfVR,
        uint executor
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 116000);

        if(!_gk.getROM().isMember(caller))
            revert FundGMMK_WrongParty(bytes32("FundGMMK_NotMember"));

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToApproveDoc(doc, seqOfVR, executor, caller);
            
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, caller);

        if (seqOfVR < 9) {

            address addr = address(uint160(doc));

            if(!ISigPage(addr).isSigner(caller))
                revert FundGMMK_WrongParty(bytes32("FundGMMK_NotSignerOfDoc"));

            if(!ISigPage(addr).established())
                revert FundGMMK_WrongState(bytes32("FundGMMK_DocNotEstablished"));

            if (seqOfVR == 8) {
                _gk.getROC().proposeFile(addr, seqOfMotion);
            } else {
                _gk.getROA().proposeFile(addr, seqOfMotion);
            }
        }
    }

    function proposeToDistributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint seqOfDR,
        uint para,
        uint executor
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 68000);

        _gpOrManager(caller);

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToDistributeUsd(amt, expireDate, seqOfVR, seqOfDR, para, executor, caller);
            
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 99000);

        _gpOrManager(caller);        

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToTransferFund(to, isCBP, amt, expireDate, seqOfVR, executor, caller);

        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 99000);

        _gpOrManager(caller);

        _gk.getGMM().createAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            caller
        );
    }

    // ==== ProposeMotion ====

    function entrustDelegaterForGeneralMeeting(
        uint256 seqOfMotion,
        uint delegate
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        _avoidanceCheck(_gk, seqOfMotion, caller);

        _gk.getGMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 72000);

        _gk.getGMM().proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 72000);

        _avoidanceCheck(_gk, seqOfMotion, caller);

        _gk.getGMM().castVoteInGeneralMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(address _gk, uint256 seqOfMotion, uint caller) private view {
        MotionsRepo.Motion memory motion = _gk.getGMM().getMotion(seqOfMotion);

        if (motion.votingRule.class != 0 &&
            !_gk.getROM().isClassMember(caller, motion.votingRule.class)) {
            revert FundGMMK_WrongParty(bytes32("FundGMMK_NotClassMember"));
        }

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc) && 
            motion.head.seqOfVR < 9) 
        {
            address doc = address(uint160(motion.contents));
            if (ISigPage(doc).isSigner(caller)) {
                revert FundGMMK_WrongParty(bytes32("FundGMMK_IsSignerOfDoc"));
            }
        }
    }

    // ==== VoteCounting ====

    function voteCountingOfGM(uint256 seqOfMotion) external onlyDK {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 88000);

        _voteCountingOfGM(_gk, seqOfMotion);
    }    

    function _voteCountingOfGM(address _gk, uint256 seqOfMotion) private {
        IRegisterOfMembers _rom = _gk.getROM();
        IMeetingMinutes _gmm = _gk.getGMM();

        MotionsRepo.Motion memory motion =
            _gmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;

        BallotsBox.Case memory case0 = _gmm.getCaseOfAttitude(motion.head.seqOfMotion, 0);

        if (_allConsent(_gmm, _rom, motion, case0)) {
            base.unaniConsent = true;
        } else {
            base = _calBase(_gk, _gmm, _rom, motion, base, case0);
        }

        bool quorumFlag = (address(_gk.getSHA()) == address(0) ||
            base.attendWeightRatio >=
            _gk.getSHA().getRule(0).governanceRuleParser().quorumOfGM);

        bool approved = _gmm.voteCounting(quorumFlag, seqOfMotion, base) ==
            uint8(MotionsRepo.StateOfMotion.Passed);

        if (motion.head.seqOfVR < 9) {
            address doc = address(uint160(motion.contents));

            if (motion.head.seqOfVR == 8) {
                _gk.getROC().voteCountingForFile(doc, approved);
            } else {
                _gk.getROA().voteCountingForFile(doc, approved);
            }
        }
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
        address _gk,
        IMeetingMinutes _gmm,
        IRegisterOfMembers _rom,
        MotionsRepo.Motion memory motion,
        MotionsRepo.VoteCalBase memory base,
        BallotsBox.Case memory case0
    ) private view returns (MotionsRepo.VoteCalBase memory) {
        BallotsBox.Case memory case3 = _gmm.getCaseOfAttitude(motion.head.seqOfMotion, 3);

        uint64 votesOfMembers;
        if (motion.votingRule.class == 0) {
            votesOfMembers = _rom.totalVotes();
        } else {
            SharesRepo.Share memory classInfo =
                _gk.getROS().getInfoOfClass(motion.votingRule.class);
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

    // ==== ExecAction ====

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external onlyDK {
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        _execActionOfGM(
            caller,
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion
        );
    }

    function _execActionOfGM(
        uint caller,
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) public {
        if(
            targets.length != values.length || targets.length != params.length
        ) {
            revert FundGMMK_WrongInput(bytes32("FundGMMK_InputLenMismatch"));
        }

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

}

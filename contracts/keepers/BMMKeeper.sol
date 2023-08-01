// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IBODKeeper.sol";

contract BMMKeeper is IBMMKeeper, AccessControl {
    using RulesParser for bytes32;

    

    //##################
    //##   Modifier   ##
    //##################

    modifier directorExist(uint256 acct) {
        require(_getGK().getBOD().isDirector(acct), 
            "BODK.DE: not director");
        _;
    }

    //###############
    //##   Write   ##
    //###############

    // ==== CreateMotion ====

    // ---- Officers ----

    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IBookOfDirectors _bod = _gk.getBOD();
        
        require(_bod.hasNominationRight(seqOfPos, nominator),
            "BMMKeeper.nominateOfficer: no rights");
     
        _gk.getBMM().nominateOfficer(seqOfPos, _bod.getPosition(seqOfPos).seqOfVR, candidate, nominator);
    }

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint nominator
    ) external onlyDK directorExist(nominator) {
        IGeneralKeeper _gk = _getGK();
        IBookOfDirectors _bod = _gk.getBOD();
        
        require(_bod.hasNominationRight(seqOfPos, nominator),
            "BODK.createMotionToRemoveOfficer: no rights");

        _gk.getBMM().createMotionToRemoveOfficer(seqOfPos, _bod.getPosition(seqOfPos).seqOfVR, nominator);
    }

    // ---- Docs ----

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDK directorExist(proposer) {
        _getGK().getBMM().createMotionToApproveDoc(doc, seqOfVR, executor, proposer);
    }

    // ---- Actions ----

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external onlyDK directorExist(proposer){
        _getGK().getBMM().createAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            proposer
        );
    }

    // ==== Cast Vote ====

    function entrustDelegaterForBoardMeeting(
        uint256 seqOfMotion,
        uint delegate,
        uint caller
    ) external onlyDK directorExist(caller) {
        _avoidanceCheck(seqOfMotion, caller);
        _getGK().getBMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external onlyDK directorExist(caller) {
        _getGK().getBMM().proposeMotionToBoard(seqOfMotion, caller);
    }

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK {
        _avoidanceCheck(seqOfMotion, caller);
        _getGK().getBMM().castVoteInBoardMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint256 caller) private view {
        IGeneralKeeper _gk = _getGK();

        MotionsRepo.Motion memory motion = _gk.getBMM().getMotion(seqOfMotion);

        if (motion.head.typeOfMotion == 
                uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
        {
            address doc = address(uint160(motion.contents));
            
            OfficersRepo.Position[] memory poses = 
                _gk.getBOD().getFullPosInfoInHand(caller);
            uint256 len = poses.length;            
            while (len > 0) {
                require (!ISigPage(doc).isSigner(poses[len-1].nominator), 
                    "BODK.RPC: is related party");
                len --;
            }
            require (!ISigPage(doc).isSigner(caller), 
                "BODK.RPC: is related party");

        }
    }

    // ==== Vote Counting ====

    function voteCounting(uint256 seqOfMotion)
        external onlyDK
    {
        IGeneralKeeper _gk = _getGK();

        IBookOfDirectors _bod = _gk.getBOD();
        IMeetingMinutes _bmm = _gk.getBMM();
        
        MotionsRepo.Motion memory motion = 
            _bmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;
        BallotsBox.Case memory case0 = _bmm.getCaseOfAttitude(seqOfMotion, 0);

        uint32 numOfDirectors = uint32(_bod.getNumOfDirectors());
        base.attendHeadRatio = uint16(case0.sumOfHead * 10000 / numOfDirectors);

        if (motion.votingRule.onlyAttendance) {
            base.totalHead = _bmm.getCaseOfAttitude(seqOfMotion, 0).sumOfHead;
        } else {
            base.totalHead = numOfDirectors;
            if (motion.votingRule.impliedConsent) {
                base.supportHead = (base.totalHead - case0.sumOfHead);

                base.attendHeadRatio = 10000;                
            }

            if (motion.head.typeOfMotion == 
                uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
            {
                uint256[] memory parties = 
                    ISigPage((address(uint160(motion.contents)))).getParties();
                uint256 len = parties.length;

                while (len > 0) {
                    uint32 voteHead = 
                        uint32(_bod.getBoardSeatsOccupied(uint40(parties[len - 1])));

                    if (voteHead > 0) {
                        if (motion.votingRule.partyAsConsent) {
                            if (!motion.votingRule.impliedConsent) {
                                base.supportHead += voteHead;

                                base.attendHeadRatio += uint16(voteHead * 10000 / numOfDirectors);
                            }
                        } else {
                            base.totalHead -= voteHead;
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
        }

        IShareholdersAgreement _sha = _gk.getSHA();

        bool quorumFlag = (address(_sha) == address(0) || 
            base.attendHeadRatio >= 
            _sha.getRule(0).governanceRuleParser().quorumOfBoardMeeting);

        _bmm.voteCounting(quorumFlag, seqOfMotion, base);
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external directorExist(caller) returns (uint) {
        return _getGK().getBMM().execAction(
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

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IBODKeeper.sol";

contract BODKeeper is IBODKeeper, AccessControl {
    using RulesParser for bytes32;

    //##################
    //##   Modifier   ##
    //##################

    modifier directorExist(uint256 acct) {
        require(_gk.getBOD().isDirector(acct), 
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
    ) external onlyDirectKeeper {

        IBookOfDirectors _bod = _gk.getBOD();

        OfficersRepo.Position memory pos =
            _bod.getPosition(seqOfPos);

        require(_bod.hasNominationRight(seqOfPos, nominator),
            "BODKeeper.nominateOfficer: has no nominationRight");

        // if (pos.nominator == 0)
        //     require(_bod.hasTitle(nominator, pos.titleOfNominator),
        //     "BODK.nominateOfficer: has no nomination right");
        // else require( pos.nominator == nominator, 
        //     "BODK.nominateOfficer: has no nomination right");
         
        _bod.nominateOfficer(seqOfPos, pos.seqOfVR, candidate, nominator);
        // _bod.proposeMotion(seqOfMotion, nominator);
    }

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint nominator
    ) external onlyDirectKeeper directorExist(nominator) {
        IBookOfDirectors _bod = _gk.getBOD();

        OfficersRepo.Position memory pos =
            _bod.getPosition(seqOfPos);

        // if (pos.nominator == 0)
        require(_bod.hasNominationRight(seqOfPos, nominator),
            "BODK.createMotionToRemoveOfficer: has no right");
        // else require( pos.nominator == nominator, 
        //     "BODK.nominateOfficer: has no nomination right");

        _bod.createMotionToRemoveOfficer(seqOfPos, pos.seqOfVR, nominator);
        // _bod.proposeMotion(seqOfMotion, nominator);
    }

    // ---- Docs ----

    function createMotionToApproveDoc(
        address doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDirectKeeper directorExist(proposer) {
        _gk.getBOD().createMotionToApproveDoc(doc, seqOfVR, executor, proposer);
        // _bod.proposeMotion(seqOfMotion, proposer);
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
    ) external onlyDirectKeeper directorExist(proposer){
        _gk.getBOD().createAction(
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
    ) external onlyDirectKeeper {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBOD().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external onlyDirectKeeper directorExist(caller) {
        _gk.getBOD().proposeMotionToBoard(seqOfMotion, caller);
    }

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBOD().castVoteInBoardMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint256 caller) private view {
        MotionsRepo.Motion memory motion = _gk.getBOD().getMotion(seqOfMotion);

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

    function voteCounting(uint256 seqOfMotion, uint256 caller)
        external onlyDirectKeeper directorExist(caller)
    {
        IBookOfDirectors _bod = _gk.getBOD();

        MotionsRepo.Motion memory motion = 
            _bod.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;
        BallotsBox.Case memory case0 = _bod.getCaseOfAttitude(seqOfMotion, 0);

        uint32 numOfDirectors = uint32(_bod.getNumOfDirectors());
        base.attendHeadRatio = uint16(case0.sumOfHead * 10000 / numOfDirectors);

        if (motion.votingRule.onlyAttendance) {
            base.totalHead = _bod.getCaseOfAttitude(seqOfMotion, 0).sumOfHead;
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

        bool quorumFlag = (address(_gk.getSHA()) == address(0)|| 
            base.attendHeadRatio >= 
            _gk.getSHA().getRule(0).governanceRuleParser().quorumOfBoardMeeting);

        _bod.voteCounting(quorumFlag, seqOfMotion, base);
    }

    // ==== Exec Motion ====

    function takePosition(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external onlyDirectKeeper {

        IBookOfDirectors _bod = _gk.getBOD(); 
    
        require(_bod.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer), 
            "BODK.TO: not a suitable motion");

        _bod.execResolution(seqOfMotion, seqOfPos, caller);
        _bod.takePosition(seqOfPos, caller);
    }

    function quitPosition(uint256 seqOfPos, uint caller)
        external onlyDirectKeeper 
    {
        _gk.getBOD().quitPosition(seqOfPos, caller);
    }

    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external onlyDirectKeeper {
        IBookOfDirectors _bod = _gk.getBOD();
        
        require(_bod.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer), 
            "BODK.TO: not a suitable motion");

        _bod.execResolution(seqOfMotion, seqOfPos, caller);
        _bod.removeOfficer(seqOfPos);        
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
        return _gk.getBOD().execAction(
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

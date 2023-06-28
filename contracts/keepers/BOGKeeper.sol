// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOGKeeper.sol";

import "../common/access/AccessControl.sol";

contract BOGKeeper is IBOGKeeper, AccessControl {
    using RulesParser for bytes32;

    modifier memberExist(uint256 acct) {
        require(_gk.getROM().isMember(acct), 
            "BOGK.mf: NOT Member");
        _;
    }

    modifier memberOrDirector(uint256 acct) {
        require(_gk.getROM().isMember(acct) ||
            _gk.getBOD().isDirector(acct), 
            "BOGK.mf: not Member or Director");
        _;
    }

    // ################
    // ##   Motion   ##
    // ################

    // ==== CreateMotion ====

    // ---- Officers ----
    function nominateDirector(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external onlyDirectKeeper memberOrDirector(nominator) {

        OfficersRepo.Position memory pos =
            _gk.getBOD().getPosition(seqOfPos);

        require(pos.nominator == 0 || 
            pos.nominator == nominator, 
            "BOGK.ND: has no nominationRight");

        _gk.getBOG().nominateOfficer(seqOfPos, pos.seqOfVR, candidate, nominator);
    }

    function createMotionToRemoveDirector(
        uint256 seqOfPos,
        uint caller
    ) external onlyDirectKeeper memberOrDirector(caller) {
        OfficersRepo.Position memory pos =
            _gk.getBOD().getPosition(seqOfPos);

        require(pos.nominator == 0 || 
            pos.nominator == caller, 
            "BOGK.PTRD: has no nominationRight");

        IBookOfGM _bog = _gk.getBOG();

        _bog.createMotionToRemoveOfficer(seqOfPos, pos.seqOfVR, caller);
    }

    function proposeDocOfGM(
        address doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDirectKeeper memberExist(proposer) {

        IBookOfGM _bog = _gk.getBOG();

        uint64 seqOfMotion = 
            _bog.createMotionToApproveDoc(doc, seqOfVR, executor, proposer);

        if (seqOfVR < 9 && 
            ISigPage(doc).isSigner(proposer)
        ) { 
            _bog.proposeMotionToGeneralMeeting(seqOfMotion, proposer);            
            seqOfVR == 8 ?
                _gk.getBOH().proposeFile(doc, seqOfMotion) :
                _gk.getBOA().proposeFile(doc, seqOfMotion);
        }
    }

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external onlyDirectKeeper memberOrDirector(proposer) {
        _gk.getBOG().createAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            proposer
        );
    }

    // ==== ProposeMotion ====

    function entrustDelegaterForGeneralMeeting(
        uint256 seqOfMotion,
        uint delegate,
        uint caller
    ) external onlyDirectKeeper {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBOG().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        uint caller
    ) external onlyKeeper {
        _gk.getBOG().proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBOG().castVoteInGeneralMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint256 caller) private view {
        MotionsRepo.Motion memory motion = _gk.getBOG().getMotion(seqOfMotion);

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
        {
            address doc = address(uint160(motion.contents));
            require (!ISigPage(doc).isSigner(caller),
                "BOGK.AC: is related party");
        }
    }

    // ==== VoteCounting ====

    function voteCountingOfGM(uint256 seqOfMotion, uint256 caller)
        external onlyDirectKeeper memberExist(caller)
    {
        IBookOfGM _bog = _gk.getBOG();
        IRegisterOfMembers _rom = _gk.getROM();

        MotionsRepo.Motion memory motion = 
            _bog.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;
        BallotsBox.Case memory case0 = _bog.getCaseOfAttitude(seqOfMotion, 0);

        uint64 votesOfMembers = _rom.basedOnPar() 
            ? _rom.capAtDate(motion.body.shareRegDate).par
            : _rom.capAtDate(motion.body.shareRegDate).paid;

        base.attendWeightRatio = uint16(case0.sumOfWeight * 10000 / votesOfMembers);

        if (motion.votingRule.onlyAttendance) {
            base.totalHead = case0.sumOfHead;
            base.totalWeight = case0.sumOfWeight;
        } else {
            base.totalHead = _rom.getNumOfMembers();
            base.totalWeight = votesOfMembers; 
            if (motion.votingRule.impliedConsent) {
                base.supportHead = (base.totalHead - case0.sumOfHead);
                base.supportWeight = (base.totalWeight - case0.sumOfWeight);

                base.attendWeightRatio = 10000;                
            }

            if (motion.head.typeOfMotion == 
                    uint8(MotionsRepo.TypeOfMotion.ApproveDoc))
            {
                uint256[] memory parties = 
                    ISigPage((address(uint160(motion.contents)))).getParties();
                uint256 len = parties.length;

                while (len > 0) {
                    uint64 votesAtDate = 
                        _rom.votesAtDate(parties[len - 1], motion.body.shareRegDate);

                    if (votesAtDate > 0) {
                        if (motion.votingRule.partyAsConsent) {
                            if (!motion.votingRule.impliedConsent) {
                                base.supportHead ++;
                                base.supportWeight += votesAtDate;

                                base.attendWeightRatio += uint16(votesAtDate * 10000 / votesOfMembers);
                            }
                        } else {
                            base.totalHead --;
                            base.totalWeight -= votesAtDate;
                            if (motion.votingRule.impliedConsent) {
                                base.supportHead --;
                                base.supportWeight -= votesAtDate;
                            } else {
                                base.attendWeightRatio += uint16(votesAtDate * 10000 / votesOfMembers);
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
            base.attendWeightRatio >= 
            _gk.getSHA().getRule(0).governanceRuleParser().quorumOfGM);

        bool approved = _bog.voteCounting(quorumFlag, seqOfMotion, base) == 
            uint8(MotionsRepo.StateOfMotion.Passed);

        if (motion.head.seqOfVR < 9) {

            address doc = address(uint160(motion.contents));

            if (motion.head.seqOfVR == 8)
                _gk.getBOH().voteCountingForFile(doc, approved);
            else _gk.getBOA().voteCountingForFile(doc, approved);
        }
    }

    // ==== execute ====

    function takeSeat(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external onlyDirectKeeper {

        IBookOfGM _bog = _gk.getBOG();
        
        require(_bog.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer), 
            "BOGK.TS: not a suitable motion");

        _bog.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getBOD().takePosition(seqOfPos, caller);
    }

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external onlyDirectKeeper {
        IBookOfGM _bog = _gk.getBOG();

        require(_bog.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer), 
            "BOGK.RD: not a suitable motion");

        _bog.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getBOD().removeOfficer(seqOfMotion, seqOfPos, caller);        
    }

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns (uint){
        return _gk.getBOG().execAction(
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

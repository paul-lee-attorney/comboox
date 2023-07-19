// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IGMMKeeper.sol";

import "../common/access/AccessControl.sol";

contract GMMKeeper is IGMMKeeper, AccessControl {
    using RulesParser for bytes32;

    

    modifier memberExist(uint256 acct) {
        require(_getGK().getBOM().isMember(acct), 
            "BOGK.mf: NOT Member");
        _;
    }

    modifier memberOrDirector(uint256 acct) {
        IGeneralKeeper _gk = _getGK();

        require(_gk.getBOM().isMember(acct) ||
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
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();

        IBookOfDirectors _bod = _gk.getBOD();

        require(_bod.hasNominationRight(seqOfPos, nominator),
            "BODKeeper.nominateOfficer: has no nominationRight");

        _gk.getGMM().nominateOfficer(
            seqOfPos, 
            _bod.getPosition(seqOfPos).seqOfVR, 
            candidate, 
            nominator
        );
    }

    function createMotionToRemoveDirector(
        uint256 seqOfPos,
        uint caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();

        IBookOfDirectors _bod = _gk.getBOD();

        require(_bod.hasNominationRight(seqOfPos, caller),
            "BODKeeper.nominateOfficer: has no nominationRight");

        _gk.getGMM().createMotionToRemoveOfficer(
            seqOfPos, 
            _bod.getPosition(seqOfPos).seqOfVR, 
            caller
        );
    }

    function proposeDocOfGM(
        address doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDK memberExist(proposer) {
        IGeneralKeeper _gk = _getGK();

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToApproveDoc(doc, seqOfVR, executor, proposer);

        if (seqOfVR < 9 && 
            ISigPage(doc).isSigner(proposer)
        ) { 
            _gmm.proposeMotionToGeneralMeeting(seqOfMotion, proposer);            
            seqOfVR == 8 ?
                _gk.getBOC().proposeFile(doc, seqOfMotion) :
                _gk.getBOI().proposeFile(doc, seqOfMotion);
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
    ) external onlyDK memberOrDirector(proposer) {
        _getGK().getGMM().createAction(
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
    ) external onlyDK {
        _avoidanceCheck(seqOfMotion, caller);
        _getGK().getGMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        uint caller
    ) external onlyKeeper {
        _getGK().getGMM().proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK {
        _avoidanceCheck(seqOfMotion, caller);
        _getGK().getGMM().castVoteInGeneralMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint256 caller) private view {
        MotionsRepo.Motion memory motion = _getGK().getGMM().getMotion(seqOfMotion);

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
        {
            address doc = address(uint160(motion.contents));
            require (!ISigPage(doc).isSigner(caller),
                "BOGK.AC: is related party");
        }
    }

    // ==== VoteCounting ====

    function voteCountingOfGM(uint256 seqOfMotion) external onlyDK {
        IGeneralKeeper _gk = _getGK();

        IBookOfMembers _bom = _gk.getBOM();
        IMeetingMinutes _gmm = _gk.getGMM();

        MotionsRepo.Motion memory motion = 
            _gmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;
        BallotsBox.Case memory case0 = _gmm.getCaseOfAttitude(seqOfMotion, 0);

        uint64 votesOfMembers = _bom.basedOnPar() 
            ? _bom.capAtDate(motion.body.shareRegDate).par
            : _bom.capAtDate(motion.body.shareRegDate).paid;

        base.attendWeightRatio = uint16(case0.sumOfWeight * 10000 / votesOfMembers);

        if (motion.votingRule.onlyAttendance) {
            base.totalHead = case0.sumOfHead;
            base.totalWeight = case0.sumOfWeight;
        } else {
            base.totalHead = _bom.getNumOfMembers();
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
                        _bom.votesAtDate(parties[len - 1], motion.body.shareRegDate);

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

        bool approved = _gmm.voteCounting(quorumFlag, seqOfMotion, base) == 
            uint8(MotionsRepo.StateOfMotion.Passed);

        if (motion.head.seqOfVR < 9) {

            address doc = address(uint160(motion.contents));

            if (motion.head.seqOfVR == 8)
                _gk.getBOC().voteCountingForFile(doc, approved);
            else _gk.getBOI().voteCountingForFile(doc, approved);
        }
    }

    // ==== execute ====

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns (uint){
        return _getGK().getGMM().execAction(
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

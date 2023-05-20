// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOGKeeper.sol";

// import "../books/boa/IInvestmentAgreement.sol";

import "../common/access/AccessControl.sol";

contract BOGKeeper is IBOGKeeper, AccessControl {
    using RulesParser for bytes32;

    modifier memberExist(uint256 acct) {
        require(_gk.getROM().isMember(acct), 
            "BOGK.mf.ME: NOT Member");
        _;
    }

    // ######################
    // ##   Corp Setting   ##
    // ######################

    // function createCorpSeal(uint info) external onlyDirectKeeper {
    //     _gk.getBOG().createCorpSeal(info);
    // }

    // function createBoardSeal(address board) external onlyDirectKeeper {
    //     _gk.getBOG().createBoardSeal(board);
    // }

    // ################
    // ##   Motion   ##
    // ################

    // ==== CreateMotion ====

    // ---- Officers ----
    function nominateDirector(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external onlyDirectKeeper memberExist(nominator) {

        OfficersRepo.Position memory pos =
            _gk.getBOD().getPosition(seqOfPos);

        // require (pos.title <= uint8(OfficersRepo.TitleOfOfficers.Director),
        //     "BOGK.ND: not a Director's position");

        require(pos.nominator == 0 || 
            pos.nominator == nominator, 
            "BOGK.ND: has no nominationRight");

        uint64 seqOfMotion = 
            _gk.getBOG().nominateOfficer(seqOfPos, pos.seqOfVR, candidate, nominator);
        _gk.getBOG().proposeMotion(seqOfMotion, nominator);
    }

    function proposeToRemoveDirector(
        uint256 seqOfPos,
        uint caller
    ) external onlyDirectKeeper memberExist(caller) {

        OfficersRepo.Position memory pos =
            _gk.getBOD().getPosition(seqOfPos);

        // require (pos.title <= uint8(OfficersRepo.TitleOfOfficers.Director),
        //     "BOGK.PTRD: not a Director's position");

        require(pos.nominator == 0 || 
            pos.nominator == caller, 
            "BOGK.PTRD: has no nominationRight");

        IBookOfGM _bog = _gk.getBOG();

        uint64 seqOfMotion = 
            _bog.proposeToRemoveOfficer(seqOfPos, pos.seqOfVR, caller);
        if (pos.nominator > 0) _bog.proposeMotion(seqOfMotion, caller);       
    }

    function proposeDocOfGM(
        address doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDirectKeeper memberExist(proposer) {

        IBookOfGM _bog = _gk.getBOG();

        uint64 seqOfMotion = 
            _bog.proposeDoc(doc, seqOfVR, executor, proposer);

        if (seqOfVR <= 8 && 
            ISigPage(doc).isSigner(proposer)
        ) { 
            _bog.proposeMotion(seqOfMotion, proposer);
            IShareholdersAgreement _sha = _gk.getSHA();
            RulesParser.VotingRule memory vr =
                address(_sha) == address(0)
                ? RulesParser.SHA_INIT_VR.votingRuleParser()
                : _sha.getRule(seqOfVR).votingRuleParser();
            
            seqOfVR == 8 ?
                _gk.getBOH().proposeFile(doc, vr) :
                _gk.getBOA().proposeFile(doc, vr);
        }
    }

    function proposeActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external onlyDirectKeeper memberExist(proposer) {
        _gk.getBOG().proposeAction(
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

    function entrustDelegateOfMember(
        uint256 seqOfMotion,
        uint delegate,
        uint caller
    ) external onlyDirectKeeper memberExist(caller) memberExist(delegate) {
        _avoidanceCheck(seqOfMotion, caller);

        IBookOfGM _bog = _gk.getBOG();

        uint64 weight;
        uint48 shareRegDate = _bog.getMotion(seqOfMotion).body.shareRegDate;

        if (shareRegDate > 0)
            weight = _gk.getROM().votesAtDate(caller, shareRegDate);

        _bog.entrustDelegate(seqOfMotion, delegate, caller, weight);
    }

    function proposeMotionOfGM(
        uint256 seqOfMotion,
        uint caller
    ) external onlyKeeper memberExist(caller) {

        IBookOfGM _bog = _gk.getBOG();

        uint16 threshold = _gk.getSHA().getRule(0).governanceRuleParser().proposeWeightRatioOfGM;

        require (_bog.getVoterOfDelegateMap(seqOfMotion, caller).delegate == 0, 
            "BOGK.PM: has entrust delegate");

        IRegisterOfMembers _rom = _gk.getROM();

        uint64 totalVotes = _rom.totalVotes(); 
        uint64 weightOfProposer = 
            _bog.getLeavesWeightAtDate(seqOfMotion, caller, uint48(block.timestamp), _rom);

        require(weightOfProposer / totalVotes >= threshold,
            "BOGK.PM: not reached proposal threshold");

        _bog.proposeMotion(seqOfMotion, caller);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper memberExist(caller) {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBOG().castVote(seqOfMotion, attitude, sigHash, _gk.getROM(), caller);
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

        if (motion.votingRule.onlyAttendance) {
            base.totalHead = case0.sumOfHead;
            base.totalWeight = case0.sumOfWeight;
        } else {
            base.totalHead = _rom.getNumOfMembers();
            base.totalWeight = _rom.basedOnPar() ?
                _rom.capAtDate(motion.body.shareRegDate).par:
                _rom.capAtDate(motion.body.shareRegDate).paid;
            if (motion.votingRule.impliedConsent) {
                base.supportHead = (base.totalHead - case0.sumOfHead);
                base.supportWeight = (base.totalWeight - case0.sumOfWeight);                
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
                            }
                        } else {
                            base.totalHead --;
                            base.totalWeight -= votesAtDate;
                            if (motion.votingRule.impliedConsent) {
                                base.supportHead --;
                                base.supportWeight -= votesAtDate;
                            }
                        }
                    }

                    len--;
                }                
            }
        }

        bool approved = _bog.voteCounting(seqOfMotion, base) == 
            uint8(MotionsRepo.StateOfMotion.Passed);
        address doc = address(uint160(motion.contents));

        motion.head.seqOfVR == 8 ?
            _gk.getBOH().voteCountingForFile(doc, approved) :
            _gk.getBOA().voteCountingForFile(doc, approved);
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
        uint director,
        uint caller
    ) external onlyDirectKeeper {
        IBookOfGM _bog = _gk.getBOG();

        require(_bog.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer), 
            "BOGK.RD: not a suitable motion");

        _bog.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getBOD().removeOfficer(seqOfMotion, seqOfPos, director, caller);        
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

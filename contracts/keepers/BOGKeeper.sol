// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOGKeeper.sol";

import "../books/boa/IInvestmentAgreement.sol";
import "../books/boo/BookOfOptions.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOGSetting.sol";
import "../common/ruting/BOHSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/ROMSetting.sol";

// import "../common/lib/SNFactory.sol";
// import "../common/lib/SNParser.sol";
import "../common/lib/MotionsRepo.sol";
import "../common/lib/RulesParser.sol";

import "../common/components/IRepoOfDocs.sol";
import "../common/components/ISigPage.sol";

contract BOGKeeper is
    IBOGKeeper,
    BOASetting,
    BODSetting,
    BOGSetting,
    BOHSetting,
    BOOSetting,
    BOSSetting,
    ROMSetting,
    AccessControl
{
    using RulesParser for bytes32;
    // using SNFactory for bytes;
    // using SNParser for bytes32;

    // ######################
    // ##   Corp Setting   ##
    // ######################

    function createCorpSeal() external onlyDirectKeeper {
        _getBOG().createCorpSeal();
    }

    function createBoardSeal() external onlyDirectKeeper {
        _getBOG().createBoardSeal(address(_getBOD()));
    }

    // ################
    // ##   Motion   ##
    // ################

    // ==== propose ====

    function nominateOfficer(
        uint256 seqOfBSR, 
        uint256 seqOfTitle, 
        uint256 nominator, 
        uint256 candidate
    ) external onlyDirectKeeper memberExist(nominator){
        RulesParser.BoardSeatsRule memory bsr = 
            _getSHA().getRule(seqOfBSR).boardSeatsRuleParser();

        require(bsr.rightholder == nominator, "BOGK.NO: caller not rightholder");
        require(_getBOD().boardSeatsOf(nominator) > bsr.qtyOfBoardSeats, 
            "BOGK.NO: board has no seats");

        uint256 seqOfVR = bsr.vrSeqOfNomination[seqOfTitle];
        uint8 title = bsr.nominationTitle[seqOfTitle];

        if (seqOfVR <= 10) _getBOG().nominateOfficer(seqOfVR, title, nominator, candidate);
        else _getBOD().nominateOfficer(seqOfVR, title, nominator, candidate);
    }

    function proposeDoc(address doc, uint256 seqOfVR, uint256 caller)
        external
        onlyDirectKeeper
        memberExist(caller)
    {
        // ISigPage _page = ISigPageSetting(doc).getSigPage();
        require(ISigPage(doc).isParty(caller), "BOGK.PD: NOT Party of Doc");

        IRepoOfDocs rod;
        if (seqOfVR != 8 && seqOfVR != 18) rod = _getBOA();
        else if (seqOfVR == 8 || seqOfVR == 18) rod = _getBOH();

        IRepoOfDocs.Head memory headOfDoc = rod.getHeadOfDoc(doc);

        require(
            headOfDoc.state == uint8(IRepoOfDocs.RODStates.Established),
            "BOGK.PD: doc not on Established"
        );

        require(
            headOfDoc.shaExecDeadline < block.timestamp,
            "BOGK.PM: IA not passed review procedure"
        );

        require(
            headOfDoc.proposeDeadline == headOfDoc.shaExecDeadline || 
            headOfDoc.proposeDeadline >= block.timestamp,
            "BOGK.PM: missed votingDeadline"
        );

        rod.setStateOfDoc(doc, uint8(IRepoOfDocs.RODStates.Proposed));

        _getBOG().proposeDoc(doc, seqOfVR, caller, 0);
    }


    function proposeAction(
        uint8 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 submitter,
        uint256 executor
    ) external onlyDirectKeeper memberExist(submitter) {
        _getBOG().proposeAction(
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            submitter,
            executor
        );
    }

    // ==== Delegate ====

    function entrustDelegate(
        uint256 actionId,
        uint256 caller,
        uint256 delegate
    ) external onlyDirectKeeper memberExist(caller) memberExist(delegate) {
        _getBOG().entrustDelegate(actionId, caller, delegate);
    }

    // ==== vote ====

    function castVote(
        uint256 motionId,
        uint256 caller,
        uint8 attitude,
        bytes32 sigHash
    ) external onlyDirectKeeper memberExist(caller) {
        _getBOG().castVote(motionId, caller, attitude, sigHash);
    }

    function voteCounting(uint256 motionId, uint256 caller)
        external
        onlyDirectKeeper
        memberExist(caller)
    {
        _getBOG().voteCounting(motionId);
    }

    // ==== execute ====

    function execAction(
        uint8 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 caller
    ) external returns (uint256) {
        require(_getBOD().isDirector(caller), "caller is not a Director");
        require(!_rc.isCOA(caller), "caller is not an EOA");
        return
            _getBOG().execAction(
                typeOfAction,
                targets,
                values,
                params,
                caller,
                desHash
            );
    }

    function requestToBuy(
        uint256 motionId,
        uint256 seqOfDeal,
        uint256 againstVoter,
        uint256 caller
    ) external onlyDirectKeeper {

        IInvestmentAgreement.Deal memory deal = IInvestmentAgreement(address(uint160(motionId))).getDeal(seqOfDeal);

        require(caller == deal.head.seller, "BOGKeeper.RTB: caller NOT Seller");

        MotionsRepo.Head memory m = _getBOG().getHeadOfMotion(motionId);

        require(
            m.state == uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy),
            "BOGKeeper.RTB: NO need to buy"
        );

        RulesParser.VotingRule memory vr = _getBOG().getVotingRuleOfMotion(motionId);

        require(block.timestamp < m.voteStartDate + (uint48(vr.votingDays) + uint48(vr.execDaysForPutOpt)) * 86400, 
            "BOGK.RTB: missed EXEC date");

        uint8 closingDays = uint8((deal.head.closingDate - uint48(block.timestamp) + 12 hours) / (24 hours));

        OptionsRepo.Head memory headOfOpt =
            OptionsRepo.Head({
                seqOfOpt: 0,
                typeOfOpt: uint8(OptionsRepo.OptTypes.PutPrice),
                rate: deal.head.price,
                triggerDate: uint48(block.timestamp),
                execDays: 1,
                closingDays: closingDays,
                classOfShare: deal.head.classOfShare,
                logicOperator: 0,
                compOperator1: 0,
                para1: 0,
                compOperator2: 0,
                para2: 0,
                state: 0
            });

        IBookOfOptions _boo = _getBOO();

        uint256 seqOfOpt = _boo.createOption(headOfOpt, caller, againstVoter, deal.body.paid, deal.body.par);

        IBookOfShares.Share memory share  = _getBOS().getShare(deal.head.seqOfShare);

        _boo.execOption(seqOfOpt);

        OptionsRepo.Future memory future = OptionsRepo.Future({
            seqOfFuture: 0,
            seqOfShare: deal.head.seqOfShare,
            buyer: uint40(againstVoter),
            paid: deal.body.paid,
            par: deal.body.par,
            state: 0
        });

        _boo.addFuture(seqOfOpt, share, future);
    }
}

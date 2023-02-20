// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boa/IInvestmentAgreement.sol";
// import "../books/boh/ShareholdersAgreement.sol";
import "../books/boo/BookOfOptions.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOHSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/ROMSetting.sol";

import "../common/lib/SNFactory.sol";
import "../common/lib/SNParser.sol";
import "../common/lib/MotionsRepo.sol";

import "../common/components/IRepoOfDocs.sol";

import "./IBOGKeeper.sol";

contract BOGKeeper is
    IBOGKeeper,
    BOASetting,
    BODSetting,
    BOHSetting,
    BOMSetting,
    BOOSetting,
    BOSSetting,
    ROMSetting
{
    using SNFactory for bytes;
    using SNParser for bytes32;

    // ######################
    // ##   Corp Setting   ##
    // ######################

    function createCorpSeal() external onlyDirectKeeper {
        _bog.createCorpSeal();
    }

    function createBoardSeal() external onlyDirectKeeper {
        _bog.createBoardSeal(address(_bod));
    }

    // ################
    // ##   Motion   ##
    // ################

    // ==== propose ====

    function nominateOfficer(
        bytes32 bsRule, 
        uint8 seqOfTitle, 
        uint40 nominator, 
        uint40 candidate
    ) external onlyDirectKeeper memberExist(nominator){
        require(bsRule.rightholderOfBSR() == nominator, "BOGK.NO: caller not rightholder");
        require(_bod.boardSeatsOf(nominator) > bsRule.qtyOfBoardSeats(), "BOGK.NO: board has no seats");

        uint16 seqOfVR = bsRule.vrSeqOfNomination(seqOfTitle);
        uint8 title = bsRule.nominateTitle(seqOfTitle);

        if (seqOfVR <= 10) _bog.nominateOfficer(seqOfVR, title, nominator, candidate);
        else _bod.nominateOfficer(seqOfVR, title, nominator, candidate);
    }

    function proposeDoc(address doc, uint8 seqOfVR, uint40 caller)
        external
        onlyDirectKeeper
        memberExist(caller)
    {
        IRepoOfDocs rod;
        if (seqOfVR > 0 && seqOfVR < 8) rod = IRepoOfDocs(_boa);
        else if (seqOfVR == 8) rod = IRepoOfDocs(_boh);
        else revert("BOGK.PD: wrong seqOfVR");

        require(
            rod.isParty(doc, caller),
            "BOGK.PD: NOT Party of Doc"
        );

        require(
            rod.getHeadOfDoc(doc).state == uint8(IRepoOfDocs.RODStates.Established),
            "BOGK.PD: doc not on Established"
        );

        IRepoOfDocs.Head memory headOfDoc = rod.getHeadOfDoc(doc);

        // uint48 shaExecDeadline = rod.getHeadOfDoc(doc).shaExecDeadline;
        // uint48 proposeDeadline = rod.getHeadOfDoc(doc).proposeDeadline;

        require(
            headOfDoc.shaExecDeadline < block.timestamp,
            "BOGKeeper.proposeMotion: IA not passed review procedure"
        );

        require(
            headOfDoc.proposeDeadline == headOfDoc.shaExecDeadline || headOfDoc.proposeDeadline >= block.timestamp,
            "missed votingDeadline"
        );

        rod.pushToNextState(doc);

        _bog.proposeDoc(doc, seqOfVR, caller, 0);
    }


    function proposeAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter,
        uint40 executor
    ) external onlyDirectKeeper memberExist(submitter) {
        _bog.proposeAction(
            actionType,
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
        uint40 caller,
        uint40 delegate
    ) external onlyDirectKeeper memberExist(caller) memberExist(delegate) {
        _bog.entrustDelegate(actionId, caller, delegate);
    }


    // ==== vote ====

    function castVote(
        uint256 motionId,
        uint40 caller,
        uint8 attitude,
        bytes32 sigHash
    ) external onlyDirectKeeper memberExist(caller) {
        _bog.castVote(motionId, caller, attitude, sigHash);
    }

    function voteCounting(uint256 motionId, uint40 caller)
        external
        onlyDirectKeeper
        memberExist(caller)
    {
        _bog.voteCounting(motionId);
        // if (address(_rod) > address(0)) _rod.pushToNextState(address(uint160(motionId)));
    }

    // ==== execute ====

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 caller
    ) external returns (uint256) {
        require(_bod.isDirector(caller), "caller is not a Director");
        require(!_rc.isCOA(caller), "caller is not an EOA");
        return
            _bog.execAction(
                actionType,
                targets,
                values,
                params,
                caller,
                desHash
            );
    }

    function requestToBuy(
        uint256 motionId,
        bytes32 snOfDeal,
        uint40 againstVoter,
        uint40 caller
    ) external onlyDirectKeeper {

        require(caller == snOfDeal.sellerOfDeal(), "BOGKeeper.RTB: caller NOT Seller");

        MotionsRepo.Head memory m = _bog.getHeadOfMotion(motionId);

        require(
            m.state == uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy),
            "BOGKeeper.RTB: NO need to buy"
        );

        bytes32 vr = _bog.getVotingRuleOfMotion(motionId);

        require(block.timestamp < m.voteStartDate + (vr.votingDaysOfVR() + vr.execDaysForPutOptOfVR()) * 86400, 
            "BOGKeeper.RTB: missed EXEC date");

        IInvestmentAgreement.Deal memory deal = IInvestmentAgreement(address(uint160(motionId))).getDeal(snOfDeal.seqOfDeal());

        uint8 closingDays = uint8((deal.closingDate - uint48(block.timestamp) + 12 hours) / (24 hours));

        bytes32 snOfOpt = _createOptSN(
            uint8(BookOfOptions.TypeOfOption.Put_Price),
            uint48(block.number),
            1,
            closingDays,
            snOfDeal.classOfDeal(),
            snOfDeal.priceOfDeal()
        );

        uint40[] memory obligors = new uint40[](1);
        obligors[0] = againstVoter;

        snOfOpt = _boo.createOption(snOfOpt, caller, obligors, deal.paid, deal.par);

        IBookOfShares.Share memory share  = _bos.getShare(snOfDeal.ssnOfDeal());

        _boo.execOption(snOfOpt);
        _boo.addFuture(snOfOpt, share.shareNumber, deal.paid, deal.par);
    }

    function _createOptSN(
        uint8 typeOfOpt,
        uint48 triggerDate,
        uint8 execDays,
        uint8 closingDays,
        uint16 classOfOpt,
        uint32 rateOfOpt
    ) private pure returns (bytes32 sn) {
        bytes memory _sn = new bytes(32);

        _sn[0] = bytes1(typeOfOpt);
        _sn = _sn.dateToSN(5, triggerDate);
        _sn[11] = bytes1(execDays);
        _sn[12] = bytes1(closingDays);
        _sn = _sn.seqToSN(13, classOfOpt);
        _sn = _sn.ssnToSN(15, rateOfOpt);

        sn = _sn.bytesToBytes32();
    }
}

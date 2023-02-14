// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import "./IBookOfMotions.sol";

import "../boa/IInvestmentAgreement.sol";

import "../../common/components/ISigPage.sol";
import "../../common/components/MeetingMinutes.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/MotionsRepo.sol";

contract BookOfMotions is IBookOfMotions, MeetingMinutes {
    using SNParser for bytes32;
    using MotionsRepo for MotionsRepo.Repo;

    enum TypeOfVoting {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STI,
        STE_STI,
        CI_STE_STI,
        CI_STE,
        OrdinaryIssuesOfGM,
        SpecialIssuesOfGM,
        OrdinaryIssuesOfBoard,
        SpecialIssuesOfBoard
    }

    bytes32 private _regNumHash;

    //##################
    //##    写接口    ##
    //##################

    // ==== Corp Register ====

    function createCorpSeal() external onlyDirectKeeper {
        _rc.regUser();
    }

    function createBoardSeal(address bod) external onlyDirectKeeper {
        _rc.setBackupKey(bod);
    }

    function setRegNumberHash(bytes32 numHash) external onlyDirectKeeper {
        _regNumHash = numHash;
        emit SetRegNumberHash(numHash);
    }

    // ==== propose ====

    function nominateDirector(uint40 candidate, uint40 nominator)
        external
        onlyDirectKeeper
    {
        bytes32 rule = _getSHA().getRule(
            uint8(TypeOfVoting.OrdinaryIssuesOfGM)
        );

        uint256 motionId = uint256(
            keccak256(
                abi.encode(rule, candidate, nominator, uint64(block.number))
            )
        );

        if (_mm.proposeMotion(motionId, rule, candidate))
            emit NominateDirector(motionId, candidate, nominator);
    }

    function proposeDoc(address doc, uint8 typeOfDoc, uint40 submitter) external onlyDirectKeeper {

        IRepoOfDocs rod;
        if (typeOfDoc < 8 && typeOfDoc > 0) rod = IRepoOfDocs(_boa);
        else if (typeOfDoc == 8) rod = IRepoOfDocs(_boh);
        else revert("BOMKeeper.pd: wrong doc type");

        uint256 motionId = (uint256(typeOfDoc) << 160) + uint256(uint160(doc));

        bytes32 rule = _getSHA().getRule(typeOfDoc);

        if (_mm.proposeMotion(motionId, rule, submitter))
            emit ProposeDoc(motionId, doc, submitter);
    }

    // ==== requestToBuy ====

    function requestToBuy(address ia, bytes32 sn)
        external
        view
        onlyDirectKeeper
        returns (uint64 paid, uint64 par)
    {
        require(
            block.timestamp <
                IInvestmentAgreement(ia).closingDateOfDeal(sn.seqOfDeal()),
            "MISSED closing date"
        );

        require(
            block.timestamp <
                _mm.motions[uint256(uint160(ia))].head.voteEndDate +
                    _mm
                        .motions[uint256(uint160(ia))]
                        .votingRule
                        .execDaysForPutOptOfVR() * 86400,
            "MISSED execute deadline"
        );

        (, paid, par, , ) = IInvestmentAgreement(ia).getDeal(sn.seqOfDeal());
    }

    //##################
    //##    读接口    ##
    //##################

    function regNumHash() external view returns (bytes32) {
        return _regNumHash;
    }

    function verifyRegNum(string memory regNum) external view returns (bool) {
        return _regNumHash == keccak256(bytes(regNum));
    }
}

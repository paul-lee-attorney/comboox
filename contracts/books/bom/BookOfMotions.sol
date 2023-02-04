// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import "./IBookOfMotions.sol";

import "../boa/IInvestmentAgreement.sol";

import "../../common/components/ISigPage.sol";
import "../../common/components/MeetingMinutes.sol";

import "../../common/ruting/BOASetting.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/MotionsRepo.sol";

contract BookOfMotions is IBookOfMotions, MeetingMinutes, BOASetting {
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

    function createCorpSeal() external onlyDK {
        _rc.regUser();
    }

    function createBoardSeal(address bod) external onlyDK {
        _rc.setBackupKey(bod);
    }

    function setRegNumberHash(bytes32 numHash) external onlyDK {
        _regNumHash = numHash;
        emit SetRegNumberHash(numHash);
    }

    // ==== propose ====

    function nominateDirector(uint40 candidate, uint40 nominator)
        external
        onlyDK
    {
        bytes32 rule = _getSHA().votingRules(
            uint8(TypeOfVoting.OrdinaryIssuesOfGM)
        );

        uint256 motionId = uint256(
            keccak256(
                abi.encode(rule, candidate, nominator, uint64(block.number))
            )
        );

        if (_mm.proposeMotion(motionId, rule, candidate, _rc.blocksPerHour()))
            emit NominateDirector(motionId, candidate, nominator);
    }

    function proposeIA(address ia, uint40 submitter) external onlyDK {
        require(ISigPage(ia).established(), "doc is not established");

        uint256 motionId = uint256(uint160(ia));

        uint8 motionType = IInvestmentAgreement(ia).typeOfIA();

        bytes32 rule = _getSHA().votingRules(motionType);

        if (_mm.proposeMotion(motionId, rule, submitter, _rc.blocksPerHour()))
            emit ProposeIA(motionId, ia, submitter);
    }

    // ==== requestToBuy ====

    function requestToBuy(address ia, bytes32 sn)
        external
        view
        onlyDK
        returns (uint64 paid, uint64 par)
    {
        require(
            block.timestamp + 15 minutes <
                IInvestmentAgreement(ia).closingDateOfDeal(sn.seqOfDeal()),
            "MISSED closing date"
        );

        require(
            block.number <
                _mm.motions[uint256(uint160(ia))].head.voteEndBN +
                    _mm
                        .motions[uint256(uint160(ia))]
                        .votingRule
                        .execDaysForPutOptOfVR() *
                    24 *
                    _rc.blocksPerHour(),
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

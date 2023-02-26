// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./InvestmentAgreement.sol";
import "./IInvestmentAgreement.sol";
import "./IBookOfIA.sol";

import "../../common/components/RepoOfDocs.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/FRClaims.sol";

import "../../common/ruting/BOHSetting.sol";
import "../../common/ruting/ROMSetting.sol";

contract BookOfIA is IBookOfIA, BOHSetting, ROMSetting, RepoOfDocs {
    using SNParser for bytes32;
    using FRClaims for FRClaims.Claims;

    // ia => frd
    mapping(address => FRClaims.Claims) private _frClaims;

    // ia => mockResults
    mapping(address => address) private _mockResults;

    //#################
    //##  Write I/O  ##
    //#################

    function circulateIA(
        address ia, 
        bytes32 docUrl, 
        bytes32 docHash
    ) external onlyDirectKeeper {
        uint256 typeOfIA = IInvestmentAgreement(ia).typeOfIA();
        bytes32 votingRule = _getSHA().getRule(typeOfIA);
        circulateDoc(ia, votingRule, docUrl, docHash);
    }

    // ==== FirstRefusal ====

    function execFirstRefusalRight(
        address ia,
        uint16 seqOfDeal,
        uint40 caller
    ) external onlyKeeper returns (bool flag) {
        if (_frClaims[ia].execFirstRefusalRight(seqOfDeal, caller))
        {
            setStateOfDoc(ia, uint8(RODStates.Circulated));
            flag = true;
        }
    }

    function acceptFirstRefusalClaims(
        address ia,
        uint16 seqOfDeal
    ) external onlyKeeper returns (FRClaims.Claim[] memory output) {
        IRegisterOfMembers rom = _getROM();
        output = _frClaims[ia].acceptFirstRefusalClaims(seqOfDeal, rom);
    }

    function createMockResults(address ia, uint40 creator)
        external
        onlyKeeper
        returns (address mock)
    {
        if (_mockResults[ia] == address(0)) {
            (mock, ) = createDoc(uint8(TypeOfDoc.MockResults), creator);
        }
    }

    //#################
    //##    读接口    ##
    //#################

    function claimsOfFR(address ia, uint256 seqOfDeal)
        external view returns(FRClaims.Claim[] memory) 
    {
        return _frClaims[ia].claimsOfFR(seqOfDeal);
    }

    function mockResultsOfIA(address ia) external view returns (address) {
        return _mockResults[ia];
    }
}

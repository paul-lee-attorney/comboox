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

import "../../common/ruting/BOHSetting.sol";

contract BookOfIA is IBookOfIA, BOHSetting, RepoOfDocs {
    using SNParser for bytes32;

    // ia => frd
    mapping(address => address) private _frDeals;

    // ia => mockResults
    mapping(address => address) private _mockResults;

    //#################
    //##  Write I/O  ##
    //#################

    function circulateIA(address ia, bytes32 docUrl, bytes32 docHash) external onlyDirectKeeper {
        uint256 typeOfIA = IInvestmentAgreement(ia).typeOfIA();

        bytes32 votingRule = _getSHA().getRule(typeOfIA);

        circulateDoc(ia, votingRule, docUrl, docHash);
    }

    function createFRDeals(address ia, uint40 creator)
        external
        onlyKeeper
        returns (address frd)
    {
        if (_frDeals[ia] == address(0)) {
            frd = createDoc(1, creator);
        }
    }

    function createMockResults(address ia, uint40 creator)
        external
        onlyKeeper
        returns (address mock)
    {
        if (_mockResults[ia] == address(0)) {
            mock = createDoc(2, creator);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function frDealsOfIA(address ia) external view returns (address) {
        return _frDeals[ia];
    }

    function mockResultsOfIA(address ia) external view returns (address) {
        return _mockResults[ia];
    }
}

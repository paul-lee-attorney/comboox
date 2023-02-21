// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IShareholdersAgreement.sol";
import "./terms/ITerm.sol";

import "../../books/boh/IBookOfSHA.sol";

import "../../common/access/IAccessControl.sol";
import "../../common/components/SigPage.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/utils/CloneFactory.sol";

contract ShareholdersAgreement is
    IShareholdersAgreement,
    CloneFactory,
    SigPage
{
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    // title => body
    mapping(uint256 => address) private _terms;
    EnumerableSet.UintSet private _titles;

    // seq => rule
    mapping(uint256 => bytes32) private _rules;
    EnumerableSet.UintSet private _rulesList;

    //####################
    //##    modifier    ##
    //####################

    modifier titleExist(uint256 title) {
        require(
            hasTitle(title),
            "SHA.titleExist: SHA does not have such title"
        );
        _;
    }

    // modifier tempReadyFor(uint8 title) {
    //     require(
    //         _rod.tempReady(title),
    //         "SHA.tempReadyFor: Template NOT ready"
    //     );
    //     _;
    // }

    //##################
    //##  Write I/O   ##
    //##################

    function createTerm(uint8 title)
        external
        onlyGeneralCounsel
        tempReady(title)
        returns (address body)
    {
        body = createClone(_rod.template(title));

        uint40 owner = getOwner();
        uint40 gc = getGeneralCounsel();

        IAccessControl(body).init(
            owner,
            address(this),
            address(_rc),
            address(_gk)
        );

        IAccessControl(body).setGeneralCounsel(gc);

        _terms[title] = body;
        _titles.add(title);
    }

    function removeTerm(uint8 title) external onlyAttorney {
        if (_titles.remove(title)) {
            delete _terms[title];
        }
    }

    function finalizeTerms() external onlyDirectKeeper {
        uint256 len = _titles.length();

        for (uint256 i = 0; i < len; i++) {
            IAccessControl(_terms[_titles.at(i)]).lockContents();
        }

        lockContents();
    }

    // ==== Rules ====
    function addRule(bytes32 rule) external onlyAttorney {
        _rules[rule.seqOfRule()] = rule;
        _rulesList.add(rule.seqOfRule());
    }

    function removeRule(uint16 seq) external onlyAttorney {
        if (_rulesList.remove(seq)) {
            delete _rules[seq];
        }
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Terms ====

    function hasTitle(uint256 title) public view returns (bool) {
        return _titles.contains(title);
    }

    function qtyOfTerms() external view returns (uint256) {
        return _titles.length();
    }

    function titles() external view returns (uint256[] memory) {
        return _titles.values();
    }

    function getTerm(uint256 title) external view returns (address) {
        return _terms[title];
    }

    function termIsTriggered(
        uint256 title,
        address ia,
        bytes32 snOfDeal
    ) public view titleExist(title) returns (bool) {
        return ITerm(_terms[title]).isTriggered(ia, snOfDeal);
    }

    function termIsExempted(
        uint256 title,
        address ia,
        bytes32 snOfDeal
    ) external view titleExist(title) returns (bool) {
        if (!termIsTriggered(title, ia, snOfDeal)) return true;

        return ITerm(_terms[title]).isExempted(ia, snOfDeal);
    }

    // ==== Rules ====
    
    function hasRule(uint256 seq) external view returns (bool) {
        return _rulesList.contains(seq);
    }

    function qtyOfRules() external view returns (uint256) {
        return _rulesList.length();
    }

    function rules() external view returns (uint256[] memory) {
        return _rulesList.values();
    }

    function getRule(uint256 seq) external view returns (bytes32) {
        return _rules[seq];
    }
}

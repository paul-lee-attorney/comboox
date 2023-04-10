// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IShareholdersAgreement.sol";
import "../../common/components/SigPage.sol";

contract ShareholdersAgreement is IShareholdersAgreement, SigPage {
    using EnumerableSet for EnumerableSet.UintSet;

    TermsRepo private _terms;
    RulesRepo private _rules;

    //####################
    //##    modifier    ##
    //####################

    modifier titleExist(uint256 title) {
        require(
            hasTitle(title),
            "SHA.mf.TE: title not exist"
        );
        _;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function createTerm(uint typeOfDoc, uint version)
        external
        onlyGeneralCounsel
        returns (address body)
    {
        // uint40 owner = getOwner();
        uint40 gc = getGeneralCounsel();

        uint256 snOfDoc = (typeOfDoc << 240) + (version << 224);

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, msg.sender);        

        IAccessControl(doc.body).init(
            gc,
            address(this),
            address(_rc),
            address(_gk)
        );

        // IAccessControl(body).setGeneralCounsel(gc);

        _terms.terms[typeOfDoc] = body;
        _terms.seqList.add(typeOfDoc);
    }

    function removeTerm(uint typeOfDoc) external onlyAttorney {
        if (_terms.seqList.remove(typeOfDoc)) {
            delete _terms.terms[typeOfDoc];
        }
    }

    // ==== Rules ====
    
    function addRule(uint256 rule) external onlyAttorney {

        uint16 seq = uint16(rule >> 240);

        _rules.rules[seq] = rule;
        _rules.seqList.add(seq);
    }

    function removeRule(uint256 seq) external onlyAttorney {
        if (_rules.seqList.remove(seq)) {
            delete _rules.rules[seq];
        }
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Terms ====

    function hasTitle(uint256 title) public view returns (bool) {
        return _terms.seqList.contains(title);
    }

    function qtyOfTerms() external view returns (uint256) {
        return _terms.seqList.length();
    }

    function titles() external view returns (uint256[] memory) {
        return _terms.seqList.values();
    }

    function getTerm(uint256 title) external view returns (address) {
        return _terms.terms[title];
    }

    function termIsTriggered(
        uint256 title,
        address ia,
        uint256 seqOfDeal
    ) public view titleExist(title) returns (bool) {
        return ITerm(_terms.terms[title]).isTriggered(ia, IInvestmentAgreement(ia).getDeal(seqOfDeal));
    }

    function termIsExempted(
        uint256 title,
        address ia,
        uint256 seqOfDeal
    ) external view titleExist(title) returns (bool) {
        if (!termIsTriggered(title, ia, seqOfDeal)) return true;

        return ITerm(_terms.terms[title]).isExempted(ia, IInvestmentAgreement(ia).getDeal(seqOfDeal));
    }

    // ==== Rules ====
    
    function hasRule(uint256 seq) external view returns (bool) {
        return _rules.seqList.contains(seq);
    }

    function qtyOfRules() external view returns (uint256) {
        return _rules.seqList.length();
    }

    function rules() external view returns (uint256[] memory) {
        return _rules.seqList.values();
    }

    function getRule(uint256 seq) external view returns (uint256) {
        return _rules.rules[seq];
    }
}

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
        onlyGC
    {
        // address owner = getOwner();
        // uint40 gc = _msgSender(10000);
        address gc = msg.sender;

        bytes32 snOfDoc = bytes32((typeOfDoc << 240) + uint240(version << 224));

        IRegCenter _rc = _getRC();

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, gc);        

        IAccessControl(doc.body).init(
            address(this),
            address(this),
            address(_rc),
            address(_getGK())
        );

        IAccessControl(doc.body).setRoleAdmin(bytes32("Attorneys"), gc);
        // IAccessControl(doc.body).setOwner(owner);

        _terms.terms[typeOfDoc] = doc.body;
        _terms.seqList.add(typeOfDoc);
    }

    function removeTerm(uint typeOfDoc) external onlyAttorney {
        if (_terms.seqList.remove(typeOfDoc)) {
            delete _terms.terms[typeOfDoc];
        }
    }

    // ==== Rules ====
    
    function addRule(bytes32 rule) external onlyAttorney {
        _addRule(rule);
    }

    function _addRule(bytes32 rule) private {
        uint seqOfRule = uint16(uint(rule) >> 240);

        _rules.rules[seqOfRule] = rule;
        _rules.seqList.add(seqOfRule);
    }


    function removeRule(uint256 seq) external onlyAttorney {
        if (_rules.seqList.remove(seq)) {
            delete _rules.rules[seq];
        }
    }

    function initDefaultRules() external onlyDK {

        bytes32[] memory rules = new bytes32[](15);        

        // DefualtGovernanceRule
        rules[0] = bytes32(uint(0x000001010003e800000d0503e8003213880500241388000000000000140105dc));

        // DefaultVotingRules
        rules[1]  = bytes32(uint(0x00010c01000100001a0b000001000f0e00010100000000000000000000000000));
        rules[2]  = bytes32(uint(0x00020c02000100001388000100010f0e00010100000000000000000000000000));
        rules[3]  = bytes32(uint(0x00030c0300010000000000010100000000010100000000000000000000000000));
        rules[4]  = bytes32(uint(0x00040c04000100001a0b000001000f0e00010100000000000000000000000000));
        rules[5]  = bytes32(uint(0x00050c05000100001388000100010f0e00010100000000000000000000000000));
        rules[6]  = bytes32(uint(0x00060c06000100001a0b000001000f0e00010100000000000000000000000000));
        rules[7]  = bytes32(uint(0x00070c07000100001a0b000001000f0e00010100000000000000000000000000));
        rules[8]  = bytes32(uint(0x00080c08000100001a0b0000010000001d010100000000000000000000000000));
        rules[9]  = bytes32(uint(0x00090c090001000013880100000000001d010100000000000000000000000000));
        rules[10] = bytes32(uint(0x000a0c0a000100001a0b0100000000001d010100000000000000000000000000));
        rules[11] = bytes32(uint(0x000b0c0b00021388000001000000000009010100000000000000000000000000));
        rules[12] = bytes32(uint(0x000c0c0c00021a0b000001000000000009010100000000000000000000000000));

        // DefaultFirstRefusalRules
        rules[13] = bytes32(uint(0x0200020101010100000000000000000000000000000000000000000000000000));
        rules[14] = bytes32(uint(0x0201020202010100000000000000000000000000000000000000000000000000));

        uint len = 15;
        while (len > 0) {
            _addRule(rules[len - 1]);
            len--;
        }

    }

    // ==== Finalize SHA ====

    function finalizeSHA() external {

        uint[] memory titles = getTitles();
        uint len = titles.length;

        while (len > 0) {
            IAccessControl(_terms.terms[titles[len-1]]).lockContents();
            len --;
        }

        lockContents();
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

    function getTitles() public view returns (uint256[] memory) {
        return _terms.seqList.values();
    }

    function getTerm(uint256 title) external view titleExist(title) returns (address) {
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

    function getRules() external view returns (uint256[] memory) {
        return _rules.seqList.values();
    }

    function getRule(uint256 seq) external view returns (bytes32) {
        return _rules.rules[seq];
    }
}

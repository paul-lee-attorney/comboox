// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IShareholdersAgreement.sol";
import "./terms/ITerm.sol";

import "../../books/boh/BookOfSHA.sol";

import "../../common/access/IAccessControl.sol";
import "../../common/components/SigPage.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/ruting/IBookSetting.sol";
import "../../common/ruting/BOASetting.sol";
import "../../common/ruting/BOHSetting.sol";
import "../../common/ruting/BOMSetting.sol";
import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROMSetting.sol";

import "../../common/utils/CloneFactory.sol";

contract ShareholdersAgreement is
    IShareholdersAgreement,
    CloneFactory,
    BOASetting,
    BOHSetting,
    BOMSetting,
    BOSSetting,
    ROMSetting,
    SigPage
{
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    enum TermTitle {
        ZeroPoint, //            0
        LOCK_UP, //              1
        ANTI_DILUTION, //        2
        DRAG_ALONG, //           3
        TAG_ALONG, //            4
        OPTIONS //               5
    }

    // title => body
    mapping(uint256 => address) private _terms;
    EnumerableSet.UintSet private _titles;

    // ==== Rules ========

/*
    |  Seq  |        Type       |    Abb       |            Description                     |       
    |    0  |  GovernanceRule   |     GR       | Board Constitution and General Rules of GM | 
    |    1  |  VotingRule       |     CI       | VR for Capital Increase                    |
    |    2  |                   |   SText      | VR for External Share Transfer             |
    |    3  |                   |   STint      | VR for Internal Share Transfer             |
    |    4  |                   |    1+3       | VR for CI & STint                          |
    |    5  |                   |    2+3       | VR for SText & STint                       |
    |    6  |                   |   1+2+3      | VR for CI & SText & STint                  |
    |    7  |                   |    1+2       | VR for CI & SText                          |
    |    8  |                   |   SHA        | VR for Update SHA                          |
    |    9  |                   |  O-Issue-GM  | VR for Ordinary Issues of GeneralMeeting   |
    |   10  |                   |  S-Issue-GM  | VR for Special Issues Of GeneralMeeting    |
    |   11  |                   |  O-Issue-B   | VR for Ordinary Issues Of Board            |
    |   12  |                   |  S-Issue-B   | VR for Special Issues Of Board             |
    ...

    |  256  |  BoardSeatsRule   |      BSR     | Board Seats Allocation Rights to Members   |
    ...

    |  512  | FirstRefusalRule  |  FR for CI...| FR rule for Investment Deal                |
    ...

    |  768  | GroupUpdateOrder  |  GroupUpdate | Grouping Members as per their relationship |
    ...

*/

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

    modifier tempReadyFor(uint8 title) {
        require(
            _boh.hasTemplate(title),
            "SHA.tempReadyFor: Template NOT ready"
        );
        _;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function createTerm(uint8 title)
        external
        onlyGeneralCounsel
        tempReadyFor(title)
        returns (address body)
    {
        body = createClone(_boh.getTermTemplate(title));

        uint40 owner = getOwner();

        uint40 gc = getGeneralCounsel();

        IAccessControl(body).init(
            owner,
            address(this),
            address(_rc),
            address(_gk)
        );

        IAccessControl(body).setGeneralCounsel(gc);

        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.LOCK_UP) ||
            title == uint8(TermTitle.TAG_ALONG)
        ) IBookSetting(body).setBOM(address(_bom));

        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.DRAG_ALONG) ||
            title == uint8(TermTitle.TAG_ALONG)
        ) IBookSetting(body).setBOS(address(_bos));

        if (
            title == uint8(TermTitle.ANTI_DILUTION) ||
            title == uint8(TermTitle.DRAG_ALONG) ||
            title == uint8(TermTitle.TAG_ALONG)
        ) IBookSetting(body).setROM(address(_rom));

        if (
            title == uint8(TermTitle.DRAG_ALONG) ||
            title == uint8(TermTitle.TAG_ALONG)
        ) IBookSetting(body).setBOA(address(_boa));

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

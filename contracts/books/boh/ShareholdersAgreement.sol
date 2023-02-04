// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
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
    using EnumerableSet for EnumerableSet.Bytes32Set;

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

    // governanceRule {
    //     uint16 seqOfRule;
    //     bool basedOnPar;
    //     uint16 proposalThreshold;
    //     uint8 maxNumOfDirectors;
    //     uint8 tenureOfBoard;
    // }

    /*
    | Seq |        Type       |    Abb       |            Description                     |       
    |  0  |  GovernanceRule   |     GR       | Board Constitution and General Rules of GM | 
    |  1  |  VotingRule       |     CI       | VR for Capital Increase                    |
    |  2  |                   |   SText      | VR for External Share Transfer             |
    |  3  |                   |   STint      | VR for Internal Share Transfer             |
    |  4  |                   |    1+3       | VR for CI & STint                          |
    |  5  |                   |    2+3       | VR for SText & STint                       |
    |  6  |                   |   1+2+3      | VR for CI & SText & STint                  |
    |  7  |                   |    1+2       | VR for CI & SText                          |
    |  8  |                   |  O-Issue-GM  | VR for Ordinary Issues of GeneralMeeting   |
    |  9  |                   |  S-Issue-GM  | VR for Special Issues Of GeneralMeeting    |
    | 10  |                   |  O-Issue-B   | VR for Ordinary Issues Of Board            |
    | 11  |                   |  S-Issue-B   | VR for Special Issues Of Board             |
    | 21  | FirstRefusalRule  |  FR for CI   | FR rule for Capital Increase Deal          |
    | 22  |                   | FR for SText | FR rule for Share Transfer (External) Deal |
    | 23  |                   | FR for STint | FR rule for Share Transfer (Internal) Deal |
*/

    // seq => rule
    mapping(uint256 => bytes32) private _rules;
    EnumerableSet.UintSet private _seqOfRules;

    // seqOfRule => userNo
    mapping(uint256 => EnumerableSet.UintSet) private _rightholders;

    // userNo => qty of directors can be appointed/nominated by the member;
    mapping(uint256 => uint8) private _boardSeatsOf;

    EnumerableSet.Bytes32Set private _groupOrders;

    //####################
    //##    modifier    ##
    //####################

    modifier titleExist(uint8 title) {
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
        onlyManager(1)
        tempReadyFor(title)
        returns (address body)
    {
        body = createClone(_boh.getTermTemplate(title));

        uint40 owner = getManager(0);

        uint40 gc = getManager(1);

        IAccessControl(body).init(
            owner,
            address(this),
            address(_rc),
            address(_gk)
        );

        IAccessControl(body).setManager(1, gc);

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

    function finalizeTerms() external onlyDK {
        uint256 len = _titles.length();

        for (uint256 i = 0; i < len; i++) {
            IAccessControl(_terms[_titles.at(i)]).lockContents();
        }

        lockContents();
    }

    // ==== Rules ====
    function addRule(bytes32 rule) external onlyAttorney {
        _rules[rule.seqOfRule()] = rule;
        _seqOfRules.add(rule.seqOfRule());
    }

    function removeRule(uint16 seq) external onlyAttorney {
        if (_seqOfRules.remove(seq)) {
            delete _rules[seq];
        }
    }

    function addRightholderOfRule(uint16 seqOfRule, uint40 rightholder)
        external
        onlyAttorney
    {
        _rightholders[seqOfRule].add(rightholder);
    }

    function removeRightholderOfRule(uint16 seqOfRule, uint40 rightholder)
        external
        onlyAttorney
    {
        _rightholders[seqOfRule].remove(rightholder);
    }

    function setBoardSeatsOf(uint40 nominator, uint8 quota)
        external
        onlyAttorney
    {
        _boardSeatsOf[nominator] = quota;
    }

    // ==== GroupUpdateOrders ====

    function addOrder(bytes32 order) external onlyAttorney {
        _groupOrders.add(order);
    }

    function delOrder(bytes32 order) external onlyAttorney {
        _groupOrders.remove(order);
    }

    //##################
    //##    读接口    ##
    //##################

    function hasTitle(uint8 title) public view returns (bool) {
        return _titles.contains(title);
    }

    function qtyOfTerms() public view returns (uint8) {
        return uint8(_titles.length());
    }

    function titles() external view returns (uint8[] memory) {
        return _titles.valuesToUint8();
    }

    function bodies() external view returns (address[] memory) {
        uint256 len = _titles.length();

        address[] memory list = new address[](len);

        while (len != 0) {
            list[len - 1] = _terms[_titles.at(len - 1)];
            len--;
        }

        return list;
    }

    function getTerm(uint8 title) external view returns (address) {
        return _terms[title];
    }

    function termIsTriggered(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) public view titleExist(title) returns (bool) {
        return ITerm(_terms[title]).isTriggered(ia, snOfDeal);
    }

    function termIsExempted(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view titleExist(title) returns (bool) {
        if (!termIsTriggered(title, ia, snOfDeal)) return true;

        return ITerm(_terms[title]).isExempted(ia, snOfDeal);
    }

    // ==== GovernanceRule ====

    function basedOnPar() external view returns (bool) {
        return uint8(_rules[0][2]) == 1;
    }

    function proposalThreshold() external view returns (uint16) {
        return uint16(bytes2(_rules[0] << 24));
    }

    function maxNumOfDirectors() public view returns (uint8) {
        return uint8(_rules[0][5]);
    }

    function tenureOfBoard() external view returns (uint8) {
        return uint8(_rules[0][6]);
    }

    function appointerOfOfficer(uint16 title) external view returns (uint40) {
        return uint40(_rightholders[0].at(title));
    }

    function boardSeatsOf(uint40 acct) external view returns (uint8) {
        return _boardSeatsOf[acct];
    }

    // ==== VotingRules ====

    function votingRules(uint16 typeOfVote) external view returns (bytes32) {
        require(typeOfVote > 0, "SA.votingRules: zero typeOfVote");
        require(typeOfVote < 21, "SA.votingRules: typeOfVote over flow");

        return _rules[typeOfVote];
    }

    function additionalVetoholdersOfVR(uint16 typeOfVote)
        external
        view
        returns (uint40[] memory)
    {
        require(typeOfVote > 0, "SA.votingRules: zero typeOfVote");
        require(typeOfVote < 21, "SA.votingRules: typeOfVote over flow");

        return _rightholders[typeOfVote].valuesToUint40();
    }

    // ==== FirstRefusal Rule ====

    function isSubjectToFR(uint8 typeOfDeal) external view returns (bool) {
        require(typeOfDeal > 0, "SHA.isSubjectToFR: typeOfDeal overflow");
        require(typeOfDeal < 4, "SHA.isSubjectToFR: typeOfDeal overflow");

        return _seqOfRules.contains(20 + typeOfDeal);
    }

    function ruleOfFR(uint8 typeOfDeal) external view returns (bytes32) {
        require(typeOfDeal > 0, "SHA.ruleOfFR: typeOfDeal overflow");
        require(typeOfDeal < 4, "SHA.ruleOfFR: typeOfDeal overflow");

        return _rules[20 + typeOfDeal];
    }

    function isRightholderOfFR(uint8 typeOfDeal, uint40 acct)
        external
        view
        returns (bool)
    {
        require(typeOfDeal > 0, "SHA.isRightholderOfFR: typeOfDeal overflow");
        require(typeOfDeal < 4, "SHA.isRightholderOfFR: typeOfDeal overflow");

        bytes32 rule = _rules[typeOfDeal + 20];

        if (rule.membersEqualOfFR()) return _rom.isMember(acct);
        else return _rightholders[typeOfDeal + 20].contains(acct);
    }

    function rightholdersOfFR(uint8 typeOfDeal)
        external
        view
        returns (uint40[] memory)
    {
        require(typeOfDeal > 0, "SHA.rightholdersOfFR: typeOfDeal overflow");
        require(typeOfDeal < 4, "SHA.rightholdersOfFR: typeOfDeal overflow");

        bytes32 rule = _rules[typeOfDeal + 20];

        if (rule.membersEqualOfFR()) return _rom.membersList();
        else return _rightholders[typeOfDeal + 20].valuesToUint40();
    }

    // ==== GroupUpdateOrders ====

    function groupOrders() external view returns (bytes32[] memory) {
        return _groupOrders.values();
    }

    function lengthOfOrders() external view returns (uint256) {
        return _groupOrders.length();
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa/IInvestmentAgreement.sol";
import "../../boa/InvestmentAgreement.sol";

import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/ROMSetting.sol";
import "../../../common/ruting/BOMSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/TopChain.sol";

import "./IAntiDilution.sol";

contract AntiDilution is IAntiDilution, BOSSetting, ROMSetting, BOMSetting {
    using ArrayUtils for uint40[];
    using EnumerableSet for EnumerableSet.UintSet;
    using SNParser for bytes32;
    using TopChain for TopChain.Chain;

    mapping(uint256 => EnumerableSet.UintSet) private _obligors;

    TopChain.Chain private _marks;

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint16 class) {
        require(
            _marks.isMember(class),
            "AD.onlyMarked: no uint price maked for the class"
        );
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function setMaxQtyOfMarks(uint16 max) external onlyAttorney {
        _marks.setMaxQtyOfMembers(max);
    }

    function addBenchmark(uint16 class, uint32 price) external onlyAttorney {
        _marks.addNode(class);
        _marks.changeAmt(class, price, true);
    }

    function updateBenchmark(
        uint16 class,
        uint32 deltaPrice,
        bool increase
    ) external onlyAttorney {
        _marks.changeAmt(class, deltaPrice, increase);
    }

    function delBenchmark(uint16 class) external onlyAttorney {
        (, , , uint64 price, , ) = _marks.getNode(class);

        _marks.changeAmt(class, price, false);
        _marks.delNode(class);
    }

    function addObligor(uint16 class, uint40 obligor) external onlyAttorney {
        _obligors[class].add(obligor);
    }

    function removeObligor(uint16 class, uint40 obligor) external onlyAttorney {
        _obligors[class].remove(obligor);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isMarked(uint16 class) external view returns (bool) {
        return class > 0 && _marks.nodes[class].ptr == class;
    }

    function markedClasses() external view returns (uint40[] memory) {
        return _marks.membersList();
    }

    function getBenchmark(uint16 class)
        external
        view
        onlyMarked(class)
        returns (uint64 price)
    {
        price = _marks.nodes[class].amt;
    }

    function obligors(uint16 class)
        external
        view
        onlyMarked(class)
        returns (uint40[] memory)
    {
        return _obligors[class].valuesToUint40();
    }

    function giftPar(bytes32 snOfDeal, bytes32 shareNumber)
        external
        view
        onlyMarked(shareNumber.class())
        returns (uint64 gift)
    {
        uint64 markPrice = _marks.nodes[shareNumber.class()].amt;

        uint32 dealPrice = snOfDeal.priceOfDeal();

        require(
            markPrice > dealPrice,
            "AD.giftPar: AntiDilution not triggered"
        );

        IBookOfShares.Share memory share = _bos.getShare(shareNumber.ssn());

        gift = (share.paid * markPrice) / dealPrice - share.paid;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) public view returns (bool) {
        uint32 unitPrice = sn.priceOfDeal();

        if (
            sn.typeOfDeal() !=
            uint8(IInvestmentAgreement.TypeOfDeal.CapitalIncrease) &&
            sn.typeOfDeal() != uint8(IInvestmentAgreement.TypeOfDeal.PreEmptive)
        ) return false;

        uint40 mark = _marks.nodes[0].next;

        while (mark > 0) {
            if (unitPrice < _marks.nodes[mark].amt) return true;
            else mark = _marks.nodes[mark].next;
        }

        return false;
    }

    function _isExempted(uint32 price, uint40[] memory consentParties)
        private
        view
        returns (bool)
    {
        require(
            consentParties.length != 0,
            "AD.isExempted: zero consentParties"
        );

        uint40 cur = _marks.nodes[0].next;

        while (cur > 0) {
            if (_marks.nodes[cur].amt <= price) break;

            uint40[] memory classMember = _membersOfClass(uint16(cur));

            if (classMember.length > consentParties.length) return false;
            else if (!classMember.fullyCoveredBy(consentParties)) return false;

            cur = _marks.nodes[cur].next;
        }

        return true;
    }

    function _membersOfClass(uint16 class)
        private
        view
        returns (uint40[] memory)
    {
        uint40[] memory members = _rom.membersList();
        uint256 len = members.length;

        uint40[] memory list = new uint40[](len);
        uint256 counter = 0;

        while (len > 0) {
            bytes32[] memory sharesInHand = _rom.sharesInHand(members[len - 1]);
            uint256 i = sharesInHand.length;

            while (i > 0) {
                if (sharesInHand[i - 1].class() == class) {
                    list[counter] = members[len - 1];
                    counter++;
                    break;
                } else i--;
            }

            len--;
        }

        uint40[] memory output = new uint40[](counter);

        assembly {
            output := list
        }

        return output;
    }

    function isExempted(address ia, bytes32 sn) external view returns (bool) {
        if (!isTriggered(ia, sn)) return true;

        uint256 typeOfIA = IInvestmentAgreement(ia).typeOfIA();
        uint256 motionId = (typeOfIA << 160) + uint256(uint160(ia));

        uint40[] memory consentParties = _bog.getCaseOfAttitude(
            motionId,
            1
        ).voters;

        uint32 unitPrice = sn.priceOfDeal();

        return _isExempted(unitPrice, consentParties);
    }
}

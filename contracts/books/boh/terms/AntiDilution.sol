// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa/IInvestmentAgreement.sol";
import "../../bos/IBookOfShares.sol";
// import "../../bog/IBookOfGM.sol";
import "../../rom/IRegisterOfMembers.sol";

import "../../../common/access/AccessControl.sol";

import "../../../common/lib/ArrayUtils.sol";
// import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/TopChain.sol";

import "../../../common/ruting/BODSetting.sol";
import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/ROMSetting.sol";

import "./IAntiDilution.sol";

contract AntiDilution is IAntiDilution, BODSetting, BOSSetting, ROMSetting, AccessControl {
    using ArrayUtils for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;
    // using SNParser for bytes32;
    using TopChain for TopChain.Chain;

    mapping(uint256 => EnumerableSet.UintSet) private _obligors;

    TopChain.Chain private _marks;

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint256 class) {
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

    function addBenchmark(uint256 class, uint32 price) external onlyAttorney {
        _marks.addNode(class);
        _marks.changeAmt(class, price, true);
    }

    function updateBenchmark(
        uint256 class,
        uint32 deltaPrice,
        bool increase
    ) external onlyAttorney {
        _marks.changeAmt(class, deltaPrice, increase);
    }

    function delBenchmark(uint256 class) external onlyAttorney {
        // (, , , uint64 price, , ) = _marks.getNode(class);
        TopChain.Node memory mark = _marks.getNode(class);

        _marks.changeAmt(class, mark.amt, false);
        _marks.delNode(class);
    }

    function addObligor(uint256 class, uint256 obligor) external onlyAttorney {
        _obligors[class].add(obligor);
    }

    function removeObligor(uint256 class, uint256 obligor) external onlyAttorney {
        _obligors[class].remove(obligor);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isMarked(uint256 class) external view returns (bool) {
        return class > 0 && _marks.nodes[class].amt > 0;
    }

    function markedClasses() external view returns (uint256[] memory) {
        return _marks.membersList();
    }

    function getBenchmark(uint256 class)
        external
        view
        onlyMarked(class)
        returns (uint64 price)
    {
        price = _marks.nodes[class].amt;
    }

    function obligors(uint256 class)
        external
        view
        onlyMarked(class)
        returns (uint256[] memory)
    {
        return _obligors[class].values();
    }

    function giftPar(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external
        view
        returns (uint64 gift)
    {
        IInvestmentAgreement.Deal memory deal = 
            IInvestmentAgreement(ia).getDeal(seqOfDeal);
        
        IBookOfShares.Share memory share = _getBOS().getShare(seqOfShare);

        uint64 markPrice = _marks.nodes[share.head.class].amt;

        // uint32 dealPrice = snOfDeal.priceOfDeal();

        require(
            markPrice > deal.head.price,
            "AD.giftPar: AntiDilution not triggered"
        );

        // IBookOfShares.Share memory share = _getBOS().
        //     getShare(shareNumber.ssn());

        gift = (share.body.paid * markPrice) / deal.head.price - share.body.paid;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, IInvestmentAgreement.Deal memory deal) public view returns (bool) {

        // IInvestmentAgreement.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        // uint32 unitPrice = sn.priceOfDeal();

        if (
            deal.head.typeOfDeal !=
            uint8(IInvestmentAgreement.TypeOfDeal.CapitalIncrease) &&
            deal.head.typeOfDeal != uint8(IInvestmentAgreement.TypeOfDeal.PreEmptive)
        ) return false;

        uint40 mark = _marks.nodes[0].next;

        while (mark > 0) {
            if (deal.head.price < _marks.nodes[mark].amt) return true;
            else mark = _marks.nodes[mark].next;
        }

        return false;
    }

    function _isExempted(uint32 price, uint256[] memory consentParties)
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

            uint256[] memory classMember = _membersOfClass(uint16(cur));

            if (classMember.length > consentParties.length) return false;
            else if (!classMember.fullyCoveredBy(consentParties)) return false;

            cur = _marks.nodes[cur].next;
        }

        return true;
    }

    function _membersOfClass(uint16 class)
        private
        view
        returns (uint256[] memory)
    {
        IRegisterOfMembers _rom = _getROM();

        uint256[] memory members = _rom.membersList();

        uint256 len = members.length;

        uint256[] memory list = new uint256[](len);
        uint256 counter = 0;

        while (len > 0) {
            uint256[] memory sharesInHand = _rom.sharesInHand(members[len - 1]);
            uint256 i = sharesInHand.length;

            while (i > 0) {
                IBookOfShares.Share memory share = _getBOS().getShare(sharesInHand[i-1]);

                if (share.head.class == class) {
                    list[counter] = members[len - 1];
                    counter++;
                    break;
                } else i--;
            }

            len--;
        }

        uint256[] memory output = new uint256[](counter);

        assembly {
            output := list
        }

        return output;
    }

    function isExempted(address ia, IInvestmentAgreement.Deal memory deal) external view returns (bool) {
        if (!isTriggered(ia, deal)) return true;

        // uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();
        // uint256 motionId = (typeOfIA << 160) + uint256(uint160(ia));
        uint256 motionId = uint256(uint160(ia));

        // uint256[] memory consentParties;

        uint256[] memory consentParties = _getBOD().
            getCaseOfAttitude(motionId,1).voters;
        
        // assembly {
        //     consentParties := parties
        // }


        // uint32 unitPrice = IInvestmentAgreement(ia).getDeal(seqOfDeal).head.price;

        return _isExempted(deal.head.price, consentParties);
    }
}

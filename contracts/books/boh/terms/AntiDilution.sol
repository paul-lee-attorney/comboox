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

import "../../../common/ruting/BOGSetting.sol";
import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/ROMSetting.sol";

import "./IAntiDilution.sol";

contract AntiDilution is IAntiDilution, BOGSetting, BOSSetting, ROMSetting, AccessControl {
    using ArrayUtils for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;

    // classOfShare => Benchmark
    mapping(uint256 => Benchmark) private _marks;
    EnumerableSet.UintSet private _classes;

    // #################
    // ##   修饰器    ##
    // #################

    modifier onlyMarked(uint256 class) {
        require(isMarked(class), "AD.mf.OM: class not marked");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function addBenchmark(uint256 class, uint32 price) external onlyAttorney {        

        require (class > 0, "AD.AB: zero class");
        require (price > 0, "AD.AB: zero price");

        _marks[class].classOfShare = class;
        _marks[class].floorPrice = price;

        _classes.add(class);
    }

    function removeBenchmark(uint256 class) external onlyAttorney {
        if (_classes.remove(class)) 
            delete _marks[class];
    }

    function addObligor(uint256 class, uint256 obligor) external onlyMarked(class) onlyAttorney {
        _marks[class].obligors.add(obligor);
    }

    function removeObligor(uint256 class, uint256 obligor) external onlyMarked(class) onlyAttorney {
        _marks[class].obligors.remove(obligor);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isMarked(uint256 class) public view returns (bool flag) {
        flag = _classes.contains(class);
    }

    function getClasses() external view returns (uint256[] memory) {
        return _classes.values();
    }

    function getFloorPriceOfClass(uint256 class)
        public
        view
        onlyMarked(class)
        returns (uint64 price)
    {
        price = _marks[class].floorPrice;
    }

    function getObligorsOfAD(uint256 class)
        external
        view
        onlyMarked(class)
        returns (uint256[] memory)
    {
        return _marks[class].obligors.values();
    }

    function getGiftPaid(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external
        view
        returns (uint64 gift)
    {
        IInvestmentAgreement.Deal memory deal = 
            IInvestmentAgreement(ia).getDeal(seqOfDeal);
        
        IBookOfShares.Share memory share = _getBOS().getShare(seqOfShare);

        uint64 floorPrice = getFloorPriceOfClass(share.head.class);

        require(floorPrice > deal.head.price, "AD.GP: adRule not triggered");

        gift = (share.body.paid * floorPrice) / deal.head.price - share.body.paid;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, IInvestmentAgreement.Deal memory deal) public view returns (bool) {

        if (deal.head.typeOfDeal != uint8(IInvestmentAgreement.TypeOfDeal.CapitalIncrease)) 
            return false;

        uint64 floorPrice = getFloorPriceOfClass(deal.head.classOfShare);

        if (deal.head.priceOfPaid < floorPrice) return true;

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

        uint256 motionId = uint256(uint160(ia));

        uint256[] memory initBuyers = ISigPage(ia).getBuyers(true);
        uint256[] memory initSellers = ISigPage(ia).getSellers(true);
        uint256[] memory addtBuyers = ISigPage(ia).getBuyers(false);
        uint256[] memory addtSellers = ISigPage(ia).getSellers(false);
        
        uint256[] memory parties = initBuyers.merge(addtBuyers).merge(initSellers).merge(addtSellers);

        uint256[] memory supporters = _getBOG().
            getCaseOfAttitude(motionId,1).voters;
        
        uint256[] memory consentParties = parties.merge(supporters);        

        return _isExempted(deal.head.priceOfPaid, consentParties);
    }
}

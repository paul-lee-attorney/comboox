// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/access/AccessControl.sol";

// import "../../../common/ruting/BOGSetting.sol";
// import "../../../common/ruting/BOSSetting.sol";
// import "../../../common/ruting/ROMSetting.sol";

import "./IAntiDilution.sol";

contract AntiDilution is IAntiDilution, AccessControl {
    using ArrayUtils for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;

    Ruler private _ruler;

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

        _ruler.marks[class].classOfShare = uint16(class);
        _ruler.marks[class].floorPrice = price;

        _ruler.classes.add(class);
    }

    function removeBenchmark(uint256 class) external onlyAttorney {
        if (_ruler.classes.remove(class)) 
            delete _ruler.marks[class];
    }

    function addObligor(uint256 class, uint256 obligor) external onlyMarked(class) onlyAttorney {
        _ruler.marks[class].obligors.add(obligor);
    }

    function removeObligor(uint256 class, uint256 obligor) external onlyMarked(class) onlyAttorney {
        _ruler.marks[class].obligors.remove(obligor);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isMarked(uint256 class) public view returns (bool flag) {
        flag = _ruler.classes.contains(class);
    }

    function getClasses() external view returns (uint256[] memory) {
        return _ruler.classes.values();
    }

    function getFloorPriceOfClass(uint256 class)
        public
        view
        onlyMarked(class)
        returns (uint32 price)
    {
        price = _ruler.marks[class].floorPrice;
    }

    function isObligor(uint256 class, uint256 acct) external view returns (bool flag)
    {
        flag = _ruler.marks[class].obligors.contains(acct);
    }

    function getObligorsOfAD(uint256 class)
        external
        view
        onlyMarked(class)
        returns (uint256[] memory)
    {
        return _ruler.marks[class].obligors.values();
    }

    function getGiftPaid(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external
        view
        returns (uint64 gift)
    {
        DealsRepo.Deal memory deal = 
            IInvestmentAgreement(ia).getDeal(seqOfDeal);
        
        SharesRepo.Share memory share = _gk.getBOS().getShare(seqOfShare);

        uint64 floorPrice = getFloorPriceOfClass(share.head.class);

        require(floorPrice > deal.head.priceOfPaid, "AD.GP: adRule not triggered");

        gift = (share.body.paid * floorPrice) / deal.head.priceOfPaid - share.body.paid;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, DealsRepo.Deal memory deal) public view returns (bool) {

        if (deal.head.typeOfDeal != uint8(DealsRepo.TypeOfDeal.CapitalIncrease)) 
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

        uint256 len = _ruler.classes.length();

        while (len > 0) {
            uint16 class = uint16 (_ruler.classes.at(len-1));
            if (_ruler.marks[class].floorPrice > price) {
                uint256[] memory members = _gk.getROM().getMembersOfClass(class);

                if (members.length > consentParties.length) return false;
                else if (!members.fullyCoveredBy(consentParties)) return false;
            }
                        len--;
        }

        return true;
    }


    function isExempted(address ia, DealsRepo.Deal memory deal) external view returns (bool) {
        if (!isTriggered(ia, deal)) return true;

        uint256 motionId = uint256(uint160(ia));
        
        uint256[] memory parties = ISigPage(ia).getParties();

        uint256[] memory supporters = _gk.getBOG().
            getCaseOfAttitude(motionId, 1).voters;
        
        uint256[] memory consentParties = parties.merge(supporters);        

        return _isExempted(deal.head.priceOfPaid, consentParties);
    }
}

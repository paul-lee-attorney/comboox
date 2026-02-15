// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "../../../common/access/DraftControl.sol";

import "./IAntiDilution.sol";

contract AntiDilution is IAntiDilution, DraftControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using InterfacesHub for address;

    Ruler private _ruler;

    // #################
    // ##   Modifier  ##
    // #################

    modifier onlyMarked(uint256 class) {
        if(!isMarked(class)) 
            revert AD_WrongInput(bytes32("AD_ClassNotMarked"));
        _;
    }

    // ################
    // ## Write I/O ##
    // ################

    function addBenchmark(uint256 class, uint price) external onlyAttorney {        

        if (class == 0) 
            revert AD_ZeroValue(bytes32("AD_ZeroClass"));
        if (price == 0) 
            revert AD_ZeroValue(bytes32("AD_ZeroPrice"));

        _ruler.marks[class].classOfShare = uint16(class);
        _ruler.marks[class].floorPrice = uint32(price);

        _ruler.classes.add(class);
    }

    function removeBenchmark(uint256 class) external onlyAttorney {
        if (_ruler.classes.remove(class)) 
            delete _ruler.marks[class];
    }

    function addObligor(uint256 class, uint256 obligor) external onlyMarked(class) onlyAttorney {
        if (obligor == 0) 
            revert AD_ZeroValue(bytes32("AD_ZeroObligor"));
        _ruler.marks[class].obligors.add(obligor);
    }

    function removeObligor(uint256 class, uint256 obligor) external onlyMarked(class) onlyAttorney {
        _ruler.marks[class].obligors.remove(obligor);
    }

    // ################
    // ##  Read I/O  ##
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
        returns (uint256[] memory)
    {
        return _ruler.marks[class].obligors.values();
    }

    function getGiftPaid(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external
        view
        returns (uint64)
    {
        DealsRepo.Deal memory deal = 
            IInvestmentAgreement(ia).getDeal(seqOfDeal);

        SharesRepo.Share memory share = 
            _gk.getROS().getShare(seqOfShare);

        if (!isTriggered(deal, share.head.class)) 
            revert AD_WrongState(bytes32("AD_NotTriggered"));

        uint32 floorPrice = getFloorPriceOfClass(share.head.class);

        if (share.head.priceOfPaid < floorPrice) 
            revert AD_Overflow(bytes32("AD_PriceBelowFloor"));

        return (share.body.paid * floorPrice / deal.head.priceOfPaid - share.body.paid);
    }

    // ################
    // ##  Term      ##
    // ################

    function isTriggered(DealsRepo.Deal memory deal, uint class) public view returns (bool) {

        if (deal.head.typeOfDeal != uint8(DealsRepo.TypeOfDeal.CapitalIncrease)) 
            return false;

        if (deal.head.priceOfPaid < getFloorPriceOfClass(class)) return true;

        return false;
    }
}

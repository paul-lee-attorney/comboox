// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IMockResults {
    //##############
    //##  Events  ##
    //##############

    event CreateMockGM();

    event MockDealOfSell(uint40 indexed seller, uint64 amount);

    event MockDealOfBuy(uint40 indexed buyer, uint64 amount);

    event AddAlongDeal(
        uint40 indexed follower,
        bytes32 sharenumber,
        uint64 amount
    );

    //#################
    //##  Write I/O  ##
    //#################

    function createMockGM() external;

    function mockDealOfSell(uint32 ssn, uint64 amount) external;

    function mockDealOfBuy(bytes32 sn, uint64 amount) external;

    function addAlongDeal(
        bytes32 rule,
        bytes32 shareNumber,
        uint64 amount
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function topGroup() external view returns (uint40 controllor, uint64 ratio);

    function mockResults(uint40 acct)
        external
        view
        returns (uint40 group, uint64 sum);
}

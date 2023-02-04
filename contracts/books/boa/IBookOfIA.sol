// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IDocumentsRepo.sol";

interface IBookOfIA is IDocumentsRepo {
    //##################
    //##    写接口    ##
    //##################

    // ======== BookOfIA ========

    function circulateIA(address ia, bytes32 docHash) external;

    function createFRDeals(address ia, uint40 creator)
        external
        returns (address frd);

    function createMockResults(address ia, uint40 creator)
        external
        returns (address mock);

    //##################
    //##    读接口    ##
    //##################

    // ======== BookOfIA ========

    function frDealsOfIA(address ia) external view returns (address);

    function mockResultsOfIA(address ia) external view returns (address);
}

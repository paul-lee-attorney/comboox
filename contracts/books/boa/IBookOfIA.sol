// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IRepoOfDocs.sol";
import "../../common/lib/FRClaims.sol";

interface IBookOfIA is IRepoOfDocs {
    //##################
    //##    写接口    ##
    //##################

    // ======== BookOfIA ========

    function circulateIA(address ia, bytes32 docUrl, bytes32 docHash) external;

    function execFirstRefusalRight(
        address ia,
        uint16 seqOfDeal,
        uint40 caller
    ) external returns (bool flag);

    function acceptFirstRefusalClaims(
        address ia,
        uint16 seqOfDeal
    ) external returns (FRClaims.Claim[] memory output);


    function createMockResults(address ia, uint40 creator)
        external
        returns (address mock);

    //##################
    //##    读接口    ##
    //##################

    // ======== BookOfIA ========

    function claimsOfFR(address ia, uint256 seqOfDeal)
        external returns(FRClaims.Claim[] memory);

    function mockResultsOfIA(address ia) external view returns (address);
}

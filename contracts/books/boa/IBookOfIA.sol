// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IRepoOfDocs.sol";
import "../../common/lib/FRClaims.sol";
import "../../common/lib/DTClaims.sol";

interface IBookOfIA is IRepoOfDocs {

    //#################
    //##    Event    ##
    //#################

    event ExecFirstRefusalRight(address ia, uint256 seqOfDeal, uint256 caller);

    event ExecAlongRight(address ia, bool dragAlong, uint256 seqOfDeal, 
    uint256 seqOfShare, uint64 paid, uint64 par, uint256 claimer, bytes32 sigHash);

    event AcceptFirstRefusalClaims(address ia, uint256 seqOfDeal);

    event AddAlongDeal(address ia, uint256 follower, uint256 seqOfShare, uint64 amount);

    //#################
    //##    写接口    ##
    //#################

    // ======== BookOfIA ========

    function circulateIA(address ia, bytes32 docUrl, bytes32 docHash) external;

    function execFirstRefusalRight(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external returns (bool flag);

    function acceptFirstRefusalClaims(
        address ia,
        uint256 seqOfDeal
    ) external returns (FRClaims.Claim[] memory output);

    function execAlongRight(
        address ia,
        bool dragAlong,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function createMockOfIA(address ia)
        external
        returns (bool flag);

    function mockDealOfSell (address ia, uint40 seller, uint64 amount) 
        external
        returns (bool flag); 

    function mockDealOfBuy (address ia, uint40 buyer, uint40 groupRep, uint64 amount) 
        external
        returns (bool flag);

    // function addAlongDeal(
    //     address ia,
    //     uint256 seqOfLinkRule,
    //     uint32 seqOfShare,
    //     uint64 amount
    // ) external returns (bool flag);

    //##################
    //##    读接口    ##
    //##################

    // ======== BookOfIA ========

    function isFRClaimer(address ia, uint256 acct) external returns (bool);

    function claimsOfFR(address ia, uint256 seqOfDeal)
        external returns(FRClaims.Claim[] memory);

    function hasDTClaims(address ia, uint256 seqOfDeal) 
        external view returns(bool);

    function getDraggingDeals(address ia)
        external view returns(uint256[] memory);

    function getDTClaimsForDeal(address ia, uint256 seqOfDeal)
        external view returns(DTClaims.Claim[] memory);

    function getDTClaimForShare(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external view returns(DTClaims.Claim memory);

    function mockResultsOfIA(address ia) 
        external view 
        returns (uint40 controllor, uint16 ratio);

    function mockResultsOfAcct(address ia, uint256 acct) 
        external view 
        returns (uint40 groupRep, uint16 ratio);
}

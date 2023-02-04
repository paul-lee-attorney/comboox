// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IMeetingMinutes.sol";

interface IBookOfDirectors is IMeetingMinutes {
    //###################
    //##    events    ##
    //##################

    event SetMaxQtyOfDirectors(uint8 max);

    event AddDirector(
        uint8 title,
        uint40 acct,
        uint40 appointer,
        uint64 startBN,
        uint64 endBN
    );

    event RemoveDirector(uint40 user);

    //##################
    //##    写接口    ##
    //##################

    // ======== Directors ========

    function setMaxQtyOfDirectors(uint8 max) external;

    function appointDirector(
        uint40 candidate,
        uint8 title,
        uint40 appointer
    ) external;

    function removeDirector(uint40 acct) external;

    function takePosition(uint40 candidate, uint40 nominator) external;

    //##################
    //##    读接口    ##
    //##################

    function maxQtyOfDirectors() external view returns (uint8);

    function qtyOfDirectors() external view returns (uint256);

    function appointmentCounter(uint40 appointer)
        external
        view
        returns (uint8 qty);

    function isDirector(uint40 acct) external view returns (bool flag);

    function inTenure(uint40 acct) external view returns (bool);

    function whoIs(uint8 title) external view returns (uint40);

    function titleOfDirector(uint40 acct) external view returns (uint8);

    function appointerOfDirector(uint40 acct) external view returns (uint40);

    function startBNOfDirector(uint40 acct) external view returns (uint64);

    function endBNOfDirector(uint40 acct) external view returns (uint64);

    function directors() external view returns (uint40[] memory);
}

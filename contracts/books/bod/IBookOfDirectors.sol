// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IMeetingMinutes.sol";

interface IBookOfDirectors is IMeetingMinutes {

    enum TitleOfDirectors {
        ZeroPoint,
        Chairman,
        ViceChairman,
        Director,
        CEO,
        CFO,
        COO,
        CTO,
        President,
        VicePresident,
        SeniorManager,
        Manager,
        ViceManager        
    }

    struct Officer {
        uint8 title; 
        uint40 acct;
        uint40 appointer;
        uint48 startDate;
        uint48 endDate;
    }

    //###################
    //##    events    ##
    //##################

    event SetMaxQtyOfDirectors(uint8 max);

    event AppointOfficer(
        uint256 indexed acct,
        uint8 title,
        uint256 appointer
    );

    event AddDirector(
        uint256 indexed acct,
        uint8 title,
        uint256 appointer,
        uint48 startDate,
        uint48 endDate
    );

    event RemoveDirector(uint256 indexed acct);

    //##################
    //##    写接口    ##
    //##################

    // ======== Directors ========

    function setMaxQtyOfDirectors(uint8 max) external;

    function appointOfficer(
        uint256 seqOfVR,
        uint8 title,
        uint256 nominator,
        uint256 candidate
    ) external;

    function removeDirector(uint256 acct) external;

    function takePosition(uint256 seqOfBSR, uint8 titile, uint256 candidate, uint256 nominator) external;

    //##################
    //##    读接口    ##
    //##################

    function maxQtyOfDirectors() external view returns (uint8);

    function qtyOfDirectors() external view returns (uint16);

    function isDirector(uint256 acct) external view returns (bool);

    function isOfficer(uint256 acct) external view returns (bool);

    function whoIs(uint8 title) external view returns (uint40);

    function getDirector(uint256 acct)
        external
        view
        returns(Officer memory director);

    function directors() external view returns (uint256[] memory);

    function boardSeatsOf(uint256 acct) external view returns(uint256);    
}

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
        uint40 indexed acct,
        uint8 title,
        uint40 appointer
    );

    event AddDirector(
        uint40 indexed acct,
        uint8 title,
        uint40 appointer,
        uint48 startDate,
        uint48 endDate
    );

    event RemoveDirector(uint40 indexed acct);

    //##################
    //##    写接口    ##
    //##################

    // ======== Directors ========

    function setMaxQtyOfDirectors(uint8 max) external;

    function appointOfficer(
        uint16 seqOfVR,
        uint8 title,
        uint40 nominator,
        uint40 candidate
    ) external;

    function removeDirector(uint40 acct) external;

    function takePosition(bytes32 bsRule, uint8 titile, uint40 candidate, uint40 nominator) external;

    //##################
    //##    读接口    ##
    //##################

    function maxQtyOfDirectors() external view returns (uint8);

    function qtyOfDirectors() external view returns (uint16);

    function isDirector(uint40 acct) external view returns (bool);

    function isOfficer(uint40 acct) external view returns (bool);

    function whoIs(uint8 title) external view returns (uint40);

    function getDirector(uint40 acct)
        external
        view
        returns(Officer memory director);

    function directors() external view returns (uint40[] memory);

    function boardSeatsOf(uint256 acct) external view returns(uint256);    
}

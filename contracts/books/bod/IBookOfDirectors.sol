// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IMeetingMinutes.sol";

import "../../common/lib/OfficersRepo.sol";

interface IBookOfDirectors is IMeetingMinutes{

    //###################
    //##    events    ##
    //##################

    event AddPosition(bytes32 indexed snOfPos);

    event RemovePosition(uint256 indexed seqOfPos);

    event TakePosition(bytes32 indexed snOfPos);

    event QuitPosition(uint256 indexed seqOfPos, uint256 indexed caller);

    event RemoveOfficer(uint256 indexed seqOfMotion, uint256 indexed seqOfPos, uint256 indexed caller);

    // event ProposeMotionToBoard(uint256 indexed seqOfMotion, uint256 indexed caller);

    // event ExecAction(uint256 indexed contents, bool success);

    //##################
    //##    写接口    ##
    //##################

    function createPosition(bytes32 snOfPos) external;

    function updatePosition(OfficersRepo.Position memory pos) external;

    function removePosition(uint256 seqOfPos) external;

    function takePosition (uint256 seqOfPos, uint caller) external;

    function quitPosition (uint256 seqOfPos, uint caller) external; 

    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos, 
        uint caller
    ) external;

    //##################
    //##    读接口    ##
    //##################
    
    function posExist(uint256 seqOfPos) external view returns (bool flag);

    function isOccupied(uint256 seqOfPos) external view returns (bool flag);

    function getPosList() external view returns(bytes32[] memory list);

    function getPosition(uint256 seqOfPos) external view 
        returns (OfficersRepo.Position memory pos);

    // function getFullPosInfo() external view 
    //     returns(OfficersRepo.Position[] memory list);

    function isOfficer(uint256 acct) external view returns (bool);

    function hasPosition(uint256 acct, uint256 seqOfPos)
        external view returns(bool flag);

    function getPosInHand(uint256 acct) 
        external view returns (uint256[] memory ls);

    function getOfficer(uint256 acct) external view 
        returns(OfficersRepo.Position[] memory ls);

    function getOffList() external view returns (uint256[] memory ls);

    // function getNumOfOfficers() external view returns (uint256 num);

    function isDirector(uint256 acct) external view returns (bool flag);

    function getNumOfDirectors() external view returns (uint256 num);

    function getDirectorsList() external view 
        returns (uint256[] memory list);

    function getBoardSeatsQuota(uint256 acct) external view 
        returns(uint256 quota);

    function getBoardSeatsOccupied(uint acct) external view 
        returns (uint256 num);

}

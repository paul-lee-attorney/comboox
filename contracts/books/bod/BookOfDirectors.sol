// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfDirectors.sol";

import "../../common/components/MeetingMinutes.sol";

contract BookOfDirectors is IBookOfDirectors, MeetingMinutes{
    using OfficersRepo for OfficersRepo.Repo;

    OfficersRepo.Repo private _repo;

    //#################
    //##    写接口    ##
    //#################

    // ==== OptionSetting ====
    function createPosition(bytes32 snOfPos) external onlyKeeper { 
            _repo.createPosition(snOfPos);
        emit AddPosition(snOfPos);
    }

    function updatePosition(OfficersRepo.Position memory pos) external onlyKeeper {
        _repo.addPosition(pos);
        emit AddPosition(OfficersRepo.codifyPosition(pos));
    }

    function removePosition(uint256 seqOfPos) external onlyKeeper {
        if (_repo.removePosition(seqOfPos))
            emit RemovePosition(seqOfPos);
    }

    // ---- Officers ----

    function takePosition (uint256 seqOfPos, uint caller) external onlyKeeper
    {
        bytes32 snOfPos = _repo.takePosition(seqOfPos, caller);
        emit TakePosition(snOfPos);
    }

    function quitPosition (uint256 seqOfPos, uint caller) external onlyDirectKeeper
    {
        if (_repo.quitPosition(seqOfPos, caller))
            emit QuitPosition(seqOfPos, caller);
    }

    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos, 
        uint target, 
        uint caller
    ) external onlyDirectKeeper
    {
        if (_repo.quitPosition(seqOfPos, target))
            emit RemoveOfficer(seqOfMotion, seqOfPos, target, caller);
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Positions ====
    
    function posExist(uint256 seqOfPos) external view returns (bool flag) {
        flag = _repo.posExist(seqOfPos);
    }

    function isOccupied(uint256 seqOfPos) external view returns (bool flag) {
        flag = _repo.isOccupied(seqOfPos);
    } 

    function getPosList() external view returns(bytes32[] memory list) {
        list = _repo.getPosList();
    }

    function getPosition(uint256 seqOfPos) external view 
        returns (OfficersRepo.Position memory pos) 
    {
        pos = _repo.getPosition(seqOfPos);
    }

    function getFullPosInfo() external view 
        returns(OfficersRepo.Position[] memory list) 
    {
        list = _repo.getFullPosInfo();
    }

    // ==== Officers ====

    function isOfficer(uint256 acct) external view returns (bool) {
        return _repo.isOfficer(acct);
    }

    function hasPosition(uint256 acct, uint256 seqOfPos)
        external view returns(bool flag)
    {
        flag = _repo.hasPosition(acct, seqOfPos);
    }

    function getPosInHand(uint256 acct) 
        external view returns (uint256[] memory ls) 
    {
        ls = _repo.getPosInHand(acct);
    }

    function getOfficer(uint256 acct) external view 
        returns(OfficersRepo.Position[] memory ls)
    {
        ls = _repo.getOfficer(acct);
    }

    function getOffList() external view returns (uint256[] memory ls) {
        ls = _repo.getOffList();
    }

    function getNumOfOfficers() external view returns (uint256 num) {
        num = _repo.getNumOfOfficers();
    }

    // ==== Directors ====

    function isDirector(uint256 acct) external view returns (bool flag) {
        flag = _repo.isDirector(acct);
    }

    function getNumOfDirectors() external view returns (uint256 num) {
        num = _repo.getNumOfDirectors();
    }

    function getDirectorsList() external view 
        returns (uint256[] memory list) 
    {
        list = _repo.getDirectorsList();
    }

    function getBoardSeatsQuota(uint256 acct) external view 
        returns(uint256 quota) 
    {
        quota = _repo.getBoardSeatsQuota(acct);
    } 

    function getBoardSeatsOccupied(uint acct) external view 
        returns (uint256 num)
    {
        num = _repo.getBoardSeatsOccupied(acct);
    }
}

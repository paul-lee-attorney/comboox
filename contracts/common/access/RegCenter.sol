// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";

contract RegCenter is IRegCenter {
    using UsersRepo for UsersRepo.Repo;
    using UsersRepo for uint256;
    using DocsRepo for DocsRepo.Repo;
    
    UsersRepo.Repo private _users;
    DocsRepo.Repo private _docs;
    
    constructor() {
        _users.users[0].primeKey = msg.sender;
    }

    // #################
    // ##   modifier  ##
    // #################

    modifier onlyOwner() {
        require(
            msg.sender == _users.users[0].primeKey,
            "RC.mf.OO: not owner"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            msg.sender == _users.users[0].backupKey,
            "RC.mf.OK: not keeper"
        );
        _;
    }

    modifier onlyPrimeKey() {
        require(
            msg.sender == _users.users[_users.userNo[msg.sender]].primeKey,
            "RC.OP: not primeKey"
        );
        _;
    }

    modifier onlyEOA() {
        require(
            !_users.users[_users.userNo[msg.sender]].isCOA,
            "RC.mf.OEOA: not EOA"
        );
        _;
    }

    // ########################
    // ##    Opts Setting    ##
    // ########################

    function setReward(uint256 snOfReward) external onlyOwner {
        _users.reward = snOfReward.rewardParser();
        emit SetReward(snOfReward);
    }

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external onlyOwner {
        _users.users[0].primeKey = newOwner;
        emit TransferOwnership(newOwner);
    }

    function turnOverCenterKey(address newKeeper) external onlyKeeper {
        _users.users[0].backupKey = newKeeper;
        emit TurnOverCenterKey(newKeeper);
    }

    // ##################
    // ##    Points    ##
    // ##################

    function mintPoints(uint256 to, uint216 amt) external onlyOwner {
        _users.users[to].balance += amt;
        emit TransferPoints(0, to, amt);
    }

    function mintAndLockPoints(uint256 snOfLocker, uint216 amt) external onlyOwner {
        if (_users.mintAndLockPoints(snOfLocker, amt))
            emit LockPoints(snOfLocker, amt);
    }

    function transferPoints(uint256 to, uint216 amt)
        external onlyPrimeKey onlyEOA
    {
        if (_users.transferPoints(msg.sender, to, amt))
            emit TransferPoints(_users.userNo[msg.sender], to, amt);
    }

    function lockPoints(uint256 snOfLocker, uint216 amt) 
        external onlyPrimeKey onlyEOA 
    {
        if (_users.lockPoints(msg.sender, snOfLocker, amt))
            emit LockPoints(snOfLocker, amt);
    }

    function releasePoints(uint256 snOfLocker, string memory hashKey, uint8 salt)
        external onlyPrimeKey onlyEOA
    {
        uint256 value = _users.releasePoints(msg.sender, snOfLocker, hashKey, salt);

        if (value > 0)
            emit ReleasePoints(snOfLocker, hashKey, salt, value);
    }

    function withdrawPoints(uint256 snOfLocker, string memory hashKey, uint8 salt)
        external onlyPrimeKey onlyEOA
    {
        uint256 value = _users.withdrawPoints(msg.sender, snOfLocker, hashKey, salt);

        if (value > 0)
            emit WithdrawPoints(snOfLocker, hashKey, salt, value);
    }

    function checkLocker(uint256 snOfLocker) external onlyPrimeKey onlyEOA
        view returns (uint256 value)
    {
        value = _users.checkLocker(msg.sender, snOfLocker);
    }

    // ################
    // ##    Users   ##
    // ################

    function regUser() external {
        _users.regUser(msg.sender);
    }

    function setBackupKey(address bKey) external onlyPrimeKey {
        _users.setBackupKey(msg.sender, bKey);
    }

    // ###############
    // ##    Docs   ##
    // ###############
    function initDocsRepo(address docKeeper) external onlyKeeper {
        if (_docs.init(_users.userNo[docKeeper]))
            emit SetDocKeeper(docKeeper);
    }

    function turnOverKeyOfDocsRepo(address newKeeper) external {
        if (_docs.turnOverRepoKey(_users.userNo[newKeeper], getMyUserNo()))
            emit SetDocKeeper(newKeeper);
    }

    function setTemplate(uint16 typeOfDoc, address body)
        external returns (uint256 snOfDoc)
    {
        snOfDoc = _docs.setTemplate(typeOfDoc, body, getMyUserNo());
        emit SetTemplate(snOfDoc, body);
    }

    function createDoc(uint16 typeOfDoc, uint16 version, uint40 creator) external 
        returns(uint256 snOfDoc, address body)
    {
        (snOfDoc, body) = _docs.createDoc(typeOfDoc, version, creator);
        // emit CreateDoc(snOfDoc, body);
    }

    // ##################
    // ##   Read I/O   ##
    // ##################

    // ==== options ====

    function getOwner() external view returns (address) {
        return _users.users[0].primeKey;
    }

    function getBookeeper() external view returns (address) {
        return _users.users[0].backupKey;
    }

    function getRewardSetting() external view 
        returns (UsersRepo.Reward memory)
    {
        return _users.reward;
    }

    // ==== Users ====

    function isKey(address key) public view returns (bool) {
        return _users.userNo[key] > 0;
    }

    function isCOA(uint256 acct) public view returns(bool) {
        return _users.users[acct].isCOA;
    }

    function getUser() external view returns (UsersRepo.User memory)
    {
        return _users.users[_users.userNo[msg.sender]];
    }

    function getUserNo(address targetAddr) external returns (uint40) {
        return _users.getUserNo(msg.sender, targetAddr);
    }

    function getMyUserNo() public view returns(uint40) {
        return _users.userNo[msg.sender];
    }

    // ==== Docs ====

    function counterOfVersions(uint16 typeOfDoc) external view returns(uint16 seq) {
        seq = _docs.counterOfVersions(typeOfDoc);
    }

    function counterOfDocs(uint16 typeOfDoc, uint16 version) external view returns(uint136 seq) {
        seq = _docs.counterOfDocs(typeOfDoc, version);
    }

    function getDocKeeper () external view returns(uint40 keeper) {
        keeper = _docs.getKeeper();
    }

    // ==== SingleCheck ====

    function getTemplate(uint256 snOfDoc) external view returns (DocsRepo.Doc memory doc) {
        doc = _docs.getTemplate(snOfDoc);
    }

    function docExist(uint256 snOfDoc) external view returns(bool) {
        return _docs.docExist(snOfDoc);
    }

    function getDoc(uint256 snOfDoc) external view returns(DocsRepo.Doc memory doc) {
        doc = _docs.getDoc(snOfDoc);
    }

    function verifyDoc(uint256 snOfDoc) external view returns(bool flag) {
        flag = _docs.verifyDoc(snOfDoc);
    }

    // ==== BatchQuery ====

    function getAllDocsSN() external view returns(uint256[] memory) {
        return _docs.getAllSN();
    }

    function getBodiesList(uint16 typeOfDoc, uint16 version) external view returns(address[] memory) {
        return _docs.getBodiesList(typeOfDoc, version);
    } 

    function getSNList(uint16 typeOfDoc, uint16 version) external view returns(uint256[] memory) {
        return _docs.getSNList(typeOfDoc, version);
    } 

    function getDocsList(uint16 typeOfDoc, uint16 version) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getDocsList(typeOfDoc, version);
    } 

    function getTempsList(uint16 typeOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getTempsList(typeOfDoc);
    }
}

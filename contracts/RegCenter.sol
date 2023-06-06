// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";

contract RegCenter is IRegCenter {
    using DocsRepo for DocsRepo.Repo;
    using DocsRepo for DocsRepo.Head;
    using UsersRepo for UsersRepo.Repo;
    using UsersRepo for uint256;
    
    UsersRepo.Repo private _users;
    DocsRepo.Repo private _docs;

    // userNo => snOfDoc
    mapping(uint => bytes32) private _docSnOfUser;
    
    constructor() {
        _users.regUser(msg.sender);
    }

    // ########################
    // ##    Opts Setting    ##
    // ########################

    function setReward(bytes32 snOfReward) external {
        _users.setReward(snOfReward, msg.sender);
        emit SetReward(snOfReward);
    }

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external {
        _users.transferOwnership(newOwner, msg.sender);
        emit TransferOwnership(newOwner);
    }

    function turnOverCenterKey(address newKeeper) external {
        _users.turnOverCenterKey(newKeeper, msg.sender);
        emit TurnOverCenterKey(newKeeper);
    }

    // ##################
    // ##    Points    ##
    // ##################

    function mintPoints(uint256 to, uint amt) external {
        _users.mintPoints(to, amt, msg.sender);
        emit MintPoints(to, amt);
    }

    function mintAndLockPoints(bytes32 snOfLocker, uint amt) external {
        if (_users.mintAndLockPoints(snOfLocker, amt, msg.sender))
            emit LockPoints(snOfLocker, amt);
    }

    function transferPoints(uint256 to, uint amt) external
    {
        if (_users.transferPoints(msg.sender, to, amt))
            emit TransferPoints(_users.userNo[msg.sender], to, amt);
    }

    function lockPoints(bytes32 snOfLocker, uint amt) 
        external 
    {
        if (_users.lockPoints(snOfLocker, amt, msg.sender))
            emit LockPoints(snOfLocker, amt);
    }

    function releasePoints(bytes32 snOfLocker, string memory hashKey)
        external
    {
        uint256 value = _users.releasePoints(snOfLocker, hashKey, msg.sender);

        if (value > 0)
            emit ReleasePoints(snOfLocker, hashKey, value);
    }

    function withdrawPoints(bytes32 snOfLocker, string memory hashKey)
        external
    {
        uint256 value = _users.withdrawPoints(snOfLocker, hashKey, msg.sender);

        if (value > 0)
            emit WithdrawPoints(snOfLocker, hashKey, value);
    }

    function checkLocker(bytes32 snOfLocker) external
        view returns (uint256 value)
    {
        value = _users.checkLocker(snOfLocker, msg.sender);
    }

    // ################
    // ##    Users   ##
    // ################

    function regUser() external {
        _users.regUser(msg.sender);
    }

    function updateUserInfo(bytes32 info) external {
        _users.updateUserInfo(info, msg.sender);
    }

    function setBackupKey(address bKey) external {
        _users.setBackupKey(bKey, msg.sender);
    }

    // ###############
    // ##    Docs   ##
    // ###############

    function initDocsRepo(address docKeeper) external {
        require(msg.sender == _users.getBookeeper(),
            "RC.IDR: not keeper");
        if (_docs.init(docKeeper))
            emit SetDocKeeper(docKeeper);
    }

    function turnOverKeyOfDocsRepo(address newKeeper) external {
        if (_docs.turnOverRepoKey(newKeeper, msg.sender))
            emit SetDocKeeper(newKeeper);
    }

    function setTemplate(bytes32 snOfDoc, address body) external {
        DocsRepo.Doc memory doc = _docs.setTemplate(snOfDoc, body, msg.sender, getMyUserNo());
        emit SetTemplate(doc.head.typeOfDoc, doc.head.version, doc.body);
    }

    function createDoc(bytes32 snOfDoc, address primeKeyOfOwner) public 
        returns(DocsRepo.Doc memory doc)
    {
        uint40 owner = _users.getUserNo(primeKeyOfOwner, msg.sender);
        doc = _docs.createDoc(snOfDoc, owner);
        emit CreateDoc(doc.head.codifyHead(), doc.body);
    }

    function setDocSnOfUser() external {

        uint myNo = _users.getMyUserNo(msg.sender);

        if (myNo > 0) {
            _docSnOfUser[myNo] = _docs.getSN(msg.sender);
        }

    }

    // ###############
    // ##    Comp   ##
    // ###############

    function createComp() external 
    {
        DocsRepo.Doc[20] memory docs;

        address primeKeyOfOwner = msg.sender;
        uint40 owner = _users.getMyUserNo(primeKeyOfOwner);

        docs[19] = _createDocAtLatestVersion(20, primeKeyOfOwner);
        IAccessControl(docs[19].body).init(
            owner,
            address(this),
            address(this),
            docs[19].body
        );

        IGeneralKeeper(docs[19].body).createCorpSeal();

        docs[9] = _createDocAtLatestVersion(10, primeKeyOfOwner);
        IAccessControl(docs[9].body).init(
            owner,
            docs[19].body,
            address(this),
            docs[19].body
        );
        IGeneralKeeper(docs[19].body).regKeeper(10, docs[9].body);

        uint16 i;
        while (i < 9) {
            docs[i] = _createDocAtLatestVersion(i+1, primeKeyOfOwner);
            IAccessControl(docs[i].body).init(
                owner,
                docs[19].body,
                address(this),
                docs[19].body
            );
            IGeneralKeeper(docs[19].body).regKeeper(i+1, docs[i].body);

            uint16 j = i+10;

            docs[j] = _createDocAtLatestVersion(j+1, primeKeyOfOwner);

            if (j != 16 && j!= 17) {
                IAccessControl(docs[j].body).init(
                    owner,
                    docs[i].body,
                    address(this),
                    docs[19].body
                );                
            } else {
                IAccessControl(docs[j].body).init(
                    owner,
                    primeKeyOfOwner,
                    address(this),
                    docs[19].body
                );
            }
            
            IGeneralKeeper(docs[19].body).regBook(i+1, docs[j].body);
            
            i++;
        }

        IAccessControl(docs[19].body).setDirectKeeper(primeKeyOfOwner);
    }

    function _createDocAtLatestVersion(uint256 typeOfDoc, address primeKeyOfOwner) internal
        returns(DocsRepo.Doc memory doc)
    {
        uint256 latest = counterOfVersions(typeOfDoc);
        bytes32 snOfDoc = bytes32((typeOfDoc << 240) + (latest << 224));
        doc = createDoc(snOfDoc, primeKeyOfOwner);
    }

    // ##################
    // ##   Read I/O   ##
    // ##################

    // ==== options ====

    function getOwner() external view returns (address) {
        return _users.getOwner();
    }

    function getBookeeper() external view returns (address) {
        return _users.getBookeeper();
    }

    function getRewardSetting() external view 
        returns (UsersRepo.Reward memory)
    {
        return _users.getRewardSetting();
    }

    // ==== Users ====

    function isKey(address key) public view returns (bool) {
        return _users.isKey(key);
    }

    function isCOA(uint256 acct) external view returns (bool) {
        return _users.isCOA(acct);
    }

    function getUser() external view returns (UsersRepo.User memory)
    {
        return _users.getUser(msg.sender);
    }

    function getUserNo(address targetAddr) external returns (uint40) {
        return _users.getUserNo(targetAddr, msg.sender);
    }

    function getMyUserNo() public view returns(uint40) {
        return _users.getMyUserNo(msg.sender);
    }

    // ==== Docs ====

    function counterOfVersions(uint256 typeOfDoc) public view returns(uint16 seq) {
        seq = _docs.counterOfVersions(typeOfDoc);
    }

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64 seq) {
        seq = _docs.counterOfDocs(typeOfDoc, version);
    }

    function getDocKeeper () external view returns(address keeper) {
        keeper = _docs.getKeeper();
    }

    // ==== SingleCheck ====

    function getTemplate(bytes32 snOfDoc) external view returns (DocsRepo.Doc memory doc) {
        doc = _docs.getTemplate(snOfDoc);
    }

    function docExist(bytes32 snOfDoc) external view returns(bool) {
        return _docs.docExist(snOfDoc);
    }

    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc) {
        doc = _docs.getDoc(snOfDoc);
    }

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc) {
        doc = _docs.getDoc(_docSnOfUser[acct]);
    }

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag) {
        flag = _docs.verifyDoc(snOfDoc);
    }

    // ==== BatchQuery ====

    function getAllDocsSN() external view returns(bytes32[] memory) {
        return _docs.getAllSN();
    }

    function getBodiesList(uint256 typeOfDoc, uint256 version) external view returns(address[] memory) {
        return _docs.getBodiesList(typeOfDoc, version);
    } 

    function getSNList(uint256 typeOfDoc, uint256 version) external view returns(bytes32[] memory) {
        return _docs.getSNList(typeOfDoc, version);
    } 

    function getDocsList(uint256 typeOfDoc, uint256 version) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getDocsList(typeOfDoc, version);
    } 

    function getTempsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getTempsList(typeOfDoc);
    }
}

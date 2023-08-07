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
    
    constructor() {
        _users.regUser(msg.sender);
    }

    // ########################
    // ##    Opts Setting    ##
    // ########################

    function setPlatformRule(bytes32 snOfRule) external {
        _users.setPlatformRule(snOfRule, msg.sender);
        emit SetPlatformRule(snOfRule);
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

    function mintAndLockPoints(
        uint to, 
        uint amt, 
        uint expireDate, 
        bytes32 hashLock
    ) external {   
        LockersRepo.Head memory head = 
            _users.mintAndLockPoints(
                to, 
                amt, 
                expireDate, 
                hashLock, 
                msg.sender
            );
        emit LockPoints( LockersRepo.codifyHead(head), hashLock);
    }

    function transferPoints(uint256 to, uint amt) external
    {
        _users.transferPoints(msg.sender, to, amt);
        emit TransferPoints(_users.userNo[msg.sender], to, amt);
    }

    function lockPoints(
        uint to, 
        uint amt, 
        uint expireDate, 
        bytes32 hashLock
    ) external {
        LockersRepo.Head memory head = 
            _users.lockPoints(
                to, 
                amt, 
                expireDate, 
                hashLock, 
                msg.sender
            );
        emit LockPoints(LockersRepo.codifyHead(head), hashLock);
    }

    function lockConsideration(
        uint to, 
        uint amt, 
        uint expireDate, 
        address counterLocker, 
        bytes calldata payload, 
        bytes32 hashLock
    ) external {
        LockersRepo.Head memory head =
            _users.lockConsideration(
                to, 
                amt, 
                expireDate, 
                counterLocker, 
                payload, 
                hashLock, 
                msg.sender
            );
        emit LockConsideration(LockersRepo.codifyHead(head), counterLocker, payload, hashLock);
    }

    function pickupPoints(bytes32 hashLock, string memory hashKey) external
    {
        LockersRepo.Head memory head = 
            _users.pickupPoints(hashLock, hashKey, msg.sender);

        if (head.value > 0)
            emit PickupPoints(LockersRepo.codifyHead(head));
    }

    // function pickupConsideration(bytes32 hashLock, string memory hashKey) external 
    // {
    //     LockersRepo.Head memory head =
    //         _users.pickupConsideration(hashLock, hashKey, msg.sender);
    //     emit PickupConsideration(LockersRepo.codifyHead(head));
    // }

    function withdrawPoints(bytes32 hashLock) external
    {
        LockersRepo.Head memory head = 
            _users.withdrawDeposit(hashLock, msg.sender);

        if (head.value > 0)
            emit WithdrawPoints(LockersRepo.codifyHead(head));
    }

    function getLocker(bytes32 hashLock) external
        view returns (LockersRepo.Locker memory locker)
    {
        locker = _users.getLocker(hashLock);
    }

    function getLocksList() external 
        view returns (bytes32[] memory)
    {
        return _users.getLocksList();
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

    function setRoyaltyRule(bytes32 snOfRoyalty) external {
        _users.setRoyaltyRule(snOfRoyalty, msg.sender);
    }

    // ###############
    // ##    Docs   ##
    // ###############

    function setTemplate(uint typeOfDoc, address body) external {
        DocsRepo.Head memory head = _docs.setTemplate(typeOfDoc, body, _users.getMyUserNo(msg.sender));
        emit SetTemplate(head.typeOfDoc, head.version, body);
    }

    function createDoc(
        bytes32 snOfDoc,
        address primeKeyOfOwner
    ) public returns(DocsRepo.Doc memory doc)
    {
        uint40 owner = _users.getUserNo(primeKeyOfOwner, 10000, 1, msg.sender);
        doc = _docs.createDoc(snOfDoc, owner);
        emit CreateDoc(doc.head.codifyHead(), doc.body);
    }

    // #########################
    // ## Comp Deploy Scripts ##
    // #########################

    function createComp(address dk) external 
    {
        address primeKeyOfOwner = msg.sender;
        address rc = address(this);

        address gk = _createDocAtLatestVersion(21, primeKeyOfOwner);
        IAccessControl(gk).init(primeKeyOfOwner, rc, rc, gk);
        IGeneralKeeper(gk).createCorpSeal();

        uint i = 10;
        while (i > 0) {
            address keeper = _deployDoc(i, primeKeyOfOwner, gk, rc, gk);
            if (i == 4 || i == 10)
                _deployDoc(i+10, primeKeyOfOwner, dk, rc, gk); 
            else _deployDoc(i+10, primeKeyOfOwner, keeper, rc, gk);
            i--;
        }
    
        IAccessControl(gk).setDirectKeeper(dk);
    }

    function _deployDoc(
        uint typeOfDoc, 
        address primeKeyOfOwner, 
        address dk, 
        address rc,
        address gk
    ) 
        private returns (address body) 
    {
        body = _createDocAtLatestVersion(typeOfDoc, primeKeyOfOwner);
        IAccessControl(body).init(primeKeyOfOwner, dk, rc, gk);
        if (typeOfDoc < 11) IGeneralKeeper(gk).regKeeper(typeOfDoc, body);
        else IGeneralKeeper(gk).regBook(typeOfDoc - 10, body);
    }


    function _createDocAtLatestVersion(uint256 typeOfDoc, address primeKeyOfOwner) internal
        returns(address body)
    {
        uint256 latest = _docs.counterOfVersions(typeOfDoc);
        bytes32 snOfDoc = bytes32((typeOfDoc << 224) + (latest << 192));
        body = createDoc(snOfDoc, primeKeyOfOwner).body;
    }

    // ##############
    // ## Read I/O ##
    // ##############

    // ==== options ====

    function getOwner() external view returns (address) {
        return _users.getOwner();
    }

    function getBookeeper() external view returns (address) {
        return _users.getBookeeper();
    }

    function getPlatformRule() external view returns(UsersRepo.Rule memory) {
        return _users.getPlatformRule();
    }

    // ==== Users ====

    function isKey(address key) external view returns (bool) {
        return _users.isKey(key);
    }

    function getUser() external view returns (UsersRepo.User memory)
    {
        return _users.getUser(msg.sender);
    }

    function getRoyaltyRule(uint author)external view returns (UsersRepo.Key memory) {
        return _users.getRoyaltyRule(author);
    }

    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40) {
        return _users.getUserNo(targetAddr, fee, author, msg.sender);
    }

    function getMyUserNo() external view returns(uint40) {
        return _users.getMyUserNo(msg.sender);
    }

    // ==== Docs ====

    function counterOfTypes() external view returns(uint32) {
        return _docs.counterOfTypes();
    }

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32) {
        return _docs.counterOfVersions(uint32(typeOfDoc));
    }

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64) {
        return _docs.counterOfDocs(uint32(typeOfDoc), uint32(version));
    }

    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc) {
        doc = _docs.getDoc(snOfDoc);
    }

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc) {
        require (_users.counterOfUsers() >= acct, "RC.getDocByUserNo: userNo not exist");

        doc.body = _users.users[acct].primeKey.pubKey;
        require(_docs.docExist(doc.body), "RC.getDocByUserNo: doc not exist");

        doc.head = _docs.heads[doc.body];
    }

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag) {
        flag = _docs.verifyDoc(snOfDoc);
    }

    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getVersionsList(uint32(typeOfDoc));
    }

    function getDocsList(bytes32 snOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getDocsList(snOfDoc);
    } 

}

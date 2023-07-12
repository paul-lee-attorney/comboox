// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./common/lib/UsersRepo.sol";
import "./common/lib/DocsRepo.sol";

import "./common/access/IAccessControl.sol";

import "./IGeneralKeeper.sol";

interface IRegCenter {

    enum TypeOfDoc{
        ZeroPoint,
        BOCKeeper,      // 1
        BODKeeper,      // 2
        BMMKeeper,      // 3
        BOMKeeper,      // 4
        GMMKeeper,      // 5
        BOIKeeper,      // 6
        BOOKeeper,      // 7
        BOPKeeper,      // 8
        ROSKeeper,      // 9
        SHAKeeper,      // 10
        BOC,            // 11
        BOD,            // 12
        BMM,            // 13
        BOM,            // 14
        GMM,            // 15
        BOI,            // 16
        BOO,            // 17
        BOP,            // 18
        ROS,            // 19
        BOS,            // 20
        GeneralKeeper,  // 21
        IA,             // 22
        SHA,            // 23
        AntiDilution,   // 24
        DragAlong,      // 25
        LockUp,         // 26
        Options,        // 27
        TagAlong        // 28
    }

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Options ====

    event SetReward(bytes32 indexed snOfReward);

    event TransferOwnership(address indexed newOwner);

    event TurnOverCenterKey(address indexed newKeeper);

    // ==== Points ====

    event MintPoints(uint256 indexed to, uint256 indexed amt);

    event TransferPoints(uint256 indexed from, uint256 indexed to, uint256 indexed amt);

    event LockPoints(bytes32 indexed headSn, bytes32 indexed hashLock);

    event LockConsideration(bytes32 indexed headSn, address indexed counterLocker, bytes payload, bytes32 indexed hashLock);

    event PickupPoints(bytes32 indexed headSn);

    event PickupConsideration(bytes32 indexed headSn);

    event WithdrawPoints(bytes32 indexed headSn);

    // ==== Docs ====
    event SetDocKeeper(address indexed keeper);
    
    event SetTemplate(uint256 indexed typeOfDoc, uint256 indexed version, address indexed body);

    event CreateDoc(bytes32 indexed snOfDoc, address indexed body);

    // event CreateComp(uint256 version, uint indexed seqOfDoc, uint indexed creator, address indexed generalKeeper);

    // ##################
    // ##    写端口     ##
    // ##################

    // ==== Opts Setting ====

    function setReward(bytes32 snOfReward) external;

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external;

    function turnOverCenterKey(address newKeeper) external;

    // ==== Mint/Sell Points ====

    function mintPoints(uint256 to, uint amt) external;

    function mintAndLockPoints(uint to, uint amt, uint expireDate, bytes32 hashLock) external;

    // ==== Points Trade ====

    function transferPoints(uint256 to, uint amt) external;

    function lockPoints(uint to, uint amt, uint expireDate, bytes32 hashLock) external;

    function lockConsideration(uint to, uint amt, uint expireDate, address counterLocker, bytes memory payload, bytes32 hashLock) external;

    function pickupPoints(bytes32 hashLock, string memory hashKey) external;

    // function pickupConsideration(bytes32 hashLock, string memory hashKey) external;

    function withdrawPoints(bytes32 hashLock) external;

    function getLocker(bytes32 hashLock) external view 
        returns (LockersRepo.Locker memory locker);

    function getLocksList() external view 
        returns (bytes32[] memory);

    // ==== User ====

    function regUser() external;

    function updateUserInfo(bytes32 info) external;

    function setBackupKey(address bKey) external;

    // ==== Doc ====

    function initDocsRepo(address docKeeper) external;

    function turnOverKeyOfDocsRepo(address newKeeper) external;

    function setTemplate(bytes32 snOfDoc, address body) external;

    // ==== use Docs ====

    function createDoc(bytes32 snOfDoc, address primeKeyOfOwner) external 
        returns(DocsRepo.Doc memory doc);

    function setDocSnOfUser() external;

    // ==== Comp ====

    function createComp() external;

    // #################
    // ##   查询端口   ##
    // #################

    // ==== Options ====

    function getOwner() external view returns (address);

    function getBookeeper() external view returns (address);

    // ---- Points ----

    function getRewardSetting()
        external
        view
        returns (UsersRepo.Reward memory);

    // ==== Users ====

    function isKey(address key) external view returns (bool);

    function isCOA(uint256 acct) external view returns(bool);

    function getUser() external view returns (UsersRepo.User memory);

    function getUserNo(address targetAddr, uint fee) external returns (uint40);

    function getMyUserNo() external returns (uint40);

    // ==== Docs ====

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint16 seq);

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64 seq);

    function getDocKeeper () external view returns(address keeper);

    // ==== SingleCheck ====

    function getTemplate(bytes32 snOfDoc) external view returns (DocsRepo.Doc memory doc);

    function docExist(bytes32 snOfDoc) external view returns(bool);

    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc);

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc);

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag);

    // ==== BatchQuery ====

    function getAllDocsSN() external view returns(bytes32[] memory);

    function getBodiesList(uint256 typeOfDoc, uint256 version) external view returns(address[] memory);

    function getSNList(uint256 typeOfDoc, uint256 version) external view returns(bytes32[] memory);

    function getDocsList(uint256 typeOfDoc, uint256 version) external view returns(DocsRepo.Doc[] memory);

    function getTempsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory);
}

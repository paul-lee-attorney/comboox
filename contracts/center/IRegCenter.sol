// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../comps/IGeneralKeeper.sol";
import "../comps/common/access/IAccessControl.sol";

import "../lib/UsersRepo.sol";
import "../lib/DocsRepo.sol";

import "./ERC20/IERC20.sol";
import "./Oracles/IPriceConsumer.sol";

interface IRegCenter is IERC20, IPriceConsumer{

    enum TypeOfDoc{
        ZeroPoint,
        ROCKeeper,      // 1
        RODKeeper,      // 2
        BMMKeeper,      // 3
        ROMKeeper,      // 4
        GMMKeeper,      // 5
        ROAKeeper,      // 6
        ROOKeeper,      // 7
        ROPKeeper,      // 8
        SHAKeeper,      // 9
        ROC,            // 10
        ROD,            // 11
        MeetingMinutes, // 12
        ROM,            // 13
        ROA,            // 14
        ROO,            // 15
        ROP,            // 16
        ROS,            // 17
        GeneralKeeper,  // 18
        IA,             // 19
        SHA,            // 20 
        AntiDilution,   // 21
        LockUp,         // 22
        Alongs,         // 23
        Options         // 24
    }

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Options ====

    event SetPlatformRule(bytes32 indexed snOfRule);

    event SetFeedRegistry(address indexed registry);

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
    // event SetDocKeeper(address indexed keeper);
    
    event SetTemplate(uint256 indexed typeOfDoc, uint256 indexed version, address indexed body);

    event CreateDoc(bytes32 indexed snOfDoc, address indexed body);

    // event CreateComp(uint256 version, uint indexed seqOfDoc, uint indexed creator, address indexed generalKeeper);

    // ##################
    // ##    写端口     ##
    // ##################

    // ==== Opts Setting ====

    function setPlatformRule(bytes32 snOfRule) external;
    
    function setFeedRegistry(address registry_ ) external;

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external;

    function handoverCenterKey(address newKeeper) external;

    // ==== Mint/Sell Points ====

    function mint(uint256 to, uint amt) external;

    function mintAndLockPoints(uint to, uint amt, uint expireDate, bytes32 hashLock) external;

    // ==== Points Trade ====

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

    function setBackupKey(address bKey) external;

    function setRoyaltyRule(bytes32 snOfRoyalty) external;

    // ==== Doc ====

    function setTemplate(uint typeOfDoc, address body) external;

    function createDoc(bytes32 snOfDoc, address primeKeyOfOwner) external 
        returns(DocsRepo.Doc memory doc);

    // ==== Comp ====

    function createComp(address dk) external;

    // #################
    // ##   查询端口   ##
    // #################

    // ==== Options ====

    function getOwner() external view returns (address);

    function getBookeeper() external view returns (address);

    function getPlatformRule() external returns(UsersRepo.Rule memory);

    // ==== Users ====

    function isKey(address key) external view returns (bool);

    function counterOfUsers() external view returns(uint40);

    function getUser() external view returns (UsersRepo.User memory);

    function getRoyaltyRule(uint author)external view returns (UsersRepo.Key memory);

    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40);

    function getMyUserNo() external returns (uint40);

    // ==== Docs ====

    function counterOfTypes() external view returns(uint32);

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32 seq);

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64 seq);

    function docExist(address body) external view returns(bool);

    function getHeadByBody(address body) external view returns (DocsRepo.Head memory );
    
    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc);

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc);

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag);

    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory);

    function getDocsList(bytes32 snOfDoc) external view returns(DocsRepo.Doc[] memory);
}
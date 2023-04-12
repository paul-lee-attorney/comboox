// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./common/lib/UsersRepo.sol";
import "./common/lib/DocsRepo.sol";

import "./common/access/IAccessControl.sol";

import "./keepers/IGeneralKeeper.sol";

interface IRegCenter {

    enum TypeOfDoc{
        ZeroPoint,
        BOAKeeper,          // 1
        BODKeeper,          // 2
        BOGKeeper,          // 3
        BOHKeeper,          // 4
        BOOKeeper,          // 5
        BOPKeeper,          // 6
        BOSKeeper,          // 7
        ROMKeeper,          // 8
        ROSKeeper,          // 9
        SHAKeeper,          // 10
        BookOfIA,           // 11
        BookOfDirectors,    // 12
        BookOfGM,           // 13
        BookOfSHA,          // 14
        BookOfOptions,      // 15
        BookOfPledges,      // 16
        BookOfShares,       // 17
        RegisterOfMembers,  // 18
        RegisterOfSwaps,    // 19
        GeneralKeeper,      // 20
        InvestmentAgreement,// 21
        ShareholdersAgreement,// 22
        AntiDilution,       // 23
        DragAlong,          // 24
        LockUp,             // 25
        Options,            // 26
        TagAlong            // 27
    }

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Options ====

    event SetReward(uint256 indexed snOfReward);

    event TransferOwnership(address indexed newOwner);

    event TurnOverCenterKey(address indexed newKeeper);

    // ==== Points ====

    event MintPoints(uint256 indexed to, uint256 amt);

    event TransferPoints(uint256 indexed from, uint256 indexed to, uint256 amt);

    event LockPoints(uint256 indexed snOfLocker, uint256 value);

    event ReleasePoints(uint256 indexed sn, string hashKey, uint salt, uint256 value);

    event WithdrawPoints(uint256 indexed sn, string hashKey, uint salt, uint256 value);

    // ==== Docs ====
    event SetDocKeeper(address indexed keeper);
    
    event SetTemplate(uint256 indexed typeOfDoc, uint256 version, address indexed body);

    event CreateDoc(uint256 indexed snOfDoc, address indexed body);

    event CreateComp(address indexed generalKeeper);

    // ##################
    // ##    写端口    ##
    // ##################

    // ==== Opts Setting ====

    function setReward(uint256 snOfReward) external;

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external;

    function turnOverCenterKey(address newKeeper) external;

    // ==== Mint/Sell Points ====

    function mintPoints(uint256 to, uint amt) external;

    function mintAndLockPoints(uint256 sn, uint amt) external;

    function transferPoints(uint256 to, uint amt) external;

    function lockPoints(uint256 sn, uint amt) external;

    function releasePoints(uint256 sn, string memory hashKey, uint salt) external;

    function withdrawPoints(uint256 sn, string memory hashKey, uint salt) external;

    function checkLocker(uint256 sn) external view returns (uint256 value);

    // ==== User ====

    function regUser(uint256 info) external;

    function setBackupKey(address bKey) external;

    // ==== Doc ====

    function initDocsRepo(address docKeeper) external;

    function turnOverKeyOfDocsRepo(address newKeeper) external;

    function setTemplate(uint256 snOfDoc, address body) external;

    function createDoc(uint256 snOfDoc, address primeKeyOfOwner) external 
        returns(DocsRepo.Doc memory doc);

    // ==== Comp ====

    function createComp(address primeKeyOfKeeper) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() external view returns (address);

    function getBookeeper() external view returns (address);

    function getRewardSetting()
        external
        view
        returns (UsersRepo.Reward memory);

    function isKey(address key) external view returns (bool);

    function isCOA(uint256 acct) external view returns(bool);

    function getUser() external view returns (UsersRepo.User memory);

    function getUserNo(address targetAddr) external returns (uint40);

    function getMyUserNo() external returns (uint40);

    // ==== Docs ====

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint16 seq);

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64 seq);

    function getDocKeeper () external view returns(uint40 keeper);

    // ==== SingleCheck ====

    function getTemplate(uint256 snOfDoc) external view returns (DocsRepo.Doc memory doc);

    function docExist(uint256 snOfDoc) external view returns(bool);

    function getDoc(uint256 snOfDoc) external view returns(DocsRepo.Doc memory doc);

    function verifyDoc(uint256 snOfDoc) external view returns(bool flag);

    // ==== BatchQuery ====

    function getAllDocsSN() external view returns(uint256[] memory);

    function getBodiesList(uint256 typeOfDoc, uint256 version) external view returns(address[] memory);

    function getSNList(uint256 typeOfDoc, uint256 version) external view returns(uint256[] memory);

    function getDocsList(uint256 typeOfDoc, uint256 version) external view returns(DocsRepo.Doc[] memory);

    function getTempsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory);
}

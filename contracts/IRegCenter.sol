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
        BOAKeeper,          // 0
        BODKeeper,          // 1
        BOGKeeper,          // 2
        BOHKeeper,          // 3
        BOOKeeper,          // 4
        BOPKeeper,          // 5
        BOSKeeper,          // 6
        ROMKeeper,          // 7
        SHAKeeper,          // 8
        GeneralKeeper,      // 9
        BookOfIA,           // 10
        BookOfDirectors,    // 11
        BookOfGM,           // 12
        BookOfSHA,          // 13
        BookOfOptions,      // 14
        BookOfPledges,      // 15
        BookOfShares,       // 16
        RegisterOfMembers,  // 17
        RegisterOfSwaps,    // 18
        ZeroPoint,          // 19
        InvestmentAgreement,// 20
        ShareholdersAgreement,// 21
        AntiDilution,       // 22
        DragAlong,          // 23
        LockUp,             // 24
        Options,            // 25
        TagAlong            // 26
    }

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Options ====

    event SetReward(uint256 indexed snOfReward);

    event TransferOwnership(address indexed newOwner);

    event TurnOverCenterKey(address indexed newKeeper);

    // ==== Points ====

    event TransferPoints(uint256 indexed from, uint256 indexed to, uint256 amt);

    event LockPoints(uint256 indexed snOfLocker, uint256 value);

    event ReleasePoints(uint256 indexed sn, string hashKey, uint8 salt, uint256 value);

    event WithdrawPoints(uint256 indexed sn, string hashKey, uint8 salt, uint256 value);

    // ==== Docs ====
    event SetDocKeeper(address indexed keeper);
    
    event SetTemplate(uint256 indexed typeOfDoc, uint256 version, address indexed body);

    // event CreateDoc(uint256 indexed snOfDoc, address indexed body);


    // ##################
    // ##    写端口    ##
    // ##################

    // ==== Opts Setting ====

    function setReward(uint256 snOfReward) external;

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external;

    function turnOverCenterKey(address newKeeper) external;

    // ==== Mint/Sell Points ====

    function mintPoints(uint256 to, uint216 amt) external;

    function mintAndLockPoints(uint256 sn, uint216 amt) external;

    function transferPoints(uint256 to, uint216 amt) external;

    function lockPoints(uint256 sn, uint216 amt) external;

    function releasePoints(uint256 sn, string memory hashKey, uint8 salt) external;

    function withdrawPoints(uint256 sn, string memory hashKey, uint8 salt) external;

    function checkLocker(uint256 sn) external view returns (uint256 value);

    // ==== User ====

    function regUser() external;

    function setBackupKey(address bKey) external;

    // ==== Doc ====

    function initDocsRepo(address docKeeper) external;

    function turnOverKeyOfDocsRepo(address newKeeper) external;

    function setTemplate(uint256 snOfDoc, address body) external;

    function createDoc(uint256 snOfDoc, address primeKeyOfOwner) external 
        returns(DocsRepo.Doc memory doc);

    // ==== Comp ====

    function createComp(address primeKeyOfKeeper, address primeKeyOfOwner) external 
        returns(DocsRepo.Doc[19] memory docs);

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

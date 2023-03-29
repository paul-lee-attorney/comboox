// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/UsersRepo.sol";
import "../lib/DocsRepo.sol";

interface IRegCenter {

    enum TypeOfDoc{
        ZeroPoint,          // 0
        GeneralKeeper,      // 1
        BOAKeeper,          // 2
        BODKeeper,          // 3
        BOGKeeper,          // 4
        BOHKeeper,          // 5
        BOOKeeper,          // 6
        BOPKeeper,          // 7
        BOSKeeper,          // 8
        ROMKeeper,          // 9
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
    
    event SetTemplate(uint256 indexed snOfDoc, address indexed body);

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

    function setTemplate(uint16 typeOfDoc, address body)
        external returns (uint256 snOfDoc);

    function createDoc(uint16 typeOfDoc, uint16 version, uint40 creator) external 
        returns(uint256 snOfDoc, address body);

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

    function counterOfVersions(uint16 typeOfDoc) external view returns(uint16 seq);

    function counterOfDocs(uint16 typeOfDoc, uint16 version) external view returns(uint136 seq);

    function getDocKeeper () external view returns(uint40 keeper);

    // ==== SingleCheck ====

    function getTemplate(uint256 snOfDoc) external view returns (DocsRepo.Doc memory doc);

    function docExist(uint256 snOfDoc) external view returns(bool);

    function getDoc(uint256 snOfDoc) external view returns(DocsRepo.Doc memory doc);

    function verifyDoc(uint256 snOfDoc) external view returns(bool flag);

    // ==== BatchQuery ====

    function getAllDocsSN() external view returns(uint256[] memory);

    function getBodiesList(uint16 typeOfDoc, uint16 version) external view returns(address[] memory);

    function getSNList(uint16 typeOfDoc, uint16 version) external view returns(uint256[] memory);

    function getDocsList(uint16 typeOfDoc, uint16 version) external view returns(DocsRepo.Doc[] memory);

    function getTempsList(uint16 typeOfDoc) external view returns(DocsRepo.Doc[] memory);
}

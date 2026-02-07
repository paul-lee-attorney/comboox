// SPDX-License-Identifier: UNLICENSED

/* *
 *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "../../lib/UsersRepo.sol";
import "../../openzeppelin/utils/Address.sol";

interface IGeneralKeeper {

    struct CompInfo {
        uint40 regNum;
        uint48 regDate;
        uint8 typeOfEntity;
        uint8 currency;
        uint8 state;
        bytes18 symbol;
        string name;
    }

    enum TypeOfEntity {
        ZeroPoint,
        PrivateCompany,
        GrowingCompany,
        ListedCompany,
        FullFuncCompany,
        LPFund,
        ListedLPFund,
        OpenFund,
        ListedOpenFund,
        FullFuncFund
    }

    // ###############
    // ##   Event   ##
    // ###############
    event ReceivedEth(address indexed sender, uint amount);

    event RegKeeper(uint indexed title, address indexed keeper, address indexed dk);

    event RegBook(uint indexed title, address indexed book, address indexed dk);

    event ExecAction(bytes32 indexed actionHash);

    // ######################
    // ##   Configuration  ##
    // ######################

    // ---- Config ----

    function setCompInfo (
        uint8 _typeOfEntity,
        uint8 _currency,
        bytes18 _symbol,
        string memory _name
    ) external;

    // function createCorpSeal() external;

    function getCompInfo() external view returns(CompInfo memory);

    function getCompUser() external view returns (UsersRepo.User memory);

    // ---- Keepers ----

    function regKeeper(uint256 title, address keeper) external;

    function isKeeper(address caller) external view returns (bool flag);

    function getKeeper(uint256) external view returns(address keeper);

    function getTitleOfKeeper(address keeper) external view returns (uint);

    // ---- Books ----

    function regBook(uint256 title, address keeper) external;

    function getBook(uint256 title) external view returns (address);

    // ---- Actions ----

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params
    ) external;    
}

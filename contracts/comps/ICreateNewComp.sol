// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

import "./common/access/IAccessControl.sol";
import "./modules/IBaseKeeper.sol";

interface ICreateNewComp {

    event UpdateBank(address indexed bank, address indexed owner);

    event UpdateDocs4GK(uint indexed typeOfEntity, uint indexed seqOfDoc);

    event UpdateDocs4FundKeeper(uint indexed typeOfDoc, uint indexed seqOfDoc);

    event UpdateDocs4Keeper(uint indexed typeOfDoc, uint indexed seqOfDoc);

    event UpdateDocs4Book(uint indexed typeOfDoc, uint indexed seqOfDoc);

    function updateBank(address _bank) external;

    function updateDocs4GK(uint typeOfEntity, uint seqOfDoc) external;
    function getSeqOfDoc4GK(uint typeOfEntity) external view returns(uint);

    function updateDocs4FundKeeper(uint typeOfDoc, uint seqOfDoc) external;
    function getSeqOfDoc4FundKeeper(uint typeOfDoc) external view returns(uint);

    function updateDocs4Keeper(uint typeOfDoc, uint seqOfDoc) external;
    function getSeqOfDoc4Keeper(uint typeOfDoc) external view returns(uint);

    function updateDocs4Book(uint typeOfDoc, uint seqOfDoc) external;
    function getSeqOfDoc4Book(uint typeOfDoc) external view returns(uint);

    function createComp(uint typeOfEntity, address dk) external;
}

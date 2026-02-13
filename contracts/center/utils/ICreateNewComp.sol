// SPDX-License-Identifier: UNLICENSED

/* *
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

pragma solidity ^0.8.24;

import "../../comps/common/access/IAccessControl.sol";

interface ICreateNewComp {

    error CNC_ZeroDK();

    error CNC_InvalidTypeOfEntity(uint typeOfEntity);

    event UpdateBank(address indexed bank, address indexed owner);

    event UpdateDocs4GK(uint indexed typeOfEntity, uint indexed typeOfDoc);

    event UpdateDocs4FundKeeper(uint indexed titleOfKeeper, uint indexed typeOfDoc);

    event UpdateDocs4Keeper(uint indexed titleOfKeeper, uint indexed typeOfDoc);
    
    event UpdateDocs4Book(uint indexed titleOfBook, uint indexed typeOfDoc);

    function updateBank(address _bank) external;

    // function updateDocs4GK(uint typeOfEntity, uint typeOfDoc) external;

    // function getSeqOfDoc4GK(uint typeOfEntity) external view returns(uint);

    function updateDocs4FundKeeper(uint titleOfKeeper, uint typeOfDoc) external;
    
    function getSeqOfDoc4FundKeeper(uint titleOfKeeper) external view returns(uint);

    function updateDocs4Keeper(uint titleOfKeeper, uint typeOfDoc) external;
    
    function getSeqOfDoc4Keeper(uint titleOfKeeper) external view returns(uint);

    function updateDocs4Book(uint titleOfBook, uint typeOfDoc) external;

    function getSeqOfDoc4Book(uint titleOfBook) external view returns(uint);
    
    function createComp(uint typeOfEntity, address dk) external;
}

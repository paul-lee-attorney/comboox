// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "./IBookOfUsers.sol";

contract BookOfUsers is IBookOfUsers {
    using UsersRepo for UsersRepo.Repo;
    using UsersRepo for uint256;
    
    UsersRepo.Repo private _users;
    
    constructor(address keeper) {
        _users.users[0].primeKey.pubKey = msg.sender;
        _users.users[0].backupKey.pubKey = keeper;
        _users.regUser(msg.sender);
        _users.regUser(keeper);
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner(),
            "BOU: not owner");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == getBookeeper(),
            "BOU: not keeper");
        _;
    }

    // #####################
    // ##    Write I/O    ##
    // #####################

    // ==== Config ====

    function setPlatformRule(bytes32 snOfRule) external {
        _users.setPlatformRule(snOfRule, msg.sender);
        emit SetPlatformRule(snOfRule);
    }

    function transferOwnership(address newOwner) external {
        _users.transferOwnership(newOwner, msg.sender);
        emit TransferOwnership(newOwner);
    }

    function handoverCenterKey(address newKeeper) external {
        _users.handoverCenterKey(newKeeper, msg.sender);
        emit TurnOverCenterKey(newKeeper);
    }

    // ==== Users ====

    function _regUser() internal returns(uint){
        UsersRepo.User memory user = _users.regUser(msg.sender);
        return user.primeKey.gift;
    }

    function setBackupKey(address bKey) external {
        _users.setBackupKey(bKey, msg.sender);
    }

    function upgradeBackupToPrime() external {
        _users.upgradeBackupToPrime(msg.sender);
    }

    function setRoyaltyRule(bytes32 snOfRoyalty) external {
        _users.setRoyaltyRule(snOfRoyalty, msg.sender);
    }    

    // ################
    // ##  Read I/O  ##
    // ################

    // ==== Config ====

    function getOwner() public view returns (address) {
        return _users.getOwner();
    }

    function getBookeeper() public view returns (address) {
        return _users.getBookeeper();
    }

    function getPlatformRule() public view returns(UsersRepo.Rule memory) {
        return _users.getPlatformRule();
    }

    // ==== Users ====

    function isKey(address key) external view returns (bool) {
        return _users.isKey(key);
    }

    function counterOfUsers() public view returns(uint40) {
        return _users.counterOfUsers();
    }

    function _getUserByNo(uint acct) internal view returns (UsersRepo.User memory)
    {
        require(acct>0, "BOU: zero userNo");
        return _users.users[acct];
    }

    function getUser() external view returns (UsersRepo.User memory)
    {
        return _users.getUser(msg.sender);
    }

    function _getUserNo(address targetAddr) internal view returns (uint40) {
        return _users.getUserNo(targetAddr);
    }

    function getMyUserNo() public view returns(uint40) {
        return _users.getUserNo(msg.sender);
    }

    function getRoyaltyRule(uint author)public view returns (UsersRepo.Key memory) {
        return _users.getRoyaltyRule(author);
    }
}

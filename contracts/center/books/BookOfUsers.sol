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

import "./IBookOfUsers.sol";
// import "../access/Ownable.sol";
import "../../openzeppelin/proxy/utils/Initializable.sol";
import "../../openzeppelin/proxy/utils/UUPSUpgradeable.sol";

contract BookOfUsers is IBookOfUsers, Initializable, UUPSUpgradeable {
    using UsersRepo for UsersRepo.Repo;
    using UsersRepo for uint256;

    UsersRepo.Repo private _users;

    // ==== UUPSUpgradable ====

    uint[50] private __gap;

    function _initUsers(address keeper) internal {
        require(keeper != address(0), "BOU: zero keeper");
        _users.users[0].primeKey.pubKey = msg.sender;
        _users.users[0].backupKey.pubKey = keeper;
        _users.regUser(msg.sender);
        _users.regUser(keeper);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyKeeper {}

    // #####################
    // ##    Modifiers    ##
    // #####################

    modifier onlyOwner() {
        require(msg.sender == _users.getOwner(),
            "BOU: not owner");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == _users.getBookeeper(),
            "BOU: not keeper");
        _;
    }

    // #####################
    // ##    Write I/O    ##
    // #####################

    // ==== Config ====

    function transferOwnership(address newOwner) external {
        _users.transferOwnership(newOwner);
        emit TransferOwnership(newOwner);
    }

    function handoverCenterKey(address newKeeper) external {
        _users.handoverCenterKey(newKeeper);
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

    // ==== Royalty & Coupon ====

    function setPlatformRule(bytes32 snOfRule) external {
        _users.setPlatformRule(snOfRule);
        emit SetPlatformRule(snOfRule);
    }

    function setRoyaltyRule(bytes32 snOfRoyalty) external {
        _users.setRoyaltyRule(snOfRoyalty, msg.sender);
    }

    function _addCouponOnce(address targetAddr) internal {
        _users.addCouponOnce(targetAddr);
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
    
    function isUserNo(uint acct) public view returns (bool) {
        return _users.isUserNo(acct);
    }

    function _getUserNo(address targetAddr) internal view returns (uint40) {
        return _users.getUserNo(targetAddr);
    }

    function counterOfUsers() external view returns(uint) {
        return _users.counterOfUsers();
    }

    function getUserNoList() external view returns(uint[] memory) {
        return _users.getUserNoList();
    }

    function _getUser(address targetAddr) internal view returns (UsersRepo.User memory)
    {
        return _users.getUser(targetAddr);
    }

    function _getUserByNo(uint acct) internal view returns (UsersRepo.User memory usr)
    {
        if (_users.isUserNo(acct)) {
            usr = _users.users[acct];
        } else revert ("BOU: not registered");
    }

    function getRoyaltyRule(uint author) public view returns (UsersRepo.Key memory) {
        return _users.getRoyaltyRule(author);
    }

    function usedKey(address key) external view returns (bool) {
        return _users.usedKey(key);
    }

    function isPrimeKey(address key) external view returns (bool) {
        return _users.isPrimeKey(key);
    }

}

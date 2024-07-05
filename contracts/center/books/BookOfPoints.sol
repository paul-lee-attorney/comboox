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

import "./IBookOfPoints.sol";
import "../ERC20/ERC20.sol";
import "./BookOfUsers.sol";

contract BookOfPoints is IBookOfPoints, ERC20("ComBooxPoints", "CBP"), BookOfUsers {
    using LockersRepo for LockersRepo.Repo;

    mapping(address => uint256) private _coffers;
    LockersRepo.Repo private _lockers;

    constructor(address keeper) BookOfUsers(keeper){}
    
    // ##################
    // ##  Mint & Lock ##
    // ##################

    function mint(uint256 to, uint amt) external onlyOwner {
        _mint(_getUserByNo(to).primeKey.pubKey, amt);
    }

    function burn(uint amt) external {
        _burn(msg.sender, amt);
    }

    function _prepareLockerHead(
        uint to,
        uint amt,
        uint expireDate
    ) private view returns (LockersRepo.Head memory head) {
        require((amt >> 128) == 0, 
            "UR.prepareLockerHead: amt overflow");

        head = LockersRepo.Head({
            from: getMyUserNo(),
            to: uint40(to),
            expireDate: uint48(expireDate),
            value: uint128(amt)
        });
    }

    function _lockPoints(
        uint to,
        uint amt,
        uint expireDate,
        bytes32 hashLock
    ) private {
        LockersRepo.Head memory head = 
            _prepareLockerHead(to, amt, expireDate);
        _lockers.lockPoints(head, hashLock);
        emit LockPoints(LockersRepo.codifyHead(head), hashLock);
    }

    function _lockPointsInCoffer(address beneficiary, uint value) private {
        _coffers[beneficiary] += value;
        _coffers[address(0)] += value;
        emit LockPointsInCoffer(beneficiary, value);
    }

    function mintAndLockPoints(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        bytes32 hashLock
    ) external onlyOwner {
        _lockPoints(to, amtOfGLee, expireDate, hashLock);
        uint amt = amtOfGLee * 10 ** 9;
        _mint(address(this), amt);
        _lockPointsInCoffer(msg.sender, amt);
    }

    function lockPoints(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        bytes32 hashLock
    ) external {
        _lockPoints(to, amtOfGLee, expireDate, hashLock);
        uint amt = amtOfGLee * 10 ** 9;
        _transfer(msg.sender, address(this), amt);
        _lockPointsInCoffer(msg.sender, amt);
    }

    function lockConsideration(
        uint to, 
        uint amtOfGLee, 
        uint expireDate, 
        address counterLocker, 
        bytes calldata payload, 
        bytes32 hashLock
    ) external {

        LockersRepo.Head memory head =
            _prepareLockerHead(to, amtOfGLee, expireDate);
        LockersRepo.Body memory body = LockersRepo.Body({
            counterLocker: counterLocker,
            payload: payload
        });
        
        _lockers.lockConsideration(head, body, hashLock);

        _lockPointsInCoffer(msg.sender, amtOfGLee * 10 ** 9);

        emit LockConsideration(LockersRepo.codifyHead(head), counterLocker, payload, hashLock);
    }

    function _pickupPointsFromCoffer(address from, address to, uint amt) private {
        require(_coffers[from] >= amt, 
            "BOP.pickupPointsFromCoffer: insufficient balance");
        _coffers[from] -= amt;
        _coffers[address(0)] -= amt;
        _transfer(address(this), to, amt);
        emit PickupPointsFromCoffer(from, to, amt);
    }

    function pickupPoints(bytes32 hashLock, string memory hashKey) external
    {
        uint caller = getMyUserNo();

        LockersRepo.Head memory head = 
            _lockers.pickupPoints(hashLock, hashKey, caller);

        if (head.value > 0) {
            _pickupPointsFromCoffer(
                _getUserByNo(head.from).primeKey.pubKey,
                _getUserByNo(head.to).primeKey.pubKey,
                head.value * 10 ** 9
            );
        }
    }

    function _withdrawPoints(address from, uint amt) private {
        require(_coffers[from] >= amt, 
            "RC.withdrawPoints: insufficient balance");
        _coffers[from] -= amt;
        _coffers[address(0)] -= amt;
        _transfer(address(this), from, amt);
        emit WithdrawPointsFromLocker(from, amt);
    }

    function withdrawPoints(bytes32 hashLock) external
    {
        uint caller = getMyUserNo();
        LockersRepo.Head memory head = 
            _lockers.withdrawDeposit(hashLock, caller);

        if (head.value > 0) {
            _withdrawPoints(
                msg.sender,
                head.value * 10 ** 9
            );
            emit WithdrawPoints(LockersRepo.codifyHead(head));
        }
    }

    // ################
    // ##  Read I/O  ##
    // ################

    function getDepositAmt(address from) external view returns(uint) {
        return _coffers[from];
    }

    function getLocker(bytes32 hashLock) external
        view returns (LockersRepo.Locker memory locker)
    {
        locker = _lockers.getLocker(hashLock);
    }

    function getLocksList() external 
        view returns (bytes32[] memory)
    {
        return _lockers.getSnList();
    }
}

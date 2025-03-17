// SPDX-License-Identifier: UNLICENSED

/* *
 *
 * Copyright (c) 2021-2025 LI LI @ JINGTIAN & GONGCHENG.
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

import "./ICashier.sol";

import "../../common/access/RoyaltyCharge.sol";

contract Cashier is ICashier, RoyaltyCharge {
    using UsdLockersRepo for UsdLockersRepo.Repo;
    
    mapping(address => uint) _coffers;
    UsdLockersRepo.Repo private _lockers;

    //###############
    //##   Write   ##
    //###############

    function _usd() private view returns(IUSDC) {
        return IUSDC(_gk.getBook(12));
    }

    function _transferWithAuthorization(TransferAuth memory auth) private {
        _usd().transferWithAuthorization(
            auth.from, 
            address(this), 
            auth.value,
            auth.validAfter, 
            auth.validBefore, 
            auth.nonce, 
            auth.v,
            auth.r,
            auth.s
        );
    }

    function collectUsd(TransferAuth memory auth) external anyKeeper {
        _transferWithAuthorization(auth);
        emit ReceiveUsd(auth.from, auth.value);
    }

    function forwardUsd(TransferAuth memory auth, address to) external anyKeeper{
        _transferWithAuthorization(auth);
        require(_usd().transfer(to, auth.value),
            "Cashier.forwardUsd: transfer failed");

        emit ForwardUsd(auth.from, to, auth.value);
    }

    function custodyUsd(TransferAuth memory auth) external anyKeeper {
        _transferWithAuthorization(auth);
        _coffers[auth.from] += auth.value;
        _coffers[address(0)] += auth.value;
        
        emit CustodyUsd(auth.from, auth.value);
    }

    function releaseUsd(address from, address to, uint amt) external anyKeeper {
        require(_coffers[from] >= amt,
            "Cashier.ReleaseUsd: insufficient amt");

        _coffers[from] -= amt;
        _coffers[address(0)] -= amt;

        emit ReleaseUsd(from, to, amt);

        require(_usd().transfer(to, amt),
            "Cashier.releaseUsd: transfer failed");
    }

    function transferUsd(address to, uint amt) external anyKeeper {

        require(balanceOfComp() >= amt,
            "Cashier.transferUsd: insufficient amt");
        
        emit TransferUsd(to, amt);

        require(_usd().transfer(to, amt),
            "Cashier.transferUsd: transfer failed");        
    }

    // ---- Cash Locker ----

    function lockUsd(
        TransferAuth memory auth, address to, uint expireDate, bytes32 lock
    ) external onlyDK {

        _transferWithAuthorization(auth);

        _coffers[auth.from] += auth.value;
        _coffers[address(1)] += auth.value;

        _lockers.lockUsd(auth.from, to, expireDate, auth.value, lock);

        emit LockUsd(auth.from, to, auth.value, expireDate, lock);
    }

    function lockConsideration(
        TransferAuth memory auth, address to, uint expireDate,  
        address counterLocker, bytes calldata payload, bytes32 hashLock
    ) external onlyDK {

        _transferWithAuthorization(auth);

        _lockers.lockConsideration(
            auth.from, to, expireDate, auth.value, 
            counterLocker, payload, hashLock
        );

        emit LockConsideration(auth.from, to, auth.value, expireDate, hashLock);
    }

    function unlockUsd(
        bytes32 lock, string memory key, address msgSender
    ) external onlyDK {

        UsdLockersRepo.Head memory head =
            _lockers.releaseUsd(lock, key, msgSender);

        require(_coffers[head.from] >= head.amt,
            "Cashier.releaseUsd: insufficient amt");

        _coffers[head.from] -= head.amt;
        _coffers[address(1)] -= head.amt;

        emit UnlockUsd(head.from, head.to, head.amt, lock);

        require(_usd().transfer(head.to, head.amt),
            "Cashier.releaseUsd: transfer failed");
    }

    function withdrawUsd(bytes32 lock, address msgSender) external onlyDK {

        UsdLockersRepo.Head memory head =
            _lockers.withdrawUsd(lock, msgSender);

        require(_coffers[head.from] >= head.amt,
            "Cashier.withdrawUsd: insufficient amt");

        _coffers[head.from] -= head.amt;
        _coffers[address(1)] -= head.amt;

        emit WithdrawUsd(head.from, head.amt, lock);

        require(_usd().transfer(head.from, head.amt),
            "Cashier.withdrawUsd: transfer failed");
    }

    //##################
    //##   Read I/O   ##
    //##################

    function isLocked(bytes32 lock) external view returns(bool) {
        return _lockers.isLocked(lock);
    }

    function counterOfLockers() external view returns(uint) {
        return _lockers.counterOfLockers();
    }

    function getHeadOfLocker(bytes32 lock) external view returns(UsdLockersRepo.Head memory) {
        return _lockers.getHeadOfLocker(lock);
    }

    function getLocker(bytes32 lock) external view returns(UsdLockersRepo.Locker memory) {
        return _lockers.getLocker(lock);
    }

    function getLockersList() external view returns (bytes32[] memory) {
        return _lockers.getSnList();
    }

    function custodyOf(address acct) external view returns(uint) {
        return _coffers[acct];
    }

    function totalCustody() external view returns(uint) {
        return _coffers[address(0)];
    }

    function totalLocked() external view returns(uint) {
        return _coffers[address(1)];
    }

    function balanceOfComp() public view returns(uint) {
        uint amt = _usd().balanceOf(address(this));        
        return amt - _coffers[address(0)] - _coffers[address(1)];
    }
}

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
    
    mapping(address => uint) private _coffers;
    // userNo => balance
    mapping(uint => uint) private _lockers;

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

    function collectUsd(TransferAuth memory auth, bytes32 remark) external anyKeeper {
        _transferWithAuthorization(auth);
        emit ReceiveUsd(auth.from, auth.value, remark);
    }

    function forwardUsd(TransferAuth memory auth, address to, bytes32 remark) external anyKeeper{
        _transferWithAuthorization(auth);
        emit ForwardUsd(auth.from, to, auth.value, remark);

        require(_usd().transfer(to, auth.value),
            "Cashier.forwardUsd: transfer failed");
    }

    function custodyUsd(TransferAuth memory auth, bytes32 remark) external anyKeeper {
        _transferWithAuthorization(auth);
        _coffers[auth.from] += auth.value;
        _coffers[address(0)] += auth.value;
        
        emit CustodyUsd(auth.from, auth.value, remark);
    }

    function releaseUsd(address from, address to, uint amt, bytes32 remark) external anyKeeper {
        require(_coffers[from] >= amt,
            "Cashier.ReleaseUsd: insufficient amt");

        _coffers[from] -= amt;
        _coffers[address(0)] -= amt;

        emit ReleaseUsd(from, to, amt, remark);

        require(_usd().transfer(to, amt),
            "Cashier.releaseUsd: transfer failed");
    }

    function transferUsd(address to, uint amt, bytes32 remark) external anyKeeper {

        require(balanceOfComp() >= amt,
            "Cashier.transferUsd: insufficient amt");
        
        emit TransferUsd(to, amt, remark);

        require(_usd().transfer(to, amt),
            "Cashier.transferUsd: transfer failed");        
    }

    function distributeUsd(uint amt) external {

        require(msg.sender == address(_gk), 
            "Cashier.DistrUsd: not GK");

        require(balanceOfComp() >= amt,
            "Cashier.DistrUsd: insufficient amt");

        IRegisterOfMembers _rom = _gk.getROM();

        uint[] memory members = _rom.membersList();
        uint len = members.length;

        uint totalPoints = _rom.ownersPoints().points;
        uint sum = 0;

        while (len > 1) {
            uint member = members[len - 1];
            uint pointsOfMember = _rom.pointsOfMember(member).points;
            uint value = pointsOfMember * amt / totalPoints;

            _lockers[member] += value;
            _lockers[0] += value;

            sum += value;

            len--;
        }

        _lockers[members[0]] += (amt - sum);
        _lockers[0] += (amt - sum);

        emit DistributeUsd(amt);
    }

    function pickupUsd() external {
        
        uint caller = _msgSender(msg.sender, 18000);
        uint value = _lockers[caller];

        if (value > 0) {

            _lockers[caller] = 0;
            _lockers[0] -= value;

            emit PickupUsd(msg.sender, caller, value);

            require(_usd().transfer(msg.sender, value),
                "Cashier.PickupUsd: transfer failed");

        } else revert("Cashier.pickupDeposit: no balance");
    }

    //##################
    //##   Read I/O   ##
    //##################

    function custodyOf(address acct) external view returns(uint) {
        return _coffers[acct];
    }

    function totalEscrow() external view returns(uint) {
        return _coffers[address(0)];
    }

    function totalDeposits() external view returns(uint) {
        return _lockers[0];
    }

    function depositOfMine(uint user) external view returns(uint) {
        return _lockers[user];
    }

    function balanceOfComp() public view returns(uint) {
        uint amt = _usd().balanceOf(address(this));        
        return amt - _coffers[address(0)] - _lockers[0];
    }
}

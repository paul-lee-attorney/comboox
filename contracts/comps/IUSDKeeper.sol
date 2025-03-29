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

import "./keepers/IUsdROMKeeper.sol";
import "./keepers/IUsdROAKeeper.sol";
import "./keepers/IUsdLOOKeeper.sol";
import "./keepers/IUsdROOKeeper.sol";

import "./books/cashier/ICashier.sol";

interface IUSDKeeper {

    function payInCapital(
        ICashier.TransferAuth memory auth, uint seqOfShare, uint paid
    ) external;

    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, address to
    ) external;

    // ---- UsdLOO ----

    function placeInitialOffer(
        uint classOfShare,uint execHours, uint paid,
        uint price,uint seqOfLR
    ) external;

    function withdrawInitialOffer(
        uint classOfShare, uint seqOfOrder, uint seqOfLR
    ) external;

    function placeSellOrder(
        uint seqOfClass, uint execHours, uint paid,
        uint price, uint seqOfLR
    ) external;

    function withdrawSellOrder(
        uint classOfShare, uint seqOfOrder
    ) external;

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, uint paid, uint price, uint execHours
    ) external;

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, uint paid, uint execHours
    ) external;

    function withdrawBuyOrder(
        uint classOfShare, uint seqOfOrder
    ) external;

    // ---- UsdROO ----

    function payOffSwap(
        ICashier.TransferAuth memory auth, uint256 seqOfOpt, uint256 seqOfSwap, address to
    ) external;

    function payOffRejectedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, uint seqOfSwap, address to
    ) external;

    // ---- Read I/O ----

    function isKeeper(address msgSender) external view returns(bool);

    // ---- Cash Locker ----

    // function lockUsd(
    //     ICashier.TransferAuth memory auth, address to, uint expireDate, bytes32 lock
    // ) external;

    // function lockConsideration(
    //     ICashier.TransferAuth memory auth, address to, uint expireDate, 
    //     address counterLocker, bytes calldata payload, bytes32 hashLock
    // ) external;

    // function unlockUsd(bytes32 lock, string memory key) external;

    // function withdrawUsd(bytes32 lock) external;

    // ---- RegInvestor ----

    function regInvestor(address bKey, uint groupRep, bytes32 idHash) external;

}
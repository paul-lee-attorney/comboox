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

import "./common/access/AccessControl.sol";
import "./IUSDKeeper.sol";

// _gk.getKeeper(15)
contract USDKeeper is IUSDKeeper, AccessControl {

    // ---- Keeper ----

    function isKeeper(address msgSender) external view returns(bool) {
        
        if (msgSender == address(_gk)) {
            return true;
        }
        
        uint i = 1;
        address keeper = _gk.getKeeper(i);
 
        while(keeper != address(0)) {
            if (keeper == msgSender) {
                return true;
            }
            i++;
            keeper = _gk.getKeeper(i);
        }

        return false;
    }

    // ---- API ----

    function payInCapital(ICashier.TransferAuth memory auth, uint seqOfShare, uint paid) external {
        IUsdROMKeeper(_gk.getKeeper(11)).payInCapital(auth, seqOfShare, paid, msg.sender);
    }

    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, address to
    ) external {
        IUsdROAKeeper(_gk.getKeeper(12)).payOffApprovedDeal(
            auth, ia, seqOfDeal, to, msg.sender
        );
    }

    // ---- UsdLOO ----

    function placeInitialOffer(
        uint classOfShare,uint execHours, uint paid,
        uint price,uint seqOfLR
    ) external {
        IUsdLOOKeeper(_gk.getKeeper(13)).placeInitialOffer(
            msg.sender, classOfShare, execHours,
            paid, price, seqOfLR
        );
    }

    function withdrawInitialOffer(
        uint classOfShare, uint seqOfOrder, uint seqOfLR
    ) external {
        IUsdLOOKeeper(_gk.getKeeper(13)).withdrawInitialOffer(
            msg.sender, classOfShare, seqOfOrder, seqOfLR
        );
    }

    function placeSellOrder(
        uint seqOfClass, uint execHours, uint paid,
        uint price, uint seqOfLR
    ) external {
        IUsdLOOKeeper(_gk.getKeeper(13)).placeSellOrder(
            msg.sender, seqOfClass, execHours, paid,
            price, seqOfLR 
        );
    }

    function withdrawSellOrder(
        uint classOfShare, uint seqOfOrder
    ) external {
        IUsdLOOKeeper(_gk.getKeeper(13)).withdrawSellOrder(
            msg.sender, classOfShare, seqOfOrder
        );
    }

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, 
        uint paid, uint price, uint execHours
    ) external {
        IUsdLOOKeeper(_gk.getKeeper(13)).placeBuyOrder(
            auth, msg.sender, classOfShare, paid, price, execHours
        );
    }

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, 
        uint paid, uint execHours
    ) external{
        IUsdLOOKeeper(_gk.getKeeper(13)).placeMarketBuyOrder(
            auth, msg.sender, classOfShare, paid, execHours
        );
    }

    function withdrawBuyOrder(
        uint classOfShare, uint seqOfOrder
    ) external {
        IUsdLOOKeeper(_gk.getKeeper(13)).withdrawBuyOrder(
            msg.sender, classOfShare, seqOfOrder
        );
    }

    // ---- UsdROO ----

    function payOffSwap(
        ICashier.TransferAuth memory auth, uint256 seqOfOpt, uint256 seqOfSwap, address to
    ) external {
        IUsdROOKeeper(_gk.getKeeper(14)).payOffSwap(
            auth, seqOfOpt, seqOfSwap, to, msg.sender
        );
    }

    function payOffRejectedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, uint seqOfSwap, address to
    ) external {
        IUsdROOKeeper(_gk.getKeeper(14)).payOffRejectedDeal(
            auth, ia, seqOfDeal, seqOfSwap, to, msg.sender
        );
    }

    // ---- RegInvestor ----

    function regInvestor(address bKey, uint groupRep, bytes32 idHash) external {
        ILOOKeeper(_gk.getKeeper(10)).regInvestor(
            msg.sender, bKey, groupRep, idHash
        );
    }


}
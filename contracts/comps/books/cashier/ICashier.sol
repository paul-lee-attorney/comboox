// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
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

pragma solidity ^0.8.24;

import "../../../center/utils/MockUSDC/IUSDC.sol";

import "../../../lib/RulesParser.sol";
import "../../../lib/WaterfallsRepo.sol";
import "../../../lib/InterfacesHub.sol";

/// @title ICashier
/// @notice Cashier interface for USDC custody, transfers, and waterfall distributions.
interface ICashier {

    struct TransferAuth{
        address from;
        address to;
        uint256 value;
        uint256 validAfter;
        uint256 validBefore;
        bytes32 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Emitted when USDC is received into the contract.
    /// @param from Sender address.
    /// @param amt Amount in smallest unit.
    /// @param remark Business remark.
    event ReceiveUsd(address indexed from, uint indexed amt, bytes32 indexed remark);

    /// @notice Emitted when USDC is forwarded from one address to another.
    /// @param from Sender address.
    /// @param to Recipient address.
    /// @param amt Amount in smallest unit.
    /// @param remark Business remark.
    event ForwardUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark);

    /// @notice Emitted when USDC is moved into custody ledger.
    /// @param from Sender address.
    /// @param amt Amount in smallest unit.
    /// @param remark Business remark.
    event CustodyUsd(address indexed from, uint indexed amt, bytes32 indexed remark);

    /// @notice Emitted when USDC is released from custody to a recipient.
    /// @param from Custody owner.
    /// @param to Recipient address.
    /// @param amt Amount in smallest unit.
    /// @param remark Business remark.
    event ReleaseUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark);

    /// @notice Emitted when USDC is transferred from contract balance.
    /// @param to Recipient address.
    /// @param amt Amount in smallest unit.
    /// @param remark Business remark.
    event TransferUsd(address indexed to, uint indexed amt, bytes32 indexed remark);

    /// @notice Emitted when a waterfall class is initialized.
    /// @param class Share class id.
    /// @param principal Principal amount.
    /// @param initDate Initialization date (timestamp).
    event InitClass(uint indexed class, uint indexed principal, uint indexed initDate);

    /// @notice Emitted when principal is redeemed for a class.
    /// @param class Share class id.
    /// @param principal Principal amount.
    event RedeemClass(uint indexed class, uint indexed principal);

    /// @notice Emitted when profits are distributed.
    /// @param amt Distribution amount.
    /// @param seqOfDR Distribution rule sequence.
    /// @param seqOfDistr Distribution sequence.
    event DistrProfits(uint indexed amt, uint indexed seqOfDR, uint indexed seqOfDistr);

    /// @notice Emitted when income is distributed.
    /// @param amt Distribution amount.
    /// @param seqOfDR Distribution rule sequence.
    /// @param fundManager Fund manager user number.
    /// @param seqOfDistr Distribution sequence.
    event DistrIncome(uint indexed amt, uint indexed seqOfDR, uint fundManager, uint indexed seqOfDistr);

    /// @notice Emitted when a user deposit is recorded.
    /// @param amt Amount in smallest unit.
    /// @param user User number.
    /// @param remark Business remark.
    event DepositUsd(uint indexed amt, uint indexed user, bytes32 indexed remark);

    /// @notice Emitted when a user picks up USDC.
    /// @param msgSender Message sender.
    /// @param caller Caller user number.
    /// @param value Amount in smallest unit.
    event PickupUsd(address indexed msgSender, uint indexed caller, uint indexed value);

    //###############
    //##   Write   ##
    //###############

    /// @notice Collect USDC from `auth.from` into custody.
    /// @param auth Transfer authorization (EIP-3009 style).
    /// @param remark Business remark.
    function collectUsd(TransferAuth memory auth, bytes32 remark) external;

    /// @notice Forward USDC from `auth.from` to `to`.
    /// @param auth Transfer authorization.
    /// @param to Recipient address.
    /// @param remark Business remark.
    function forwardUsd(TransferAuth memory auth, address to, bytes32 remark) external;

    /// @notice Add USDC into custody ledger using authorization.
    /// @param auth Transfer authorization.
    /// @param remark Business remark.
    function custodyUsd(TransferAuth memory auth, bytes32 remark) external;

    /// @notice Release USDC from custody to a recipient.
    /// @param from Custody owner.
    /// @param to Recipient address.
    /// @param amt Amount in USDC smallest unit.
    /// @param remark Business remark.
    function releaseUsd(address from, address to, uint amt, bytes32 remark) external;

    /// @notice Transfer USDC from contract balance to recipient.
    /// @param to Recipient address.
    /// @param amt Amount in USDC smallest unit.
    /// @param remark Business remark.
    function transferUsd(address to, uint amt, bytes32 remark) external;

    /// @notice Initialize waterfall class with principal.
    /// @param class Share class id.
    /// @param principal Principal amount.
    function initClass(uint class, uint principal) external;

    /// @notice Redeem principal for a class.
    /// @param class Share class id.
    /// @param principal Principal amount.
    function redeemClass(uint class, uint principal) external;

    /// @notice Distribute profits by waterfall rule.
    /// @param amt Amount in USDC smallest unit.
    /// @param seqOfDR Distribution rule sequence.
    /// @return mlist Member drops list.
    function distrProfits(uint amt, uint seqOfDR) external returns(
        WaterfallsRepo.Drop[] memory mlist
    );

    /// @notice Distribute income with manager carry.
    /// @param amt Amount in USDC smallest unit.
    /// @param seqOfDR Distribution rule sequence.
    /// @param para Extra parameter (e.g., fundManager id).
    /// @return mlist Member drops list.
    /// @return slist Share drops list.
    function distrIncome(uint amt, uint seqOfDR, uint para) external returns(
        WaterfallsRepo.Drop[] memory mlist, WaterfallsRepo.Drop[] memory slist
    );

    /// @notice Deposit USDC into user escrow.
    /// @param amt Amount in USDC smallest unit.
    /// @param user User number.
    /// @param remark Business remark.
    function depositUsd(uint amt, uint user, bytes32 remark) external;

    /// @notice Withdraw caller's escrow balance.
    function pickupUsd() external; 

    //##################
    //##   Read I/O   ##
    //##################

    /// @notice Get custody balance of an address.
    /// @param acct Account address.
    /// @return Balance in USDC smallest unit.
    function custodyOf(address acct) external view returns(uint);

    /// @notice Get total escrowed amount.
    /// @return Total escrow in USDC smallest unit.
    function totalEscrow() external view returns(uint);

    /// @notice Get total deposits amount.
    /// @return Total deposits in USDC smallest unit.
    function totalDeposits() external view returns(uint);

    /// @notice Get deposit of a user.
    /// @param user User number.
    /// @return Deposit in USDC smallest unit.
    function depositOfMine(uint user) external view returns(uint);    

    /// @notice Get contract USDC balance.
    /// @return Balance in USDC smallest unit.
    function balanceOfComp() external view returns(uint);

    // ==== Waterfalls Distribution ====

    // ---- Drop ----

    /// @notice Get a specific drop by path.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    /// @param class Share class id.
    /// @param seqOfShare Share sequence.
    /// @return drop Drop record.
    function getDrop(
        uint seqOfDistr, uint member, uint class, uint seqOfShare
    ) external view returns(WaterfallsRepo.Drop memory drop);

    // ---- Flow ----

    /// @notice Get flow summary info.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    /// @param class Share class id.
    /// @return info Flow summary drop.
    function getFlowInfo(
        uint seqOfDistr, uint member, uint class
    ) external view returns(WaterfallsRepo.Drop memory info);

    /// @notice Get drops in a flow.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    /// @param class Share class id.
    /// @return list Drop list.
    function getDropsOfFlow(
        uint seqOfDistr, uint member, uint class
    ) external view returns(WaterfallsRepo.Drop[] memory list);

    // ---- Creek ----

    /// @notice Get creek summary info.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    /// @return info Creek summary drop.
    function getCreekInfo(
        uint seqOfDistr, uint member
    ) external view returns(WaterfallsRepo.Drop memory info);

    /// @notice Get drops in a creek.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    /// @return list Drop list.
    function getDropsOfCreek(
        uint seqOfDistr, uint member
    ) external view returns(WaterfallsRepo.Drop[] memory list);

    // ---- Stream ----

    /// @notice Get stream summary info.
    /// @param seqOfDistr Distribution sequence.
    /// @return info Stream summary drop.
    function getStreamInfo(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop memory info);

    /// @notice Get creeks in a stream.
    /// @param seqOfDistr Distribution sequence.
    /// @return list Creek drops list.
    function getCreeksOfStream(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop[] memory list);

    /// @notice Get all drops in a stream.
    /// @param seqOfDistr Distribution sequence.
    /// @return list Drop list.
    function getDropsOfStream(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop[] memory list);

    // ==== Waterfalls Member ====

    /// @notice Get pool info for member/class.
    /// @param member Member user number.
    /// @param class Share class id.
    /// @return drop Pool info.
    function getPoolInfo(
        uint member, uint class
    ) external view returns(WaterfallsRepo.Drop memory drop);

    /// @notice Get lake info for member.
    /// @param member Member user number.
    /// @return drop Lake info.
    function getLakeInfo(
        uint member
    ) external view returns(WaterfallsRepo.Drop memory drop);

    // ==== Waterfalls Class ====

    /// @notice Get initial sea info for class.
    /// @param class Share class id.
    /// @return info Sea info.
    function getInitSeaInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info);

    /// @notice Get sea info for class.
    /// @param class Share class id.
    /// @return info Sea info.
    function getSeaInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info);

    /// @notice Get gulf info for class.
    /// @param class Share class id.
    /// @return info Gulf info.
    function getGulfInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info);

    /// @notice Get island info for class and distribution.
    /// @param class Share class id.
    /// @param seqOfDistr Distribution sequence.
    /// @return info Island info.
    function getIslandInfo(
        uint class, uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop memory info);

    /// @notice Get list of classes in waterfall.
    /// @return list Class ids.
    function getListOfClasses() external view returns(uint[] memory list);

    /// @notice Get sea info list for all classes.
    /// @return list Sea info list.
    function getAllSeasInfo() external view returns(
        WaterfallsRepo.Drop[] memory list
    );

    // ==== Waterfalls Sum ====

    /// @notice Get ocean summary info.
    /// @return info Ocean info.
    function getOceanInfo() external view returns(
        WaterfallsRepo.Drop memory info
    );

}

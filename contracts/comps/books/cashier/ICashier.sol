// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
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

import "../../../center/ERC20/IUSDC.sol";

import "../../../lib/UsdLockersRepo.sol";
import "../../../lib/RulesParser.sol";
import "../../../lib/WaterfallsRepo.sol";
import "../../../lib/BooksRepo.sol";

// import "../roc/IRegisterOfConstitution.sol";
// import "../../common/retrieve/ROC.sol";
// import "../../common/retrieve/ROM.sol";
// import "../../common/retrieve/ROS.sol";

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

    event ReceiveUsd(address indexed from, uint indexed amt, bytes32 indexed remark);

    event ForwardUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark);

    event CustodyUsd(address indexed from, uint indexed amt, bytes32 indexed remark);

    event ReleaseUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark);

    event TransferUsd(address indexed to, uint indexed amt, bytes32 indexed remark);

    event InitClass(uint indexed class, uint indexed principal, uint indexed initDate);

    event RedeemClass(uint indexed class, uint indexed principal);

    event DistrProfits(uint indexed amt, uint indexed seqOfDR, uint indexed seqOfDistr);

    event DistrIncome(uint indexed amt, uint indexed seqOfDR, uint fundManager, uint indexed seqOfDistr);

    event DepositUsd(uint indexed amt, uint indexed user, bytes32 indexed remark);

    event PickupUsd(address indexed msgSender, uint indexed caller, uint indexed value);

    //###############
    //##   Write   ##
    //###############

    function collectUsd(TransferAuth memory auth, bytes32 remark) external;

    function forwardUsd(TransferAuth memory auth, address to, bytes32 remark) external;

    function custodyUsd(TransferAuth memory auth, bytes32 remark) external;

    function releaseUsd(address from, address to, uint amt, bytes32 remark) external;

    function transferUsd(address to, uint amt, bytes32 remark) external;

    function initClass(uint class, uint principal) external;

    function redeemClass(uint class, uint principal) external;

    function distrProfits(uint amt, uint seqOfDR) external returns(
        WaterfallsRepo.Drop[] memory mlist
    );

    function distrIncome(uint amt, uint seqOfDR, uint para) external returns(
        WaterfallsRepo.Drop[] memory mlist, WaterfallsRepo.Drop[] memory slist
    );

    function depositUsd(uint amt, uint user, bytes32 remark) external;

    function pickupUsd() external; 

    //##################
    //##   Read I/O   ##
    //##################

    function custodyOf(address acct) external view returns(uint);

    function totalEscrow() external view returns(uint);

    function totalDeposits() external view returns(uint);

    function depositOfMine(uint user) external view returns(uint);    

    function balanceOfComp() external view returns(uint);

    // ==== Waterfalls Distribution ====

    // ---- Drop ----

    function getDrop(
        uint seqOfDistr, uint member, uint class, uint seqOfShare
    ) external view returns(WaterfallsRepo.Drop memory drop);

    // ---- Flow ----

    function getFlowInfo(
        uint seqOfDistr, uint member, uint class
    ) external view returns(WaterfallsRepo.Drop memory info);

    function getDropsOfFlow(
        uint seqOfDistr, uint member, uint class
    ) external view returns(WaterfallsRepo.Drop[] memory list);

    // ---- Creek ----

    function getCreekInfo(
        uint seqOfDistr, uint member
    ) external view returns(WaterfallsRepo.Drop memory info);

    function getDropsOfCreek(
        uint seqOfDistr, uint member
    ) external view returns(WaterfallsRepo.Drop[] memory list);

    // ---- Stream ----

    function getStreamInfo(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop memory info);

    function getCreeksOfStream(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop[] memory list);

    function getDropsOfStream(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop[] memory list);

    // ==== Waterfalls Member ====

    function getPoolInfo(
        uint member, uint class
    ) external view returns(WaterfallsRepo.Drop memory drop);

    function getLakeInfo(
        uint member
    ) external view returns(WaterfallsRepo.Drop memory drop);

    // ==== Waterfalls Class ====

    function getInitSeaInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info);

    function getSeaInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info);

    function getGulfInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info);

    function getIslandInfo(
        uint class, uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop memory info);

    function getListOfClasses() external view returns(uint[] memory list);

    function getAllSeasInfo() external view returns(
        WaterfallsRepo.Drop[] memory list
    );

    // ==== Waterfalls Sum ====

    function getOceanInfo() external view returns(
        WaterfallsRepo.Drop memory info
    );

}

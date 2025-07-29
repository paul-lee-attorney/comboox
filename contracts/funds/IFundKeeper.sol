// SPDX-License-Identifier: UNLICENSED

/* *
 *
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

import "../comps/common/components/IMeetingMinutes.sol";

import "../lib/UsersRepo.sol";
import "../lib/Address.sol";

import "../comps/keepers/IAccountant.sol";
import "../comps/keepers/IROCKeeper.sol";
import "../comps/keepers/IRODKeeper.sol";
import "../comps/keepers/IBMMKeeper.sol";
import "../comps/keepers/IROMKeeper.sol";
import "../comps/keepers/IGMMKeeper.sol";
import "../comps/keepers/IROAKeeper.sol";
import "../comps/keepers/IROOKeeper.sol";
import "../comps/keepers/IROPKeeper.sol";
import "../comps/keepers/ISHAKeeper.sol";
import "../comps/keepers/ILOOKeeper.sol";
import "../comps/keepers/IROIKeeper.sol";
import "../comps/keepers/IRORKeeper.sol";

import "../comps/books/cashier/ICashier.sol";

import "../comps/books/roa/IRegisterOfAgreements.sol";
import "../comps/books/roc/IRegisterOfConstitution.sol";
import "../comps/books/rod/IRegisterOfDirectors.sol";
import "../comps/books/rom/IRegisterOfMembers.sol";
import "../comps/books/roo/IRegisterOfOptions.sol";
import "../comps/books/rop/IRegisterOfPledges.sol";
import "../comps/books/ros/IRegisterOfShares.sol";

import "../comps/books/loo/IListOfOrders.sol";
import "../comps/books/roi/IRegisterOfInvestors.sol";
import "../comps/books/ror/IRegisterOfRedemptions.sol";

interface IFundKeeper {

    struct CompInfo {
        uint40 regNum;
        uint48 regDate;
        uint8 currency;
        uint8 state;
        bytes19 symbol;
        string name;
    }

    // ###############
    // ##   Event   ##
    // ###############

    event RegKeeper(uint indexed title, address indexed keeper, address indexed dk);
    event RegBook(uint indexed title, address indexed book, address indexed dk);
    event ExecAction(uint256 indexed contents);
    event ReceivedCash(address indexed from, uint indexed amt);
    event DeprecateGK(address indexed receiver, uint indexed balanceOfCBP, uint indexed balanceOfETH);

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setCompInfo (
        uint8 _currency,
        bytes19 _symbol,
        string memory _name
    ) external;

    function createCorpSeal() external;

    function getCompInfo() external view returns(CompInfo memory);

    function getCompUser() external view returns (UsersRepo.User memory);

    function regKeeper(uint256 title, address keeper) external;

    function isKeeper(address caller) external view returns (bool flag);

    function getKeeper(uint256) external view returns(address keeper);

    function getTitleOfKeeper(address keeper) external view returns (uint);

    function regBook(uint256 title, address keeper) external;

    function getBook(uint256 title) external view returns (address);

    // ##################
    // ##  ROCKeeper   ##
    // ##################

    function createSHA(uint version) external;

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external;

    function signSHA(address sha, bytes32 sigHash) external;

    function activateSHA(address body) external;

    function acceptSHA(bytes32 sigHash) external;

    // ###################
    // ##   RODKeeper   ##
    // ###################

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external;

    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external;

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external;

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external;

    function quitPosition(uint256 seqOfPos) external;

    // ###################
    // ##   BMMKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint candidate) external;

    function createMotionToRemoveOfficer(uint256 seqOfPos) external;

    function createMotionToApproveDoc(uint doc, uint seqOfVR, uint executor) external;

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    function entrustDelegaterForBoardMeeting(uint256 seqOfMotion, uint delegate) external;

    function proposeMotionToBoard (uint seqOfMotion) external;

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;

    function voteCounting(uint256 seqOfMotion) external;

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external;

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;

    function payInCapital(ICashier.TransferAuth memory auth,uint seqOfShare, uint paid) external;

    // ###################
    // ##   GMMKeeper   ##
    // ###################

    function nominateDirector(uint256 seqOfPos, uint candidate) external;

    function createMotionToRemoveDirector(uint256 seqOfPos) external;

    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external;

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    function proposeToDeprecateGK(address payable receiver) external;

    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external;

    function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external;

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external;

    function voteCountingOfGM(uint256 seqOfMotion) external;

    function execActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

    function deprecateGK(address payable receiver, uint seqOfMotion) external;

    // ###################
    // ##   ROAKeeper   ##
    // ###################

    function createIA(uint256 snOfIA) external;

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external;

    function signIA(address ia, bytes32 sigHash) external;

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) external;

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) external;

    function issueNewShare(address ia, uint256 seqOfDeal) external;

    function transferTargetShare(address ia, uint256 seqOfDeal) external;

    function terminateDeal(address ia, uint256 seqOfDeal) external;

    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, address to
    ) external;

    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external;

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external;

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external;

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external;

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external;

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external;

    function execPledge(uint seqOfShare, uint256 seqOfPld, uint buyer, uint groupOfBuyer) external;

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external;

    // ############
    // ##  Fund  ##
    // ############

    function initClass(uint class) external;

    function proposeToDistributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint seqOfDR,
        uint para,
        uint executor
    ) external;

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion
    ) external;

    function distributeIncome(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint fundManager,
        uint seqOfMotion
    ) external;

    function proposeToTransferFund(
        bool toBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external;

    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external;

    // #################
    // ##  LOOKeeper  ##
    // #################

    function regInvestor(address bKey, uint groupRep, bytes32 idHash) external;

    function approveInvestor(uint userNo, uint seqOfLR) external;

    function revokeInvestor(uint userNo, uint seqOfLR) external;

    function placeInitialOffer(
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    function withdrawInitialOffer(
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external;

    function placeSellOrder(
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external;    

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, uint paid, uint price, uint execHours
    ) external;

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, uint paid, uint execHours
    ) external;
    
    function withdrawBuyOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external;

    // #################
    // ##  RORKeeper  ##
    // #################

    function addRedeemableClass(uint class) external;

    function removeRedeemableClass(uint class) external;

    function updateNavPrice(uint class, uint price) external;

    function requestForRedemption(uint class, uint paid) external;

    function redeem(uint class, uint seqOfPack) external;

    // ###############
    // ##  Routing  ##
    // ###############

    function getROC() external view returns (IRegisterOfConstitution);

    function getSHA() external view returns (IShareholdersAgreement);

    function getROD() external view returns (IRegisterOfDirectors);

    function getBMM() external view returns (IMeetingMinutes);

    function getROM() external view returns (IRegisterOfMembers);

    function getGMM() external view returns (IMeetingMinutes);

    function getROA() external view returns (IRegisterOfAgreements);

    function getROP() external view returns (IRegisterOfPledges);

    function getROS() external view returns (IRegisterOfShares);

    function getLOO() external view returns (IListOfOrders);

    function getROI() external view returns (IRegisterOfInvestors);

    function getBank() external view returns (IUSDC);

    function getCashier() external view returns (ICashier);

    function getROR() external view returns (IRegisterOfRedemptions);

}

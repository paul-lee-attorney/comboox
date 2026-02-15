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

import "../../openzeppelin/utils/Address.sol";

library KeepersRouter  {
    using Address for address;

    enum Keepers {
        ZeroPoint,
        ROCK,       //1
        RODK,
        BMMK,
        ROMK,
        GMMK,       //5
        ROAK,
        ROOK,
        ROPK,
        SHAK,
        LOOK,       //10
        ROIK,       
        Accountant,
        Blank_1,
        Blank_2,
        GK,    //15
        RORK
    }

    struct Repo {
        /// keeper's title => address
        mapping(uint256 => address) keepers;
        /// keeper's address => title
        mapping(address => uint256) titleOfKeeper;
        // function's sig => title
        mapping(bytes4 => uint256) sigToTitle;
    }

    // ==== Errors ====  

    error KeepersRouter_ZeroTitle();

    error KeepersRouter_ZeroAddr();

    error KeepersRouter_ZeroSig();

    error KeepersRouter_AddrNotContract();

    error KeepersRouter_SigNotRegistered();

    error KeepersRouter_SigAlreadyRegistered();

    // ==== Initialize ==== 

    function initSigs(Repo storage repo) external {
        _initSigToTitle(repo);
    }

    function _initSigToTitle(Repo storage repo) internal {
        _initROCKeeper(repo);
        _initRODKeeper(repo);
        _initBMMKeeper(repo);
        _initROMKeeper(repo);
        _initGMMKeeper(repo);
        _initROAKeeper(repo);
        _initROOKeeper(repo);
        _initROPKeeper(repo);
        _initSHAKeeper(repo);
        _initLOOKeeper(repo);
        _initROIKeeper(repo);
        _initAccountant(repo);
        _initRORKeeper(repo);
    }

    // ==== Write ==== 

    function regKeeper(Repo storage repo, uint title, address addr) external {
        
        if (title == 0) revert KeepersRouter_ZeroTitle();
        if (!addr.isContract()) revert KeepersRouter_AddrNotContract();

        if (addr == address(0)) {
            delete repo.keepers[title];
            return;
        }

        if (repo.titleOfKeeper[addr] > 0) {
            delete repo.keepers[repo.titleOfKeeper[addr]];
        }

        repo.keepers[title] = addr;
        repo.titleOfKeeper[addr] = title;
    }

    function regSigToTitle(Repo storage repo, bytes4 sig, uint title) external {
        if (sig == bytes4(0)) revert KeepersRouter_ZeroSig();
        
        if (title == 0) {
            delete repo.sigToTitle[sig];
            return;
        }

        if (repo.sigToTitle[sig] > 0) 
            revert KeepersRouter_SigAlreadyRegistered();
        
        repo.sigToTitle[sig] = title;
    }

    // ==== Read ====

    function isKeeper(Repo storage repo, address addr) external view returns (bool flag) {   
        return repo.titleOfKeeper[addr] > 0;
    }

    function getKeeper(Repo storage repo, uint256 title) external view returns (address) {
        return repo.keepers[title];
    }

    function getTitleOfKeeper(Repo storage repo, address keeper) external view returns (uint) {
        return repo.titleOfKeeper[keeper];
    }

    function getKeeperBySig(Repo storage repo, bytes4 sig) external view returns (address keeper) {
        uint title = repo.sigToTitle[sig];
        if (repo.keepers[title] == address(0)) 
            revert KeepersRouter_SigNotRegistered();
        
        keeper = repo.keepers[title];
    }

    // ==== Config of Sigs ====

    // ROCKeeper
    bytes4 internal constant sigOfCreateSHA = bytes4(keccak256("createSHA(uint256)"));
    bytes4 internal constant sigOfCirculateSHA = bytes4(keccak256("circulateSHA(address,bytes32,bytes32)"));
    bytes4 internal constant sigOfSignSHA = bytes4(keccak256("signSHA(address,bytes32)"));
    bytes4 internal constant sigOfActivateSHA = bytes4(keccak256("activateSHA(address)"));
    bytes4 internal constant sigOfAcceptSHA = bytes4(keccak256("acceptSHA(bytes32)"));

    // RODKeeper
    bytes4 internal constant sigOfTakeSeat = bytes4(keccak256("takeSeat(uint256,uint256)"));
    bytes4 internal constant sigOfRemoveDirector = bytes4(keccak256("removeDirector(uint256,uint256)"));
    bytes4 internal constant sigOfTakePosition = bytes4(keccak256("takePosition(uint256,uint256)"));
    bytes4 internal constant sigOfRemoveOfficer = bytes4(keccak256("removeOfficer(uint256,uint256)"));
    bytes4 internal constant sigOfQuitPosition = bytes4(keccak256("quitPosition(uint256)"));

    // BMMKeeper
    bytes4 internal constant sigOfNominateOfficer = bytes4(keccak256("nominateOfficer(uint256,uint256)"));
    bytes4 internal constant sigOfCreateMotionToRemoveOfficer = bytes4(keccak256("createMotionToRemoveOfficer(uint256)"));
    bytes4 internal constant sigOfCreateMotionToApproveDoc = bytes4(keccak256("createMotionToApproveDoc(uint256,uint256,uint256)"));
    bytes4 internal constant sigOfProposeToTransferFund = bytes4(keccak256("proposeToTransferFund(address,bool,uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfCreateAction = bytes4(keccak256("createAction(uint256,address[],uint256[],bytes[],bytes32,uint256)"));
    bytes4 internal constant sigOfEntrustDelegaterForBoardMeeting = bytes4(keccak256("entrustDelegaterForBoardMeeting(uint256,uint256)"));
    bytes4 internal constant sigOfProposeMotionToBoard = bytes4(keccak256("proposeMotionToBoard(uint256)"));
    bytes4 internal constant sigOfCastVote = bytes4(keccak256("castVote(uint256,uint256,bytes32)"));
    bytes4 internal constant sigOfVoteCounting = bytes4(keccak256("voteCounting(uint256)"));
    bytes4 internal constant sigOfExecAction = bytes4(keccak256("execAction(uint256,address[],uint256[],bytes[],bytes32,uint256)"));

    // ROMKeeper
    bytes4 internal constant sigOfSetMaxQtyOfMembers = bytes4(keccak256("setMaxQtyOfMembers(uint256)"));
    bytes4 internal constant sigOfSetPayInAmt = bytes4(keccak256("setPayInAmt(uint256,uint256,uint256,bytes32)"));
    bytes4 internal constant sigOfRequestPaidInCapital = bytes4(keccak256("requestPaidInCapital(bytes32,string)"));
    bytes4 internal constant sigOfWithdrawPayInAmt = bytes4(keccak256("withdrawPayInAmt(bytes32,uint256)"));
    bytes4 internal constant sigOfPayInCapital = bytes4(keccak256("payInCapital((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256)"));
    bytes4 internal constant sigOfDecreaseCapital = bytes4(keccak256("decreaseCapital(uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfUpdatePaidInDeadline = bytes4(keccak256("updatePaidInDeadline(uint256,uint256)"));

    // GMMKeeper
    bytes4 internal constant sigOfNominateDirector = bytes4(keccak256("nominateDirector(uint256,uint256)"));
    bytes4 internal constant sigOfCreateMotionToRemoveDirector = bytes4(keccak256("createMotionToRemoveDirector(uint256)"));
    bytes4 internal constant sigOfProposeDocOfGM = bytes4(keccak256("proposeDocOfGM(uint256,uint256,uint256)"));
    bytes4 internal constant sigOfProposeToDistributeUsd = bytes4(keccak256("proposeToDistributeUsd(uint256,uint256,uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfProposeToTransferFundOfGM = bytes4(keccak256("proposeToTransferFund(address,bool,uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfCreateActionOfGM = bytes4(keccak256("createActionOfGM(uint256,address[],uint256[],bytes[],bytes32,uint256)"));
    bytes4 internal constant sigOfEntrustDelegaterForGeneralMeeting = bytes4(keccak256("entrustDelegaterForGeneralMeeting(uint256,uint256)"));
    bytes4 internal constant sigOfProposeMotionToGeneralMeeting = bytes4(keccak256("proposeMotionToGeneralMeeting(uint256)"));
    bytes4 internal constant sigOfCastVoteOfGM = bytes4(keccak256("castVoteOfGM(uint256,uint256,bytes32)"));
    bytes4 internal constant sigOfVoteCountingOfGM = bytes4(keccak256("voteCountingOfGM(uint256)"));
    bytes4 internal constant sigOfExecActionOfGM = bytes4(keccak256("execActionOfGM(uint256,address[],uint256[],bytes[],bytes32,uint256)"));

    // ROAKeeper
    bytes4 internal constant sigOfCreateIA = bytes4(keccak256("createIA(uint256)"));
    bytes4 internal constant sigOfCirculateIA = bytes4(keccak256("circulateIA(address,bytes32,bytes32)"));
    bytes4 internal constant sigOfSignIA = bytes4(keccak256("signIA(address,bytes32)"));
    bytes4 internal constant sigOfPushToCoffer = bytes4(keccak256("pushToCoffer(address,uint256,bytes32,uint256)"));
    bytes4 internal constant sigOfCloseDeal = bytes4(keccak256("closeDeal(address,uint256,string)"));
    bytes4 internal constant sigOfTransferTargetShare = bytes4(keccak256("transferTargetShare(address,uint256)"));
    bytes4 internal constant sigOfIssueNewShare = bytes4(keccak256("issueNewShare(address,uint256)"));
    bytes4 internal constant sigOfTerminateDeal = bytes4(keccak256("terminateDeal(address,uint256)"));
    bytes4 internal constant sigOfPayOffApprovedDeal = bytes4(keccak256("payOffApprovedDeal((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),address,uint256,address)"));

    // ROOKeeper
    bytes4 internal constant sigOfUpdateOracle = bytes4(keccak256("updateOracle(uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfExecOption = bytes4(keccak256("execOption(uint256)"));
    bytes4 internal constant sigOfCreateSwap = bytes4(keccak256("createSwap(uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfPayOffSwap = bytes4(keccak256("payOffSwap((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,address)"));
    bytes4 internal constant sigOfTerminateSwap = bytes4(keccak256("terminateSwap(uint256,uint256)"));

    // ROPKeeper
    bytes4 internal constant sigOfCreatePledge = bytes4(keccak256("createPledge(bytes32,uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfTransferPledge = bytes4(keccak256("transferPledge(uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfRefundDebt = bytes4(keccak256("refundDebt(uint256,uint256,uint256)"));
    bytes4 internal constant sigOfExtendPledge = bytes4(keccak256("extendPledge(uint256,uint256,uint256)"));
    bytes4 internal constant sigOfLockPledge = bytes4(keccak256("lockPledge(uint256,uint256,bytes32)"));
    bytes4 internal constant sigOfReleasePledge = bytes4(keccak256("releasePledge(uint256,uint256,string)"));
    bytes4 internal constant sigOfExecPledge = bytes4(keccak256("execPledge(uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfRevokePledge = bytes4(keccak256("revokePledge(uint256,uint256)"));

    // SHAKeeper
    bytes4 internal constant sigOfExecAlongRight = bytes4(keccak256("execAlongRight(address,bytes32,bytes32)"));
    bytes4 internal constant sigOfAcceptAlongDeal = bytes4(keccak256("acceptAlongDeal(address,uint256,bytes32)"));
    bytes4 internal constant sigOfExecAntiDilution = bytes4(keccak256("execAntiDilution(address,uint256,uint256,bytes32)"));
    bytes4 internal constant sigOfTakeGiftShares = bytes4(keccak256("takeGiftShares(address,uint256)"));
    bytes4 internal constant sigOfExecFirstRefusal = bytes4(keccak256("execFirstRefusal(uint256,uint256,address,uint256,bytes32)"));
    bytes4 internal constant sigOfComputeFirstRefusal = bytes4(keccak256("computeFirstRefusal(address,uint256)"));

    // LOOKeeper
    bytes4 internal constant sigOfPlaceInitialOffer = bytes4(keccak256("placeInitialOffer(uint256,uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfWithdrawInitialOffer = bytes4(keccak256("withdrawInitialOffer(uint256,uint256,uint256)"));
    bytes4 internal constant sigOfPlaceSellOrder = bytes4(keccak256("placeSellOrder(uint256,uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfWithdrawSellOrder = bytes4(keccak256("withdrawSellOrder(uint256,uint256)"));
    bytes4 internal constant sigOfPlaceBuyOrder = bytes4(keccak256("placeBuyOrder((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfPlaceMarketBuyOrder = bytes4(keccak256("placeMarketBuyOrder((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,uint256)"));
    bytes4 internal constant sigOfWithdrawBuyOrder = bytes4(keccak256("withdrawBuyOrder(uint256,uint256)"));

    // ROIKeeper
    bytes4 internal constant sigOfPause = bytes4(keccak256("pause(uint256)"));
    bytes4 internal constant sigOfUnPause = bytes4(keccak256("unPause(uint256)"));
    bytes4 internal constant sigOfFreezeShare = bytes4(keccak256("freezeShare(uint256,uint256,uint256,bytes32)"));
    bytes4 internal constant sigOfUnfreezeShare = bytes4(keccak256("unfreezeShare(uint256,uint256,uint256,bytes32)"));
    bytes4 internal constant sigOfForceTransfer = bytes4(keccak256("forceTransfer(uint256,uint256,uint256,address,bytes32)"));
    bytes4 internal constant sigOfRegInvestor = bytes4(keccak256("regInvestor(address,uint256,bytes32)"));
    bytes4 internal constant sigOfApproveInvestor = bytes4(keccak256("approveInvestor(uint256,uint256)"));
    bytes4 internal constant sigOfRevokeInvestor = bytes4(keccak256("revokeInvestor(uint256,uint256)"));

    // Accountant
    bytes4 internal constant sigOfInitClass = bytes4(keccak256("initClass(uint256)"));
    bytes4 internal constant sigOfDistrProfits = bytes4(keccak256("distrProfits(uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfDistrIncome = bytes4(keccak256("distrIncome(uint256,uint256,uint256,uint256,uint256)"));
    bytes4 internal constant sigOfTransferFund = bytes4(keccak256("transferFund(bool,address,bool,uint256,uint256,uint256)"));

    // RORKeeper
    bytes4 internal constant sigOfAddRedeemableClass = bytes4(keccak256("addRedeemableClass(uint256)"));
    bytes4 internal constant sigOfRemoveRedeemableClass = bytes4(keccak256("removeRedeemableClass(uint256)"));
    bytes4 internal constant sigOfUpdateNavPrice = bytes4(keccak256("updateNavPrice(uint256,uint256)"));
    bytes4 internal constant sigOfRequestForRedemption = bytes4(keccak256("requestForRedemption(uint256,uint256)"));
    bytes4 internal constant sigOfRedeem = bytes4(keccak256("redeem(uint256,uint256)"));

    function _initROCKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfCreateSHA] = uint8(Keepers.ROCK);
        repo.sigToTitle[sigOfCirculateSHA] = uint8(Keepers.ROCK);
        repo.sigToTitle[sigOfSignSHA] = uint8(Keepers.ROCK);
        repo.sigToTitle[sigOfActivateSHA] = uint8(Keepers.ROCK);
        repo.sigToTitle[sigOfAcceptSHA] = uint8(Keepers.ROCK);
    }

    function _initRODKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfTakeSeat] = uint8(Keepers.RODK);
        repo.sigToTitle[sigOfRemoveDirector] = uint8(Keepers.RODK);
        repo.sigToTitle[sigOfTakePosition] = uint8(Keepers.RODK);
        repo.sigToTitle[sigOfRemoveOfficer] = uint8(Keepers.RODK);
        repo.sigToTitle[sigOfQuitPosition] = uint8(Keepers.RODK);
    }

    function _initBMMKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfNominateOfficer] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfCreateMotionToRemoveOfficer] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfCreateMotionToApproveDoc] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfProposeToTransferFund] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfCreateAction] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfEntrustDelegaterForBoardMeeting] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfProposeMotionToBoard] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfCastVote] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfVoteCounting] = uint8(Keepers.BMMK);
        repo.sigToTitle[sigOfExecAction] = uint8(Keepers.BMMK);        
    }

    function _initROMKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfSetMaxQtyOfMembers] = uint8(Keepers.ROMK);
        repo.sigToTitle[sigOfSetPayInAmt] = uint8(Keepers.ROMK);
        repo.sigToTitle[sigOfRequestPaidInCapital] = uint8(Keepers.ROMK);
        repo.sigToTitle[sigOfWithdrawPayInAmt] = uint8(Keepers.ROMK);
        repo.sigToTitle[sigOfPayInCapital] = uint8(Keepers.ROMK);
        repo.sigToTitle[sigOfDecreaseCapital] = uint8(Keepers.ROMK);
        repo.sigToTitle[sigOfUpdatePaidInDeadline] = uint8(Keepers.ROMK);
    }

    function _initGMMKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfNominateDirector] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfCreateMotionToRemoveDirector] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfProposeDocOfGM] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfProposeToDistributeUsd] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfProposeToTransferFundOfGM] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfCreateActionOfGM] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfEntrustDelegaterForGeneralMeeting] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfProposeMotionToGeneralMeeting] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfCastVoteOfGM] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfVoteCountingOfGM] = uint8(Keepers.GMMK);
        repo.sigToTitle[sigOfExecActionOfGM] = uint8(Keepers.GMMK);        
    }

    function _initROAKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfCreateIA] = uint8(Keepers.ROAK);
        repo.sigToTitle[sigOfCirculateIA] = uint8(Keepers.ROAK);
        repo.sigToTitle[sigOfSignIA] = uint8(Keepers.ROAK);
        repo.sigToTitle[sigOfPushToCoffer] = uint8(Keepers.ROAK);
        repo.sigToTitle[sigOfCloseDeal] = uint8(Keepers.ROAK);
        repo.sigToTitle[sigOfTransferTargetShare] = uint8(Keepers.ROAK);
        repo.sigToTitle[sigOfIssueNewShare] = uint8(Keepers.ROAK);
        repo.sigToTitle[sigOfTerminateDeal] = uint8(Keepers.ROAK);
        repo.sigToTitle[sigOfPayOffApprovedDeal] = uint8(Keepers.ROAK);
    }

    function _initROOKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfUpdateOracle] = uint8(Keepers.ROOK);
        repo.sigToTitle[sigOfExecOption] = uint8(Keepers.ROOK);
        repo.sigToTitle[sigOfCreateSwap] = uint8(Keepers.ROOK);
        repo.sigToTitle[sigOfPayOffSwap] = uint8(Keepers.ROOK);
        repo.sigToTitle[sigOfTerminateSwap] = uint8(Keepers.ROOK);
    }

    function _initROPKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfCreatePledge] = uint8(Keepers.ROPK);
        repo.sigToTitle[sigOfTransferPledge] = uint8(Keepers.ROPK);
        repo.sigToTitle[sigOfRefundDebt] = uint8(Keepers.ROPK);
        repo.sigToTitle[sigOfExtendPledge] = uint8(Keepers.ROPK);
        repo.sigToTitle[sigOfLockPledge] = uint8(Keepers.ROPK);
        repo.sigToTitle[sigOfReleasePledge] = uint8(Keepers.ROPK);
        repo.sigToTitle[sigOfExecPledge] = uint8(Keepers.ROPK);
        repo.sigToTitle[sigOfRevokePledge] = uint8(Keepers.ROPK);
    }

    function _initSHAKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfExecAlongRight] = uint8(Keepers.SHAK);
        repo.sigToTitle[sigOfAcceptAlongDeal] = uint8(Keepers.SHAK);
        repo.sigToTitle[sigOfExecAntiDilution] = uint8(Keepers.SHAK);
        repo.sigToTitle[sigOfTakeGiftShares] = uint8(Keepers.SHAK);
        repo.sigToTitle[sigOfExecFirstRefusal] = uint8(Keepers.SHAK);
        repo.sigToTitle[sigOfComputeFirstRefusal] = uint8(Keepers.SHAK);
    }

    function _initLOOKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfPlaceInitialOffer] = uint8(Keepers.LOOK);
        repo.sigToTitle[sigOfWithdrawInitialOffer] = uint8(Keepers.LOOK);
        repo.sigToTitle[sigOfPlaceSellOrder] = uint8(Keepers.LOOK);
        repo.sigToTitle[sigOfWithdrawSellOrder] = uint8(Keepers.LOOK);
        repo.sigToTitle[sigOfPlaceBuyOrder] = uint8(Keepers.LOOK);
        repo.sigToTitle[sigOfPlaceMarketBuyOrder] = uint8(Keepers.LOOK);
        repo.sigToTitle[sigOfWithdrawBuyOrder] = uint8(Keepers.LOOK);
    }

    function _initROIKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfPause] = uint8(Keepers.ROIK);
        repo.sigToTitle[sigOfUnPause] = uint8(Keepers.ROIK);
        repo.sigToTitle[sigOfFreezeShare] = uint8(Keepers.ROIK);
        repo.sigToTitle[sigOfUnfreezeShare] = uint8(Keepers.ROIK);
        repo.sigToTitle[sigOfForceTransfer] = uint8(Keepers.ROIK);
        repo.sigToTitle[sigOfRegInvestor] = uint8(Keepers.ROIK);
        repo.sigToTitle[sigOfApproveInvestor] = uint8(Keepers.ROIK);
        repo.sigToTitle[sigOfRevokeInvestor] = uint8(Keepers.ROIK);
    }

    function _initAccountant(Repo storage repo) private {
        repo.sigToTitle[sigOfInitClass] = uint8(Keepers.Accountant);
        repo.sigToTitle[sigOfDistrProfits] = uint8(Keepers.Accountant);
        repo.sigToTitle[sigOfDistrIncome] = uint8(Keepers.Accountant);
        repo.sigToTitle[sigOfTransferFund] = uint8(Keepers.Accountant);
    }

    function _initRORKeeper(Repo storage repo) private {
        repo.sigToTitle[sigOfAddRedeemableClass] = uint8(Keepers.RORK);
        repo.sigToTitle[sigOfRemoveRedeemableClass] = uint8(Keepers.RORK);
        repo.sigToTitle[sigOfUpdateNavPrice] = uint8(Keepers.RORK);
        repo.sigToTitle[sigOfRequestForRedemption] = uint8(Keepers.RORK);
        repo.sigToTitle[sigOfRedeem] = uint8(Keepers.RORK);
    }

}

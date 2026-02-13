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

import "../openzeppelin/utils/Address.sol";

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
        /// @notice Keeper registry (title => keeper address).
        mapping(uint256 => address) keepers;
        /// @notice Reverse keeper registry (keeper address => title).
        mapping(address => uint256) titleOfKeeper;
        // sig => title of keeper
        mapping(bytes4 => Keepers) sigToKeeper;
    }

    // function regSelector(Repo storage repo, bytes4 sig, Keepers title) public {
    //     if (repo.sigToKeeper[sig] != Keepers.ZeroPoint) {
    //         delete repo.sigToKeeper[sig];
    //     }
    //     repo.sigToKeeper[sig] = title;
    // }

    function regKeeper(Repo storage repo, uint title, address addr) public {
        require(title > 0, 
            "KR.regKeeper: invalid title");

        if (addr != address(0)) {
            require(addr.isContract(), 
                "KR.regKeeper: not a contract");
        }

        if (repo.titleOfKeeper[addr] != 0) {
            if (repo.titleOfKeeper[addr] != title) {
                _updateSelectorsByTitle(
                    repo, 
                    repo.titleOfKeeper[addr], 
                    address(0)
                );
            }
            delete repo.titleOfKeeper[addr];
        }

        if (repo.keepers[title] != address(0)) {
            delete repo.titleOfKeeper[repo.keepers[title]];
        }

        repo.keepers[title] = addr;        
        repo.titleOfKeeper[addr] = title;

        _updateSelectorsByTitle(repo, title, addr);
    }

    function _updateSelectorsByTitle(Repo storage repo, uint title, address addr) private {
        if(title == uint(Keepers.Accountant)){
            addr == address(0)
                ? _removeAccountant(repo) : _regAccountant(repo);
        } else if(title == uint(Keepers.ROCK)){
            addr == address(0) 
                ? _removeROCKeeper(repo) : _regROCKeeper(repo);
        } else if(title == uint(Keepers.RODK)){
            addr == address(0) 
                ? _removeRODKeeper(repo) : _regRODKeeper(repo);
        } else if(title == uint(Keepers.BMMK)){
            addr == address(0) 
                ? _removeBMMKeeper(repo) : _regBMMKeeper(repo);
        } else if(title == uint(Keepers.ROMK)){
            addr == address(0) 
                ? _removeROMKeeper(repo) : _regROMKeeper(repo);
        } else if(title == uint(Keepers.GMMK)){
            addr == address(0) 
                ? _removeGMMKeeper(repo) : _regGMMKeeper(repo);
        } else if(title == uint(Keepers.ROAK)){
            addr == address(0) 
                ? _removeROAKeeper(repo) : _regROAKeeper(repo);
        } else if(title == uint(Keepers.ROOK)){
            addr == address(0) 
                ? _removeROOKeeper(repo) : _regROOKeeper(repo);
        } else if(title == uint(Keepers.ROPK)){
            addr == address(0) 
                ? _removeROPKeeper(repo) : _regROPKeeper(repo);
        } else if(title == uint(Keepers.SHAK)){
            addr == address(0) 
                ? _removeSHAKeeper(repo) : _regSHAKeeper(repo);
        } else if(title == uint(Keepers.LOOK)){
            addr == address(0) 
                ? _removeLOOKeeper(repo) : _regLOOKeeper(repo);
        } else if(title == uint(Keepers.ROIK)){
            addr == address(0) 
                ? _removeROIKeeper(repo) : _regROIKeeper(repo);
        } else if(title == uint(Keepers.RORK)){
            addr == address(0) 
                ? _removeRORKeeper(repo) : _regRORKeeper(repo);
        }
    }

    function isKeeper(Repo storage repo, address caller) public view returns (bool flag) {   
        return repo.titleOfKeeper[caller] > 0;
    }

    function getKeeper(Repo storage repo, uint256 title) public view returns (address) {
        return repo.keepers[title];
    }

    function getTitleOfKeeper(Repo storage repo, address keeper) public view returns (uint) {
        return repo.titleOfKeeper[keeper];
    }

    function getKeeperBySig(Repo storage repo, bytes4 sig) public view returns (address keeper) {
        Keepers title = repo.sigToKeeper[sig];
        keeper = repo.keepers[uint256(title)];
    }

    // Accountant
    bytes4 constant sigOfInitClass = bytes4(keccak256("initClass(uint256)"));
    bytes4 constant sigOfDistrProfits = bytes4(keccak256("distrProfits(uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfDistrIncome = bytes4(keccak256("distrIncome(uint256,uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfTransferFund = bytes4(keccak256("transferFund(bool,address,bool,uint256,uint256,uint256)"));

    // ROCKeeper
    bytes4 constant sigOfCreateSHA = bytes4(keccak256("createSHA(uint256)"));
    bytes4 constant sigOfCirculateSHA = bytes4(keccak256("circulateSHA(address,bytes32,bytes32)"));
    bytes4 constant sigOfSignSHA = bytes4(keccak256("signSHA(address,bytes32)"));
    bytes4 constant sigOfActivateSHA = bytes4(keccak256("activateSHA(address)"));
    bytes4 constant sigOfAcceptSHA = bytes4(keccak256("acceptSHA(bytes32)"));

    // RODKeeper
    bytes4 constant sigOfTakeSeat = bytes4(keccak256("takeSeat(uint256,uint256)"));
    bytes4 constant sigOfRemoveDirector = bytes4(keccak256("removeDirector(uint256,uint256)"));
    bytes4 constant sigOfTakePosition = bytes4(keccak256("takePosition(uint256,uint256)"));
    bytes4 constant sigOfRemoveOfficer = bytes4(keccak256("removeOfficer(uint256,uint256)"));
    bytes4 constant sigOfQuitPosition = bytes4(keccak256("quitPosition(uint256)"));

    // BMMKeeper
    bytes4 constant sigOfNominateOfficer = bytes4(keccak256("nominateOfficer(uint256,uint256)"));
    bytes4 constant sigOfCreateMotionToRemoveOfficer = bytes4(keccak256("createMotionToRemoveOfficer(uint256)"));
    bytes4 constant sigOfCreateMotionToApproveDoc = bytes4(keccak256("createMotionToApproveDoc(uint256,uint256,uint256)"));
    bytes4 constant sigOfProposeToTransferFund = bytes4(keccak256("proposeToTransferFund(address,bool,uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfCreateAction = bytes4(keccak256("createAction(uint256,address[],uint256[],bytes[],bytes32,uint256)"));
    bytes4 constant sigOfEntrustDelegaterForBoardMeeting = bytes4(keccak256("entrustDelegaterForBoardMeeting(uint256,uint256)"));
    bytes4 constant sigOfProposeMotionToBoard = bytes4(keccak256("proposeMotionToBoard(uint256)"));
    bytes4 constant sigOfCastVote = bytes4(keccak256("castVote(uint256,uint256,bytes32)"));
    bytes4 constant sigOfVoteCounting = bytes4(keccak256("voteCounting(uint256)"));
    bytes4 constant sigOfExecAction = bytes4(keccak256("execAction(uint256,address[],uint256[],bytes[],bytes32,uint256)"));

    // ROMKeeper
    bytes4 constant sigOfSetMaxQtyOfMembers = bytes4(keccak256("setMaxQtyOfMembers(uint256)"));
    bytes4 constant sigOfSetPayInAmt = bytes4(keccak256("setPayInAmt(uint256,uint256,uint256,bytes32)"));
    bytes4 constant sigOfRequestPaidInCapital = bytes4(keccak256("requestPaidInCapital(bytes32,string)"));
    bytes4 constant sigOfWithdrawPayInAmt = bytes4(keccak256("withdrawPayInAmt(bytes32,uint256)"));
    bytes4 constant sigOfPayInCapital = bytes4(keccak256("payInCapital((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256)"));
    bytes4 constant sigOfDecreaseCapital = bytes4(keccak256("decreaseCapital(uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfUpdatePaidInDeadline = bytes4(keccak256("updatePaidInDeadline(uint256,uint256)"));

    // GMMKeeper
    bytes4 constant sigOfNominateDirector = bytes4(keccak256("nominateDirector(uint256,uint256)"));
    bytes4 constant sigOfCreateMotionToRemoveDirector = bytes4(keccak256("createMotionToRemoveDirector(uint256)"));
    bytes4 constant sigOfProposeDocOfGM = bytes4(keccak256("proposeDocOfGM(uint256,uint256,uint256)"));
    bytes4 constant sigOfProposeToDistributeUsd = bytes4(keccak256("proposeToDistributeUsd(uint256,uint256,uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfProposeToTransferFundOfGM = bytes4(keccak256("proposeToTransferFund(address,bool,uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfCreateActionOfGM = bytes4(keccak256("createActionOfGM(uint256,address[],uint256[],bytes[],bytes32,uint256)"));
    bytes4 constant sigOfEntrustDelegaterForGeneralMeeting = bytes4(keccak256("entrustDelegaterForGeneralMeeting(uint256,uint256)"));
    bytes4 constant sigOfProposeMotionToGeneralMeeting = bytes4(keccak256("proposeMotionToGeneralMeeting(uint256)"));
    bytes4 constant sigOfCastVoteOfGM = bytes4(keccak256("castVoteOfGM(uint256,uint256,bytes32)"));
    bytes4 constant sigOfVoteCountingOfGM = bytes4(keccak256("voteCountingOfGM(uint256)"));
    bytes4 constant sigOfExecActionOfGM = bytes4(keccak256("execActionOfGM(uint256,address[],uint256[],bytes[],bytes32,uint256)"));

    // ROAKeeper
    bytes4 constant sigOfCreateIA = bytes4(keccak256("createIA(uint256)"));
    bytes4 constant sigOfCirculateIA = bytes4(keccak256("circulateIA(address,bytes32,bytes32)"));
    bytes4 constant sigOfSignIA = bytes4(keccak256("signIA(address,bytes32)"));
    bytes4 constant sigOfPushToCoffer = bytes4(keccak256("pushToCoffer(address,uint256,bytes32,uint256)"));
    bytes4 constant sigOfCloseDeal = bytes4(keccak256("closeDeal(address,uint256,string)"));
    bytes4 constant sigOfTransferTargetShare = bytes4(keccak256("transferTargetShare(address,uint256)"));
    bytes4 constant sigOfIssueNewShare = bytes4(keccak256("issueNewShare(address,uint256)"));
    bytes4 constant sigOfTerminateDeal = bytes4(keccak256("terminateDeal(address,uint256)"));
    bytes4 constant sigOfPayOffApprovedDeal = bytes4(keccak256("payOffApprovedDeal((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),address,uint256,address)"));

    // ROOKeeper
    bytes4 constant sigOfUpdateOracle = bytes4(keccak256("updateOracle(uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfExecOption = bytes4(keccak256("execOption(uint256)"));
    bytes4 constant sigOfCreateSwap = bytes4(keccak256("createSwap(uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfPayOffSwap = bytes4(keccak256("payOffSwap((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,address)"));
    bytes4 constant sigOfTerminateSwap = bytes4(keccak256("terminateSwap(uint256,uint256)"));

    // ROPKeeper
    bytes4 constant sigOfCreatePledge = bytes4(keccak256("createPledge(bytes32,uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfTransferPledge = bytes4(keccak256("transferPledge(uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfRefundDebt = bytes4(keccak256("refundDebt(uint256,uint256,uint256)"));
    bytes4 constant sigOfExtendPledge = bytes4(keccak256("extendPledge(uint256,uint256,uint256)"));
    bytes4 constant sigOfLockPledge = bytes4(keccak256("lockPledge(uint256,uint256,bytes32)"));
    bytes4 constant sigOfReleasePledge = bytes4(keccak256("releasePledge(uint256,uint256,string)"));
    bytes4 constant sigOfExecPledge = bytes4(keccak256("execPledge(uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfRevokePledge = bytes4(keccak256("revokePledge(uint256,uint256)"));

    // SHAKeeper
    bytes4 constant sigOfExecAlongRight = bytes4(keccak256("execAlongRight(address,bytes32,bytes32)"));
    bytes4 constant sigOfAcceptAlongDeal = bytes4(keccak256("acceptAlongDeal(address,uint256,bytes32)"));
    bytes4 constant sigOfExecAntiDilution = bytes4(keccak256("execAntiDilution(address,uint256,uint256,bytes32)"));
    bytes4 constant sigOfTakeGiftShares = bytes4(keccak256("takeGiftShares(address,uint256)"));
    bytes4 constant sigOfExecFirstRefusal = bytes4(keccak256("execFirstRefusal(uint256,uint256,address,uint256,bytes32)"));
    bytes4 constant sigOfComputeFirstRefusal = bytes4(keccak256("computeFirstRefusal(address,uint256)"));

    // LOOKeeper
    bytes4 constant sigOfPlaceInitialOffer = bytes4(keccak256("placeInitialOffer(uint256,uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfWithdrawInitialOffer = bytes4(keccak256("withdrawInitialOffer(uint256,uint256,uint256)"));
    bytes4 constant sigOfPlaceSellOrder = bytes4(keccak256("placeSellOrder(uint256,uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfWithdrawSellOrder = bytes4(keccak256("withdrawSellOrder(uint256,uint256)"));
    bytes4 constant sigOfPlaceBuyOrder = bytes4(keccak256("placeBuyOrder((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,uint256,uint256)"));
    bytes4 constant sigOfPlaceMarketBuyOrder = bytes4(keccak256("placeMarketBuyOrder((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,uint256)"));
    bytes4 constant sigOfWithdrawBuyOrder = bytes4(keccak256("withdrawBuyOrder(uint256,uint256)"));

    // ROIKeeper
    bytes4 constant sigOfPause = bytes4(keccak256("pause(uint256)"));
    bytes4 constant sigOfUnPause = bytes4(keccak256("unPause(uint256)"));
    bytes4 constant sigOfFreezeShare = bytes4(keccak256("freezeShare(uint256,uint256,uint256,bytes32)"));
    bytes4 constant sigOfUnfreezeShare = bytes4(keccak256("unfreezeShare(uint256,uint256,uint256,bytes32)"));
    bytes4 constant sigOfForceTransfer = bytes4(keccak256("forceTransfer(uint256,uint256,uint256,address,bytes32)"));
    bytes4 constant sigOfRegInvestor = bytes4(keccak256("regInvestor(address,uint256,bytes32)"));
    bytes4 constant sigOfApproveInvestor = bytes4(keccak256("approveInvestor(uint256,uint256)"));
    bytes4 constant sigOfRevokeInvestor = bytes4(keccak256("revokeInvestor(uint256,uint256)"));

    // RORKeeper
    bytes4 constant sigOfAddRedeemableClass = bytes4(keccak256("addRedeemableClass(uint256)"));
    bytes4 constant sigOfRemoveRedeemableClass = bytes4(keccak256("removeRedeemableClass(uint256)"));
    bytes4 constant sigOfUpdateNavPrice = bytes4(keccak256("updateNavPrice(uint256,uint256)"));
    bytes4 constant sigOfRequestForRedemption = bytes4(keccak256("requestForRedemption(uint256,uint256)"));
    bytes4 constant sigOfRedeem = bytes4(keccak256("redeem(uint256,uint256)"));

    function _regAccountant(Repo storage repo) private {   
        repo.sigToKeeper[sigOfInitClass] = Keepers.Accountant;
        repo.sigToKeeper[sigOfDistrProfits] = Keepers.Accountant;
        repo.sigToKeeper[sigOfDistrIncome] = Keepers.Accountant;
        repo.sigToKeeper[sigOfTransferFund] = Keepers.Accountant;
    }

    function _removeAccountant(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfInitClass];
        delete repo.sigToKeeper[sigOfDistrProfits];
        delete repo.sigToKeeper[sigOfDistrIncome];
        delete repo.sigToKeeper[sigOfTransferFund];
    }

    function _regROCKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfCreateSHA] = Keepers.ROCK;
        repo.sigToKeeper[sigOfCirculateSHA] = Keepers.ROCK;
        repo.sigToKeeper[sigOfSignSHA] = Keepers.ROCK;
        repo.sigToKeeper[sigOfActivateSHA] = Keepers.ROCK;
        repo.sigToKeeper[sigOfAcceptSHA] = Keepers.ROCK;
    }

    function _removeROCKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfCreateSHA];
        delete repo.sigToKeeper[sigOfCirculateSHA];
        delete repo.sigToKeeper[sigOfSignSHA];
        delete repo.sigToKeeper[sigOfActivateSHA];
        delete repo.sigToKeeper[sigOfAcceptSHA];
    }

    function _regRODKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfTakeSeat] = Keepers.RODK;
        repo.sigToKeeper[sigOfRemoveDirector] = Keepers.RODK;
        repo.sigToKeeper[sigOfTakePosition] = Keepers.RODK;
        repo.sigToKeeper[sigOfRemoveOfficer] = Keepers.RODK;
        repo.sigToKeeper[sigOfQuitPosition] = Keepers.RODK;
    }

    function _removeRODKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfTakeSeat];
        delete repo.sigToKeeper[sigOfRemoveDirector];
        delete repo.sigToKeeper[sigOfTakePosition];
        delete repo.sigToKeeper[sigOfRemoveOfficer];
        delete repo.sigToKeeper[sigOfQuitPosition];
    }

    function _regBMMKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfNominateOfficer] = Keepers.BMMK;
        repo.sigToKeeper[sigOfCreateMotionToRemoveOfficer] = Keepers.BMMK;
        repo.sigToKeeper[sigOfCreateMotionToApproveDoc] = Keepers.BMMK;
        repo.sigToKeeper[sigOfProposeToTransferFund] = Keepers.BMMK;
        repo.sigToKeeper[sigOfCreateAction] = Keepers.BMMK;
        repo.sigToKeeper[sigOfEntrustDelegaterForBoardMeeting] = Keepers.BMMK;
        repo.sigToKeeper[sigOfProposeMotionToBoard] = Keepers.BMMK;
        repo.sigToKeeper[sigOfCastVote] = Keepers.BMMK;
        repo.sigToKeeper[sigOfVoteCounting] = Keepers.BMMK;
        repo.sigToKeeper[sigOfExecAction] = Keepers.BMMK;        
    }

    function _removeBMMKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfNominateOfficer];
        delete repo.sigToKeeper[sigOfCreateMotionToRemoveOfficer];
        delete repo.sigToKeeper[sigOfCreateMotionToApproveDoc];
        delete repo.sigToKeeper[sigOfProposeToTransferFund];
        delete repo.sigToKeeper[sigOfCreateAction];
        delete repo.sigToKeeper[sigOfEntrustDelegaterForBoardMeeting];
        delete repo.sigToKeeper[sigOfProposeMotionToBoard];
        delete repo.sigToKeeper[sigOfCastVote];
        delete repo.sigToKeeper[sigOfVoteCounting];
        delete repo.sigToKeeper[sigOfExecAction];
    }

    function _regROMKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfSetMaxQtyOfMembers] = Keepers.ROMK;
        repo.sigToKeeper[sigOfSetPayInAmt] = Keepers.ROMK;
        repo.sigToKeeper[sigOfRequestPaidInCapital] = Keepers.ROMK;
        repo.sigToKeeper[sigOfWithdrawPayInAmt] = Keepers.ROMK;
        repo.sigToKeeper[sigOfPayInCapital] = Keepers.ROMK;
        repo.sigToKeeper[sigOfDecreaseCapital] = Keepers.ROMK;
        repo.sigToKeeper[sigOfUpdatePaidInDeadline] = Keepers.ROMK;
    }

    function _removeROMKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfSetMaxQtyOfMembers];
        delete repo.sigToKeeper[sigOfSetPayInAmt];
        delete repo.sigToKeeper[sigOfRequestPaidInCapital];
        delete repo.sigToKeeper[sigOfWithdrawPayInAmt];
        delete repo.sigToKeeper[sigOfPayInCapital];
        delete repo.sigToKeeper[sigOfDecreaseCapital];
        delete repo.sigToKeeper[sigOfUpdatePaidInDeadline];
    }

    function _regGMMKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfNominateDirector] = Keepers.GMMK;
        repo.sigToKeeper[sigOfCreateMotionToRemoveDirector] = Keepers.GMMK;
        repo.sigToKeeper[sigOfProposeDocOfGM] = Keepers.GMMK;
        repo.sigToKeeper[sigOfProposeToDistributeUsd] = Keepers.GMMK;
        repo.sigToKeeper[sigOfProposeToTransferFundOfGM] = Keepers.GMMK;
        repo.sigToKeeper[sigOfCreateActionOfGM] = Keepers.GMMK;
        repo.sigToKeeper[sigOfEntrustDelegaterForGeneralMeeting] = Keepers.GMMK;
        repo.sigToKeeper[sigOfProposeMotionToGeneralMeeting] = Keepers.GMMK;
        repo.sigToKeeper[sigOfCastVoteOfGM] = Keepers.GMMK;
        repo.sigToKeeper[sigOfVoteCountingOfGM] = Keepers.GMMK;
        repo.sigToKeeper[sigOfExecActionOfGM] = Keepers.GMMK;        
    }

    function _removeGMMKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfNominateDirector];
        delete repo.sigToKeeper[sigOfCreateMotionToRemoveDirector];
        delete repo.sigToKeeper[sigOfProposeDocOfGM];
        delete repo.sigToKeeper[sigOfProposeToDistributeUsd];
        delete repo.sigToKeeper[sigOfProposeToTransferFundOfGM];
        delete repo.sigToKeeper[sigOfCreateActionOfGM];
        delete repo.sigToKeeper[sigOfEntrustDelegaterForGeneralMeeting];
        delete repo.sigToKeeper[sigOfProposeMotionToGeneralMeeting];
        delete repo.sigToKeeper[sigOfCastVoteOfGM];
        delete repo.sigToKeeper[sigOfVoteCountingOfGM];
        delete repo.sigToKeeper[sigOfExecActionOfGM];        
    }

    function _regROAKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfCreateIA] = Keepers.ROAK;
        repo.sigToKeeper[sigOfCirculateIA] = Keepers.ROAK;
        repo.sigToKeeper[sigOfSignIA] = Keepers.ROAK;
        repo.sigToKeeper[sigOfPushToCoffer] = Keepers.ROAK;
        repo.sigToKeeper[sigOfCloseDeal] = Keepers.ROAK;
        repo.sigToKeeper[sigOfTransferTargetShare] = Keepers.ROAK;
        repo.sigToKeeper[sigOfIssueNewShare] = Keepers.ROAK;
        repo.sigToKeeper[sigOfTerminateDeal] = Keepers.ROAK;
        repo.sigToKeeper[sigOfPayOffApprovedDeal] = Keepers.ROAK;
    }

    function _removeROAKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfCreateIA];
        delete repo.sigToKeeper[sigOfCirculateIA];
        delete repo.sigToKeeper[sigOfSignIA];
        delete repo.sigToKeeper[sigOfPushToCoffer];
        delete repo.sigToKeeper[sigOfCloseDeal];
        delete repo.sigToKeeper[sigOfTransferTargetShare];
        delete repo.sigToKeeper[sigOfIssueNewShare];
        delete repo.sigToKeeper[sigOfTerminateDeal];
        delete repo.sigToKeeper[sigOfPayOffApprovedDeal];
    }

    function _regROOKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfUpdateOracle] = Keepers.ROOK;
        repo.sigToKeeper[sigOfExecOption] = Keepers.ROOK;
        repo.sigToKeeper[sigOfCreateSwap] = Keepers.ROOK;
        repo.sigToKeeper[sigOfPayOffSwap] = Keepers.ROOK;
        repo.sigToKeeper[sigOfTerminateSwap] = Keepers.ROOK;
    }

    function _removeROOKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfUpdateOracle];
        delete repo.sigToKeeper[sigOfExecOption];
        delete repo.sigToKeeper[sigOfCreateSwap];
        delete repo.sigToKeeper[sigOfPayOffSwap];
        delete repo.sigToKeeper[sigOfTerminateSwap];
    }

    function _regROPKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfCreatePledge] = Keepers.ROPK;
        repo.sigToKeeper[sigOfTransferPledge] = Keepers.ROPK;
        repo.sigToKeeper[sigOfRefundDebt] = Keepers.ROPK;
        repo.sigToKeeper[sigOfExtendPledge] = Keepers.ROPK;
        repo.sigToKeeper[sigOfLockPledge] = Keepers.ROPK;
        repo.sigToKeeper[sigOfReleasePledge] = Keepers.ROPK;
        repo.sigToKeeper[sigOfExecPledge] = Keepers.ROPK;
        repo.sigToKeeper[sigOfRevokePledge] = Keepers.ROPK;
    }

    function _removeROPKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfCreatePledge];
        delete repo.sigToKeeper[sigOfTransferPledge];
        delete repo.sigToKeeper[sigOfRefundDebt];
        delete repo.sigToKeeper[sigOfExtendPledge];
        delete repo.sigToKeeper[sigOfLockPledge];
        delete repo.sigToKeeper[sigOfReleasePledge];
        delete repo.sigToKeeper[sigOfExecPledge];
        delete repo.sigToKeeper[sigOfRevokePledge];
    }

    function _regSHAKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfExecAlongRight] = Keepers.SHAK;
        repo.sigToKeeper[sigOfAcceptAlongDeal] = Keepers.SHAK;
        repo.sigToKeeper[sigOfExecAntiDilution] = Keepers.SHAK;
        repo.sigToKeeper[sigOfTakeGiftShares] = Keepers.SHAK;
        repo.sigToKeeper[sigOfExecFirstRefusal] = Keepers.SHAK;
        repo.sigToKeeper[sigOfComputeFirstRefusal] = Keepers.SHAK;
    }

    function _removeSHAKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfExecAlongRight];
        delete repo.sigToKeeper[sigOfAcceptAlongDeal];
        delete repo.sigToKeeper[sigOfExecAntiDilution];
        delete repo.sigToKeeper[sigOfTakeGiftShares];
        delete repo.sigToKeeper[sigOfExecFirstRefusal];
        delete repo.sigToKeeper[sigOfComputeFirstRefusal];
    }

    function _regLOOKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfPlaceInitialOffer] = Keepers.LOOK;
        repo.sigToKeeper[sigOfWithdrawInitialOffer] = Keepers.LOOK;
        repo.sigToKeeper[sigOfPlaceSellOrder] = Keepers.LOOK;
        repo.sigToKeeper[sigOfWithdrawSellOrder] = Keepers.LOOK;
        repo.sigToKeeper[sigOfPlaceBuyOrder] = Keepers.LOOK;
        repo.sigToKeeper[sigOfPlaceMarketBuyOrder] = Keepers.LOOK;
        repo.sigToKeeper[sigOfWithdrawBuyOrder] = Keepers.LOOK;
    }

    function _removeLOOKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfPlaceInitialOffer];
        delete repo.sigToKeeper[sigOfWithdrawInitialOffer];
        delete repo.sigToKeeper[sigOfPlaceSellOrder];
        delete repo.sigToKeeper[sigOfWithdrawSellOrder];
        delete repo.sigToKeeper[sigOfPlaceBuyOrder];
        delete repo.sigToKeeper[sigOfPlaceMarketBuyOrder];
        delete repo.sigToKeeper[sigOfWithdrawBuyOrder];
    }

    function _regROIKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfPause] = Keepers.ROIK;
        repo.sigToKeeper[sigOfUnPause] = Keepers.ROIK;
        repo.sigToKeeper[sigOfFreezeShare] = Keepers.ROIK;
        repo.sigToKeeper[sigOfUnfreezeShare] = Keepers.ROIK;
        repo.sigToKeeper[sigOfForceTransfer] = Keepers.ROIK;
        repo.sigToKeeper[sigOfRegInvestor] = Keepers.ROIK;
        repo.sigToKeeper[sigOfApproveInvestor] = Keepers.ROIK;
        repo.sigToKeeper[sigOfRevokeInvestor] = Keepers.ROIK;
    }

    function _removeROIKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfPause];
        delete repo.sigToKeeper[sigOfUnPause];
        delete repo.sigToKeeper[sigOfFreezeShare];
        delete repo.sigToKeeper[sigOfUnfreezeShare];
        delete repo.sigToKeeper[sigOfForceTransfer];
        delete repo.sigToKeeper[sigOfRegInvestor];
        delete repo.sigToKeeper[sigOfApproveInvestor];
        delete repo.sigToKeeper[sigOfRevokeInvestor];
    }

    function _regRORKeeper(Repo storage repo) private {
        repo.sigToKeeper[sigOfAddRedeemableClass] = Keepers.RORK;
        repo.sigToKeeper[sigOfRemoveRedeemableClass] = Keepers.RORK;
        repo.sigToKeeper[sigOfUpdateNavPrice] = Keepers.RORK;
        repo.sigToKeeper[sigOfRequestForRedemption] = Keepers.RORK;
        repo.sigToKeeper[sigOfRedeem] = Keepers.RORK;
    }

    function _removeRORKeeper(Repo storage repo) private {
        delete repo.sigToKeeper[sigOfAddRedeemableClass];
        delete repo.sigToKeeper[sigOfRemoveRedeemableClass];
        delete repo.sigToKeeper[sigOfUpdateNavPrice];
        delete repo.sigToKeeper[sigOfRequestForRedemption];
        delete repo.sigToKeeper[sigOfRedeem];
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./common/lib/RolesRepo.sol";

import "./keepers/IBOAKeeper.sol";
import "./keepers/IBODKeeper.sol";
import "./keepers/IBOHKeeper.sol";
import "./keepers/IBOGKeeper.sol";
import "./keepers/IBOOKeeper.sol";
import "./keepers/IBOPKeeper.sol";
import "./keepers/IBOSKeeper.sol";
import "./keepers/IROMKeeper.sol";
import "./keepers/ISHAKeeper.sol";
import "./keepers/IROSKeeper.sol";

import "./books/boa/IBookOfIA.sol";
import "./books/bod/IBookOfDirectors.sol";
import "./books/bog/IBookOfGM.sol";
import "./books/boh/IBookOfSHA.sol";
import "./books/boo/IBookOfOptions.sol";
import "./books/bop/IBookOfPledges.sol";
import "./books/bos/IBookOfShares.sol";
import "./books/rom/IRegisterOfMembers.sol";
import "./books/ros/IRegisterOfSwaps.sol";

interface IGeneralKeeper {

    // ###############
    // ##   Event   ##
    // ###############

    // event RegBook(uint256 indexed title, address indexed book);

    // event RegKeeper(uint256 indexed title, address indexed keeper);

    // event SetCompInfo(string indexed nameOfCompany, string indexed symbolOfCompany);

    // event CreateCorpSeal(uint256 indexed corpNo);

    event ExecAction(uint256 indexed contents, bool indexed result);

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setCompInfo (
        // bytes32 _regNumHash,
        string memory _name,
        string memory _symbol
    ) external;

    function createCorpSeal() external;

    function regKeeper(uint256 title, address keeper) external;

    function isKeeper(address caller) external view returns (bool flag);

    function getKeeper(uint256) external view returns(address keeper);

    function regBook(uint256 title, address keeper) external;

    function getBook(uint256 title) external view returns (address);

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function createIA(uint256 snOfIA) external;

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external;

    function signIA(address ia, bytes32 sigHash) external;

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDate) 
    external;

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external;

    function issueNewShare(address ia, uint256 seqOfDeal) external;

    function transferTargetShare(address ia, uint256 seqOfDeal) external;

    function revokeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external;

    function terminateDeal(address ia, uint256 seqOfDeal) external;

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint candidate) external;

    function proposeToRemoveOfficer(uint256 seqOfPos) external;

    function proposeDoc(address doc, uint seqOfVR, uint executor) external;

    function proposeAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    function entrustDelegate(uint256 seqOfMotion, uint delegate) external;

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;

    function voteCounting(uint256 seqOfMotion) external;

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external;

    function quitPosition(uint256 seqOfPos) external;

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos, uint officer) external;

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

    // ###################
    // ##   BOGKeeper   ##
    // ###################

    function nominateDirector(uint256 seqOfPos, uint candidate) external;

    function proposeToRemoveDirector(uint256 seqOfPos) external;

    function proposeDocOfGM(address doc, uint seqOfVR, uint executor) external;

    function proposeActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    function entrustDelegateOfMember(uint256 seqOfMotion, uint delegate) external;

    function proposeMotionOfGM(uint256 seqOfMotion) external;

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external;

    function voteCountingOfGM(uint256 seqOfMotion) external;

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external;

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint director
    ) external;

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function createSHA(uint version) external;

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external;

    function signSHA(address sha, bytes32 sigHash) external;

    function activateSHA(address body) external;

    function acceptSHA(bytes32 sigHash) external;


    // #################
    // ##  BOOKeeper  ##
    // #################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    function execOption(uint256 seqOfOpt) external;

    function placeSwapOrder(
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget
    ) external;

    function lockSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        bytes32 hashLock
    ) external;

    function releaseSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        string memory hashKey
    ) external;

    function execSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf
    ) external;

    function revokeSwapOrder(uint256 seqOfOpt, uint256 seqOfBrf) external;

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint creditor, uint guaranteeDays, uint paid,
    uint par, uint guaranteedAmt) external;

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external;

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external;

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external;

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external;

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external;

    function execPledge(uint256 seqOfShare, uint256 seqOfPld) external;

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external;

    // ###################
    // ##   BOSKeeper   ##
    // ###################

    function setPayInAmt(bytes32 snOfLocker, uint amount) external;

    function requestPaidInCapital(bytes32 snOfLocker, string memory hashKey, uint salt) external;

    function withdrawPayInAmt(bytes32 snOfLocker) external;

    function decreaseCapital(uint256 seqOfShare, uint parValue, uint paidPar) 
    external;

    function updatePaidInDeadline(uint256 seqOfShare, uint line) external;

    // ##################
    // ##  ROMKeeper   ##
    // ##################

    function setVoteBase(bool onPar) external;

    function setMaxQtyOfMembers(uint max) external;

    function setAmtBase(bool onPar) external;

    // ###################
    // ##   SHAKeeper   ##
    // ###################

    // ======= TagAlong ========

    function execTagAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external;

    // ======= DragAlong ========

    function execDragAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external;

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external;

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external;

    function takeGiftShares(address ia, uint256 seqOfDeal) external;

    // ======== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external;

    function acceptFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external;

    // ##################
    // ##  ROSKeeper   ##
    // ##################

    function createSwap(
        bytes32 snOfSwap,
        uint rightholder, 
        uint paidOfConsider
    ) external;

    function transferSwap(
        uint256 seqOfSwap, 
        uint to, 
        uint amt
    ) external;

    function crystalizeSwap(
        uint256 seqOfSwap, 
        uint seqOfConsider, 
        uint seqOfTarget
    ) external;

    function lockSwap(
        uint256 seqOfSwap, 
        bytes32 hashLock
    ) external;

    function releaseSwap(uint256 seqOfSwap, string memory hashKey) external;

    function execSwap(uint256 seqOfSwap) external;

    function revokeSwap(uint256 seqOfSwap) external;

    function requestToBuy(
        uint256 seqOfMotion,
        uint256 seqOfDeal,
        uint seqOfTarget
    ) external;

    // ###############
    // ##  Routing  ##
    // ###############

    function getBOA() external view returns (IBookOfIA);

    function getBOD() external view returns (IBookOfDirectors);

    function getBOG() external view returns (IBookOfGM);

    function getBOH() external view returns (IBookOfSHA);

    function getSHA() external view returns (IShareholdersAgreement);

    function getBOO() external view returns (IBookOfOptions);

    function getBOP() external view returns (IBookOfPledges);

    function getBOS() external view returns (IBookOfShares);

    function getROM() external view returns (IRegisterOfMembers);

    function getROS() external view returns (IRegisterOfSwaps);

}

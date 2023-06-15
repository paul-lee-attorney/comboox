// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./common/access/AccessControl.sol";

import "./IGeneralKeeper.sol";

contract GeneralKeeper is IGeneralKeeper, AccessControl {

    uint public regNumOfCompany;
    string public nameOfCompany;
    string public symbolOfCompany;

    mapping(uint256 => address) private _books;
    mapping(uint256 => address) private _keepers;

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setCompInfo (
        // bytes32 _regNumHash,
        string memory _name,
        string memory _symbol
    ) external onlyOwner {
        // regNumHash = _regNumHash;
        nameOfCompany = _name;
        symbolOfCompany = _symbol;
        // emit SetCompInfo(_name, _symbol);
    }

    function createCorpSeal() external onlyKeeper {
        _rc.regUser();
        regNumOfCompany = _rc.getMyUserNo();
        _rc.setDocSnOfUser();
    }

    // ---- Keepers ----

    function regKeeper(uint256 title, address keeper) 
    external onlyDirectKeeper {
        _keepers[title] = keeper;
        // emit RegKeeper(title, keeper);
    }

    function isKeeper(address caller) external view returns (bool) {   
        uint256 len = 10;

        while (len > 0) {
            if (caller == _keepers[len]) return true;
            len--;
        }
        return false;
    }

    function getKeeper(uint256 title) external view returns (address) {
        return _keepers[title];
    }

    // ---- Books ----

    function regBook(uint256 title, address book) external onlyDirectKeeper {
        _books[title] = book;
        // emit RegBook(title, book);
    } 

    function getBook(uint256 title) external view returns (address) {
        return _books[title];
    }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function createIA(uint256 snOfIA) external {
        IBOAKeeper(_keepers[1]).createIA(snOfIA, msg.sender, _msgSender());
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IBOAKeeper(_keepers[1]).circulateIA(body, docUrl, docHash, _msgSender());
    }

    function signIA(address ia, bytes32 sigHash) external {
        IBOAKeeper(_keepers[1]).signIA(ia, _msgSender(), sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDate) 
    external {
        IBOAKeeper(_keepers[1]).pushToCoffer(ia, seqOfDeal, hashLock, closingDate, _msgSender());
    }

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external {
        IBOAKeeper(_keepers[1]).closeDeal(ia, seqOfDeal, hashKey, _msgSender());
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external onlyDirectKeeper {
        IBOAKeeper(_keepers[1]).issueNewShare(ia, seqOfDeal);
    }

    function transferTargetShare(address ia, uint256 seqOfDeal) external {
        IBOAKeeper(_keepers[1]).transferTargetShare(ia, seqOfDeal, _msgSender());
    }

    function revokeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external {
        IBOAKeeper(_keepers[1]).revokeDeal(ia, seqOfDeal, _msgSender(), hashKey);
    }

    function terminateDeal(address ia, uint256 seqOfDeal) external {
        IBOAKeeper(_keepers[1]).terminateDeal(ia, seqOfDeal, _msgSender());
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint candidate) external {
        IBODKeeper(_keepers[2]).nominateOfficer(seqOfPos, candidate, _msgSender());
    }

    function createMotionToRemoveOfficer(uint256 seqOfPos) external {
        IBODKeeper(_keepers[2]).createMotionToRemoveOfficer(seqOfPos, _msgSender());
    }

    function proposeDoc(address doc, uint seqOfVR, uint executor) external {
        IBODKeeper(_keepers[2]).proposeDoc(doc, seqOfVR, executor, _msgSender());
    }

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external {
        IBODKeeper(_keepers[2]).createAction(seqOfVR, targets, values, params, desHash, executor, _msgSender());
    }

    function entrustDelegate(uint256 seqOfMotion, uint delegate) external {
        IBODKeeper(_keepers[2]).entrustDelegate(seqOfMotion, delegate, _msgSender());
    }

    function proposeMotionToBoard (uint seqOfMotion) external {
        IBODKeeper(_keepers[2]).proposeMotionToBoard(seqOfMotion, _msgSender());
    }

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external {
        IBODKeeper(_keepers[2]).castVote(seqOfMotion, attitude, sigHash, _msgSender());
    }

    function voteCounting(uint256 seqOfMotion) external {
        IBODKeeper(_keepers[2]).voteCounting(seqOfMotion, _msgSender());
    }

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external {
        IBODKeeper(_keepers[2]).takePosition(seqOfMotion, seqOfPos, _msgSender());
    }

    function quitPosition(uint256 seqOfPos) external {
        IBODKeeper(_keepers[2]).quitPosition(seqOfPos, _msgSender());
    }

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos, uint officer) external {
        IBODKeeper(_keepers[2]).removeOfficer(seqOfMotion, seqOfPos, officer, _msgSender());
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        uint contents = IBODKeeper(_keepers[2]).execAction(typeOfAction, targets, values, params, desHash, seqOfMotion, _msgSender());
        if (_execute(targets, values, params)) {
            emit ExecAction(contents, true);
        } else emit ExecAction(contents, false);        
    }

    function _execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params
    ) private returns (bool success) {
        for (uint256 i = 0; i < targets.length; i++) {
            (success, ) = targets[i].call{value: values[i]}(params[i]);
            if (!success) return success;
        }
    }

    // ###################
    // ##   BOGKeeper   ##
    // ###################


    function nominateDirector(uint256 seqOfPos, uint candidate) external {
        IBOGKeeper(_keepers[3]).nominateDirector(seqOfPos, candidate, _msgSender());
    }

    function createMotionToRemoveDirector(uint256 seqOfPos) external {
        IBOGKeeper(_keepers[3]).createMotionToRemoveDirector(seqOfPos, _msgSender());
    }

    function proposeDocOfGM(address doc, uint seqOfVR, uint executor) external {
        IBOGKeeper(_keepers[3]).proposeDocOfGM(doc, seqOfVR, executor, _msgSender());
    }

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external {
        IBOGKeeper(_keepers[3]).createActionOfGM(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            _msgSender()
        );
    }

    function entrustDelegateOfMember(uint256 seqOfMotion, uint delegate) external {
        IBOGKeeper(_keepers[3]).entrustDelegateOfMember(seqOfMotion, delegate, _msgSender());
    }

    function proposeMotionToGM(uint256 seqOfMotion) external {
        IBOGKeeper(_keepers[3]).proposeMotionToGM(seqOfMotion, _msgSender());
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external {
        IBOGKeeper(_keepers[3]).castVoteOfGM(seqOfMotion, attitude, sigHash, _msgSender());
    }

    function voteCountingOfGM(uint256 seqOfMotion) external {
        IBOGKeeper(_keepers[3]).voteCountingOfGM(seqOfMotion, _msgSender());
    }

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external {
        IBOGKeeper(_keepers[3]).takeSeat(seqOfMotion, seqOfPos, _msgSender());
    }

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint director
    ) external {
        IBOGKeeper(_keepers[3]).removeDirector(seqOfMotion, seqOfPos, director, _msgSender());        
    }

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        uint contents = IBOGKeeper(_keepers[3]).execActionOfGM(
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            _msgSender()
        );
        if (_execute(targets, values, params)) {
            emit ExecAction(contents, true);
        } else emit ExecAction(contents, false);        
    }

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function createSHA(uint version) external {
        IBOHKeeper(_keepers[4]).createSHA(version, msg.sender, _msgSender());
    }

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external {
        IBOHKeeper(_keepers[4]).circulateSHA(body, docUrl, docHash, _msgSender());
    }

    function signSHA(address sha, bytes32 sigHash) external  {
        IBOHKeeper(_keepers[4]).signSHA(sha, sigHash, _msgSender());
    }

    function activateSHA(address body) external {
        IBOHKeeper(_keepers[4]).activateSHA(body, _msgSender());
    }

    function acceptSHA(bytes32 sigHash) external {
        IBOHKeeper(_keepers[4]).acceptSHA(sigHash, _msgSender());
    }


    // #################
    // ##  BOOKeeper  ##
    // #################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDirectKeeper {
        IBOOKeeper(_keepers[5]).updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external {
        IBOOKeeper(_keepers[5]).execOption(seqOfOpt, _msgSender());
    }

    function placeSwapOrder(
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget
    ) external {
        IBOOKeeper(_keepers[5]).placeSwapOrder(seqOfOpt, seqOfConsider, paidOfConsider, seqOfTarget, _msgSender());
    }

    function lockSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        bytes32 hashLock
    ) external {
        IBOOKeeper(_keepers[5]).lockSwapOrder(seqOfOpt, seqOfBrf, hashLock, _msgSender());
    }

    function releaseSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        string memory hashKey
    ) external {
        IBOOKeeper(_keepers[5]).releaseSwapOrder(seqOfOpt, seqOfBrf, hashKey, _msgSender());
    }

    function execSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf
    ) external {
        IBOOKeeper(_keepers[5]).execSwapOrder(seqOfOpt, seqOfBrf, _msgSender());
    }

    function revokeSwapOrder(uint256 seqOfOpt, uint256 seqOfBrf) external {
        IBOOKeeper(_keepers[5]).revokeSwapOrder(seqOfOpt, seqOfBrf, _msgSender());
    }

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint creditor, uint guaranteeDays, uint paid,
    uint par, uint guaranteedAmt) external {
        IBOPKeeper(_keepers[6]).createPledge(snOfPld, creditor, guaranteeDays, paid, par,
        guaranteedAmt, _msgSender());
    }

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external {
        IBOPKeeper(_keepers[6]).transferPledge(seqOfShare, seqOfPld, buyer, amt, _msgSender());
    }

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external {
        IBOPKeeper(_keepers[6]).refundDebt(seqOfShare, seqOfPld, amt, _msgSender());
    }

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external {
        IBOPKeeper(_keepers[6]).extendPledge(seqOfShare, seqOfPld, extDays, _msgSender());
    }

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external {
        IBOPKeeper(_keepers[6]).lockPledge(seqOfShare, seqOfPld, hashLock, _msgSender());
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external {
        IBOPKeeper(_keepers[6]).releasePledge(seqOfShare, seqOfPld, hashKey, _msgSender());
    }

    function execPledge(uint256 seqOfShare, uint256 seqOfPld) external {
        IBOPKeeper(_keepers[6]).execPledge(seqOfShare, seqOfPld, _msgSender());
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external {
        IBOPKeeper(_keepers[6]).revokePledge(seqOfShare, seqOfPld, _msgSender());
    }

    // ###################
    // ##   BOSKeeper   ##
    // ###################

    function setPayInAmt(bytes32 snOfLocker, uint amount) external onlyDirectKeeper {
        IBOSKeeper(_keepers[7]).setPayInAmt(snOfLocker, amount);
    }

    function requestPaidInCapital(bytes32 snOfLocker, string memory hashKey) external {
        IBOSKeeper(_keepers[7]).requestPaidInCapital(snOfLocker, hashKey, _msgSender());
    }

    function withdrawPayInAmt(bytes32 snOfLocker) external onlyDirectKeeper {
        IBOSKeeper(_keepers[7]).withdrawPayInAmt(snOfLocker);
    }

    function decreaseCapital(uint256 seqOfShare, uint parValue, uint paidPar) 
    external onlyDirectKeeper {
        IBOSKeeper(_keepers[7]).decreaseCapital(seqOfShare, parValue, paidPar);
    }

    // function updatePaidInDeadline(uint256 seqOfShare, uint line) external onlyDirectKeeper {
    //     IBOSKeeper(_keepers[7]).updatePaidInDeadline(seqOfShare, line);
    // }

    // ##################
    // ##  ROMKeeper   ##
    // ##################

    function setVoteBase(bool onPar) external onlyDirectKeeper {
        IROMKeeper(_keepers[8]).setVoteBase(onPar);
    }

    function setMaxQtyOfMembers(uint max) external onlyDirectKeeper {
        IROMKeeper(_keepers[8]).setMaxQtyOfMembers(max);
    }

    function setAmtBase(bool onPar) external onlyDirectKeeper {
        IROMKeeper(_keepers[8]).setAmtBase(onPar);
    }

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
    ) external {
        ISHAKeeper(_keepers[9]).execAlongRight(
                ia,
                seqOfDeal,
                false,
                seqOfShare,
                paid,
                par,
                _msgSender(),
                sigHash
            );
    }

    // ======= DragAlong ========

    function execDragAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[9]).execAlongRight(
                ia,
                seqOfDeal,
                true,
                seqOfShare,
                paid,
                par,
                _msgSender(),
                sigHash
            );
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[9]).acceptAlongDeal(ia, seqOfDeal, seqOfShare, _msgSender(), sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[9]).execAntiDilution(ia, seqOfDeal, seqOfShare, _msgSender(), sigHash);
    }

    function takeGiftShares(address ia, uint256 seqOfDeal) external {
        ISHAKeeper(_keepers[9]).takeGiftShares(ia, seqOfDeal, _msgSender());
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[9]).execFirstRefusal(seqOfRule, seqOfRightholder, ia, seqOfDeal, _msgSender(), sigHash);
    }

    function acceptFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[9]).acceptFirstRefusal(
                ia,
                seqOfDeal,
                _msgSender(),
                sigHash
            );
    }

    // ##################
    // ##  ROSKeeper   ##
    // ##################

    function createSwap(
        bytes32 snOfSwap,
        uint rightholder, 
        uint paidOfConsider
    ) external  {
        IROSKeeper(_keepers[10]).createSwap(snOfSwap, rightholder, paidOfConsider, _msgSender());
    }

    function transferSwap(
        uint256 seqOfSwap, 
        uint to, 
        uint amt
    ) external {
        IROSKeeper(_keepers[10]).transferSwap(seqOfSwap, to, amt, _msgSender());
    }

    function crystalizeSwap(
        uint256 seqOfSwap, 
        uint seqOfConsider, 
        uint seqOfTarget
    ) external {
        IROSKeeper(_keepers[10]).crystalizeSwap(seqOfSwap, seqOfConsider, seqOfTarget, _msgSender());
    }

    function lockSwap(
        uint256 seqOfSwap, 
        bytes32 hashLock
    ) external {
        IROSKeeper(_keepers[10]).lockSwap(seqOfSwap, hashLock, _msgSender());
    }

    function releaseSwap(uint256 seqOfSwap, string memory hashKey) external {
        IROSKeeper(_keepers[10]).releaseSwap(seqOfSwap, hashKey, _msgSender());
    } 

    function execSwap(uint256 seqOfSwap) external {
        IROSKeeper(_keepers[10]).execSwap(seqOfSwap, _msgSender());
    }

    function revokeSwap(uint256 seqOfSwap) external
    {
        IROSKeeper(_keepers[10]).revokeSwap(seqOfSwap, _msgSender());
    }

    function requestToBuy(
        uint256 seqOfMotion,
        uint256 seqOfDeal,
        uint seqOfTarget
    ) external {
        IROSKeeper(_keepers[10]).requestToBuy(seqOfMotion, seqOfDeal, seqOfTarget, _msgSender());
    }

    // ###############
    // ##  Routing  ##
    // ###############

    function getBOA() external view returns (IBookOfIA) {
        return IBookOfIA(_books[1]);
    }

    function getBOD() external view returns (IBookOfDirectors ) {
        return IBookOfDirectors(_books[2]);
    }

    function getBOG() external view returns (IBookOfGM ) {
        return IBookOfGM(_books[3]);
    }

    function getBOH() external view returns (IBookOfSHA ) {
        return IBookOfSHA(_books[4]);
    }

    function getSHA() external view returns (IShareholdersAgreement ) {
        return IShareholdersAgreement(IBookOfSHA(_books[4]).pointer());
    }

    function getBOO() external view returns (IBookOfOptions ) {
        return IBookOfOptions(_books[5]);
    }

    function getBOP() external view returns (IBookOfPledges ) {
        return IBookOfPledges(_books[6]);
    }

    function getBOS() external view returns (IBookOfShares ) {
        return IBookOfShares(_books[7]);
    }

    function getROM() external view returns (IRegisterOfMembers ) {
        return IRegisterOfMembers(_books[8]);
    }

    function getROS() external view returns (IRegisterOfSwaps ) {
        return IRegisterOfSwaps(_books[9]);
    }

    
}

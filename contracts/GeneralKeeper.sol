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

    // uint[8] public fees = [10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000];

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

    function createCorpSeal() external onlyDK {
        IRegCenter _rc = _getRC();
        _rc.regUser();
        regNumOfCompany = _rc.getMyUserNo();
        _rc.setDocSnOfUser();
    }

    // ---- Keepers ----

    function regKeeper(uint256 title, address keeper) 
    external onlyDK {
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

    function regBook(uint256 title, address book) external onlyDK {
        _books[title] = book;
        // emit RegBook(title, book);
    } 

    function getBook(uint256 title) external view returns (address) {
        return _books[title];
    }

    // ##################
    // ##  BOCKeeper   ##
    // ##################

    function createSHA(uint version) external {
        IBOCKeeper(_keepers[1]).createSHA(version, msg.sender, _msgSender(60000));
    }

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external {
        IBOCKeeper(_keepers[1]).circulateSHA(body, docUrl, docHash, _msgSender(30000));
    }

    function signSHA(address sha, bytes32 sigHash) external  {
        IBOCKeeper(_keepers[1]).signSHA(sha, sigHash, _msgSender(20000));
    }

    function activateSHA(address body) external {
        IBOCKeeper(_keepers[1]).activateSHA(body, _msgSender(50000));
    }

    function acceptSHA(bytes32 sigHash) external {
        IBOCKeeper(_keepers[1]).acceptSHA(sigHash, _msgSender(20000));
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external {
        IBODKeeper(_keepers[2]).takeSeat(seqOfMotion, seqOfPos, _msgSender(70000));
    }

    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external {
        IBODKeeper(_keepers[2]).removeDirector(seqOfMotion, seqOfPos, _msgSender(70000));        
    }

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external {
        IBODKeeper(_keepers[2]).takePosition(seqOfMotion, seqOfPos, _msgSender(70000));
    }

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external {
        IBODKeeper(_keepers[2]).removeOfficer(seqOfMotion, seqOfPos, _msgSender(70000));
    }

    function quitPosition(uint256 seqOfPos) external {
        IBODKeeper(_keepers[2]).quitPosition(seqOfPos, _msgSender(20000));
    }

    // ###################
    // ##   BMMKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint candidate) external {
        IBMMKeeper(_keepers[3]).nominateOfficer(seqOfPos, candidate, _msgSender(50000));
    }

    function createMotionToRemoveOfficer(uint256 seqOfPos) external {
        IBMMKeeper(_keepers[3]).createMotionToRemoveOfficer(seqOfPos, _msgSender(60000));
    }

    function createMotionToApproveDoc(uint doc, uint seqOfVR, uint executor) external {
        IBMMKeeper(_keepers[3]).createMotionToApproveDoc(doc, seqOfVR, executor, _msgSender(70000));
    }

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external {
        IBMMKeeper(_keepers[3]).createAction(seqOfVR, targets, values, params, desHash, executor, _msgSender(60000));
    }

    function entrustDelegaterForBoardMeeting(uint256 seqOfMotion, uint delegate) external {
        IBMMKeeper(_keepers[3]).entrustDelegaterForBoardMeeting(seqOfMotion, delegate, _msgSender(30000));
    }

    function proposeMotionToBoard (uint seqOfMotion) external {
        IBMMKeeper(_keepers[3]).proposeMotionToBoard(seqOfMotion, _msgSender(40000));
    }

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external {
        IBMMKeeper(_keepers[3]).castVote(seqOfMotion, attitude, sigHash, _msgSender(20000));
    }

    function voteCounting(uint256 seqOfMotion) external {
        IBMMKeeper(_keepers[3]).voteCounting(seqOfMotion);
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        uint contents = IBMMKeeper(_keepers[3]).execAction(typeOfAction, targets, values, params, desHash, seqOfMotion, _msgSender(20000));
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
    // ##   BOMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        IBOMKeeper(_keepers[4]).setMaxQtyOfMembers(max);
    }

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external onlyDK {
        IBOMKeeper(_keepers[4]).setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external {
        IBOMKeeper(_keepers[4]).requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        IBOMKeeper(_keepers[4]).withdrawPayInAmt(hashLock, seqOfShare);
    }

    function decreaseCapital(uint256 seqOfShare, uint paid, uint par) 
    external onlyDK {
        IBOMKeeper(_keepers[4]).decreaseCapital(seqOfShare, paid, par);
    }

    // function updatePaidInDeadline(uint256 seqOfShare, uint line) external onlyDK {
    //     IBOMKeeper(_keepers[9]).updatePaidInDeadline(seqOfShare, line);
    // }

    // ###################
    // ##   GMMKeeper   ##
    // ###################

    function nominateDirector(uint256 seqOfPos, uint candidate) external {
        IGMMKeeper(_keepers[5]).nominateDirector(seqOfPos, candidate, _msgSender(60000));
    }

    function createMotionToRemoveDirector(uint256 seqOfPos) external {
        IGMMKeeper(_keepers[5]).createMotionToRemoveDirector(seqOfPos, _msgSender(70000));
    }

    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external {
        IGMMKeeper(_keepers[5]).proposeDocOfGM(doc, seqOfVR, executor, _msgSender(60000));
    }

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external {
        IGMMKeeper(_keepers[5]).createActionOfGM(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            _msgSender(40000)
        );
    }

    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external {
        IGMMKeeper(_keepers[5]).entrustDelegaterForGeneralMeeting(seqOfMotion, delegate, _msgSender(30000));
    }

    function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external {
        IGMMKeeper(_keepers[5]).proposeMotionToGeneralMeeting(seqOfMotion, _msgSender(50000));
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external {
        IGMMKeeper(_keepers[5]).castVoteOfGM(seqOfMotion, attitude, sigHash, _msgSender(20000));
    }

    function voteCountingOfGM(uint256 seqOfMotion) external {
        IGMMKeeper(_keepers[5]).voteCountingOfGM(seqOfMotion);
    }

    function execActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        uint contents = IGMMKeeper(_keepers[5]).execActionOfGM(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            _msgSender(30000)
        );
        if (_execute(targets, values, params)) {
            emit ExecAction(contents, true);
        } else emit ExecAction(contents, false);        
    }

    // ###################
    // ##   BOIKeeper   ##
    // ###################

    function createIA(uint256 snOfIA) external {
        IBOIKeeper(_keepers[6]).createIA(snOfIA, msg.sender, _msgSender(60000));
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IBOIKeeper(_keepers[6]).circulateIA(body, docUrl, docHash, _msgSender(30000));
    }

    function signIA(address ia, bytes32 sigHash) external {
        IBOIKeeper(_keepers[6]).signIA(ia, _msgSender(20000), sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) 
    external {
        IBOIKeeper(_keepers[6]).pushToCoffer(ia, seqOfDeal, hashLock, closingDeadline, _msgSender(50000));
    }

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external {
        IBOIKeeper(_keepers[6]).closeDeal(ia, seqOfDeal, hashKey);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external onlyDK {
        IBOIKeeper(_keepers[6]).issueNewShare(ia, seqOfDeal);
    }

    function transferTargetShare(address ia, uint256 seqOfDeal) external {
        IBOIKeeper(_keepers[6]).transferTargetShare(ia, seqOfDeal, _msgSender(50000));
    }


    function terminateDeal(address ia, uint256 seqOfDeal) external {
        IBOIKeeper(_keepers[6]).terminateDeal(ia, seqOfDeal, _msgSender(10000));
    }

    // #################
    // ##  BOOKeeper  ##
    // #################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK {
        IBOOKeeper(_keepers[7]).updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external {
        IBOOKeeper(_keepers[7]).execOption(seqOfOpt, _msgSender(70000));
    }

    function placeSwapOrder(
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget
    ) external {
        IBOOKeeper(_keepers[7]).placeSwapOrder(seqOfOpt, seqOfConsider, paidOfConsider, seqOfTarget, _msgSender(70000));
    }

    function lockSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        bytes32 hashLock
    ) external {
        IBOOKeeper(_keepers[7]).lockSwapOrder(seqOfOpt, seqOfBrf, hashLock, _msgSender(60000));
    }

    function releaseSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        string memory hashKey
    ) external {
        IBOOKeeper(_keepers[7]).releaseSwapOrder(seqOfOpt, seqOfBrf, hashKey);
    }

    function execSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf
    ) external {
        IBOOKeeper(_keepers[7]).execSwapOrder(seqOfOpt, seqOfBrf, _msgSender(60000));
    }

    function revokeSwapOrder(uint256 seqOfOpt, uint256 seqOfBrf) external {
        IBOOKeeper(_keepers[7]).revokeSwapOrder(seqOfOpt, seqOfBrf, _msgSender(30000));
    }

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external {
        IBOPKeeper(_keepers[8]).createPledge(snOfPld, paid, par, guaranteedAmt, execDays, _msgSender(50000));
    }

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external {
        IBOPKeeper(_keepers[8]).transferPledge(seqOfShare, seqOfPld, buyer, amt, _msgSender(50000));
    }

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external {
        IBOPKeeper(_keepers[8]).refundDebt(seqOfShare, seqOfPld, amt, _msgSender(30000));
    }

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external {
        IBOPKeeper(_keepers[8]).extendPledge(seqOfShare, seqOfPld, extDays, _msgSender(30000));
    }

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external {
        IBOPKeeper(_keepers[8]).lockPledge(seqOfShare, seqOfPld, hashLock, _msgSender(50000));
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external {
        IBOPKeeper(_keepers[8]).releasePledge(seqOfShare, seqOfPld, hashKey);
    }

    function execPledge(bytes32 snOfDeal, uint256 seqOfPld, uint version, uint buyer, uint groupOfBuyer) external {
        IBOPKeeper(_keepers[8]).execPledge(snOfDeal, seqOfPld, version, msg.sender, buyer, groupOfBuyer, _msgSender(60000));
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external {
        IBOPKeeper(_keepers[8]).revokePledge(seqOfShare, seqOfPld, _msgSender(10000));
    }

    // ##################
    // ##  ROSKeeper   ##
    // ##################

    // function createSwap(
    //     bytes32 snOfSwap,
    //     uint rightholder, 
    //     uint paidOfConsider
    // ) external  {
    //     IROSKeeper(_keepers[9]).createSwap(snOfSwap, rightholder, paidOfConsider, _msgSender(70000));
    // }

    // function transferSwap(
    //     uint256 seqOfSwap, 
    //     uint to, 
    //     uint amt
    // ) external {
    //     IROSKeeper(_keepers[9]).transferSwap(seqOfSwap, to, amt, _msgSender(60000));
    // }

    // function crystalizeSwap(
    //     uint256 seqOfSwap, 
    //     uint seqOfConsider, 
    //     uint seqOfTarget
    // ) external {
    //     IROSKeeper(_keepers[9]).crystalizeSwap(seqOfSwap, seqOfConsider, seqOfTarget, _msgSender(50000));
    // }

    // function lockSwap(
    //     uint256 seqOfSwap, 
    //     bytes32 hashLock
    // ) external {
    //     IROSKeeper(_keepers[9]).lockSwap(seqOfSwap, hashLock, _msgSender(50000));
    // }

    // function releaseSwap(uint256 seqOfSwap, string memory hashKey) external {
    //     IROSKeeper(_keepers[9]).releaseSwap(seqOfSwap, hashKey);
    // } 

    // function execSwap(uint256 seqOfSwap) external {
    //     IROSKeeper(_keepers[9]).execSwap(seqOfSwap, _msgSender(70000));
    // }

    // function revokeSwap(uint256 seqOfSwap) external
    // {
    //     IROSKeeper(_keepers[9]).revokeSwap(seqOfSwap, _msgSender(10000));
    // }

    function requestToBuy(
        uint256 seqOfMotion,
        uint256 seqOfDeal,
        uint seqOfTarget
    ) external {
        IROSKeeper(_keepers[9]).requestToBuy(seqOfMotion, seqOfDeal, seqOfTarget, _msgSender(70000));
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
        ISHAKeeper(_keepers[10]).execAlongRight(
                ia,
                seqOfDeal,
                false,
                seqOfShare,
                paid,
                par,
                _msgSender(70000),
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
        ISHAKeeper(_keepers[10]).execAlongRight(
                ia,
                seqOfDeal,
                true,
                seqOfShare,
                paid,
                par,
                _msgSender(70000),
                sigHash
            );
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[10]).acceptAlongDeal(ia, seqOfDeal, seqOfShare, _msgSender(60000), sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[10]).execAntiDilution(ia, seqOfDeal, seqOfShare, _msgSender(50000), sigHash);
    }

    function takeGiftShares(address ia, uint256 seqOfDeal) external {
        ISHAKeeper(_keepers[10]).takeGiftShares(ia, seqOfDeal, _msgSender(70000));
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[10]).execFirstRefusal(seqOfRule, seqOfRightholder, ia, seqOfDeal, _msgSender(60000), sigHash);
    }

    function acceptFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[10]).acceptFirstRefusal(
                ia,
                seqOfDeal,
                _msgSender(60000),
                sigHash
            );
    }


    // ###############
    // ##  Routing  ##
    // ###############

    function getBOC() external view returns (IBookOfConstitution ) {
        return IBookOfConstitution(_books[1]);
    }

    function getSHA() external view returns (IShareholdersAgreement ) {
        return IShareholdersAgreement(IBookOfConstitution(_books[1]).pointer());
    }

    function getBOD() external view returns (IBookOfDirectors ) {
        return IBookOfDirectors(_books[2]);
    }

    function getBMM() external view returns (IMeetingMinutes ) {
        return IMeetingMinutes(_books[3]);
    }

    function getBOM() external view returns (IBookOfMembers ) {
        return IBookOfMembers(_books[4]);
    }

    function getGMM() external view returns (IMeetingMinutes ) {
        return IMeetingMinutes(_books[5]);
    }

    function getBOI() external view returns (IBookOfIA) {
        return IBookOfIA(_books[6]);
    }

    function getBOO() external view returns (IBookOfOptions ) {
        return IBookOfOptions(_books[7]);
    }

    function getBOP() external view returns (IBookOfPledges ) {
        return IBookOfPledges(_books[8]);
    }

    function getROS() external view returns (IRegisterOfSwaps ) {
        return IRegisterOfSwaps(_books[9]);
    }

    function getBOS() external view returns (IBookOfShares ) {
        return IBookOfShares(_books[10]);
    }    
}

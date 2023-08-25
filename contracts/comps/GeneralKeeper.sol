// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./common/access/AccessControl.sol";
import "./IGeneralKeeper.sol";

contract GeneralKeeper is IGeneralKeeper, AccessControl {

    CompInfo private _info;

    mapping(uint256 => address) private _books;
    mapping(uint256 => address) private _keepers;
    mapping(uint256 => uint256) private _coffers;

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setCompInfo (
        uint8 _currency,
        bytes20 _symbol,
        string memory _name
    ) external onlyDK {
        _info.currency = _currency;
        _info.symbol = _symbol;
        _info.name = _name;
    }

    function createCorpSeal() external onlyDK {
        IRegCenter _rc = _getRC();
        _rc.regUser();
        _info.regNum = _rc.getMyUserNo();
        _info.regDate = uint48(block.timestamp);
    }

    function getCompInfo() external view returns(CompInfo memory) {
        return _info;
    }

    function getCompUser() external view onlyOwner returns (UsersRepo.User memory) {
        return _getRC().getUser();
    }

    function getCentPrice() external view returns(uint) {
        return _getRC().getCentPriceInWei(_info.currency);
    }

    function pickupDeposit() external {
        uint caller = _msgSender(20000);
        uint balance = _coffers[caller];
        if (balance > 0) {
            _coffers[caller] = 0;
            payable(msg.sender).transfer(balance);
        }
    }

    // ---- Keepers ----

    function regKeeper(uint256 title, address keeper) 
    external onlyDK {
        _keepers[title] = keeper;
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
    } 

    function getBook(uint256 title) external view returns (address) {
        return _books[title];
    }

    // ##################
    // ##  Verify ID   ##
    // ##################

    function _msgSender(uint fee) private returns (uint40 usr) {
        usr = _getRC().getUserNo(msg.sender, fee, 1);
    }

    // ##################
    // ##  ROCKeeper   ##
    // ##################

    function createSHA(uint version) external {
        IROCKeeper(_keepers[1]).createSHA(version, msg.sender, _msgSender(60000));
    }

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external {
        IROCKeeper(_keepers[1]).circulateSHA(body, docUrl, docHash, _msgSender(30000));
    }

    function signSHA(address sha, bytes32 sigHash) external  {
        IROCKeeper(_keepers[1]).signSHA(sha, sigHash, _msgSender(20000));
    }

    function activateSHA(address body) external {
        IROCKeeper(_keepers[1]).activateSHA(body, _msgSender(50000));
    }

    function acceptSHA(bytes32 sigHash) external {
        IROCKeeper(_keepers[1]).acceptSHA(sigHash, _msgSender(20000));
    }

    // ###################
    // ##   RODKeeper   ##
    // ###################

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).takeSeat(seqOfMotion, seqOfPos, _msgSender(70000));
    }

    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).removeDirector(seqOfMotion, seqOfPos, _msgSender(70000));        
    }

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).takePosition(seqOfMotion, seqOfPos, _msgSender(70000));
    }

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).removeOfficer(seqOfMotion, seqOfPos, _msgSender(70000));
    }

    function quitPosition(uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).quitPosition(seqOfPos, _msgSender(20000));
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
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        IROMKeeper(_keepers[4]).setMaxQtyOfMembers(max);
    }

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external onlyDK {
        IROMKeeper(_keepers[4]).setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external {
        IROMKeeper(_keepers[4]).requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        IROMKeeper(_keepers[4]).withdrawPayInAmt(hashLock, seqOfShare);
    }

    function decreaseCapital(uint256 seqOfShare, uint paid, uint par) 
    external onlyDK {
        IROMKeeper(_keepers[4]).decreaseCapital(seqOfShare, paid, par);
    }

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
    // ##   ROAKeeper   ##
    // ###################

    function createIA(uint256 snOfIA) external {
        IROAKeeper(_keepers[6]).createIA(snOfIA, msg.sender, _msgSender(60000));
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IROAKeeper(_keepers[6]).circulateIA(body, docUrl, docHash, _msgSender(30000));
    }

    function signIA(address ia, bytes32 sigHash) external {
        IROAKeeper(_keepers[6]).signIA(ia, _msgSender(20000), sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) 
    external {
        IROAKeeper(_keepers[6]).pushToCoffer(ia, seqOfDeal, hashLock, closingDeadline, _msgSender(50000));
    }

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external {
        IROAKeeper(_keepers[6]).closeDeal(ia, seqOfDeal, hashKey);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external {
        IROAKeeper(_keepers[6]).issueNewShare(ia, seqOfDeal, _msgSender(50000));
    }

    function transferTargetShare(address ia, uint256 seqOfDeal) external {
        IROAKeeper(_keepers[6]).transferTargetShare(ia, seqOfDeal, _msgSender(50000));
    }


    function terminateDeal(address ia, uint256 seqOfDeal) external {
        IROAKeeper(_keepers[6]).terminateDeal(ia, seqOfDeal, _msgSender(10000));
    }

    function payOffApprovedDeal(
        address ia,
        uint seqOfDeal
    ) external payable {
        uint receiver = IROAKeeper(_keepers[6]).payOffApprovedDeal(ia, seqOfDeal, msg.value, _msgSender(50000));
        if (receiver > 0) _coffers[receiver] += msg.value;
    }

    // #################
    // ##  ROOKeeper  ##
    // #################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK {
        IROOKeeper(_keepers[7]).updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external {
        IROOKeeper(_keepers[7]).execOption(seqOfOpt, _msgSender(70000));
    }

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge
    ) external {
        IROOKeeper(_keepers[7]).createSwap(seqOfOpt, seqOfTarget, paidOfTarget, seqOfPledge, _msgSender(70000));
    }

    function payOffSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external payable {
        uint receiver = IROOKeeper(_keepers[7]).payOffSwap(seqOfOpt, seqOfSwap, msg.value, _msgSender(70000));
        _coffers[receiver] += msg.value;
    }

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external {
        IROOKeeper(_keepers[7]).terminateSwap(seqOfOpt, seqOfSwap, _msgSender(70000));
    }

    function requestToBuy(address ia, uint seqOfDeal, uint paidOfTarget, uint seqOfPledge) external {
        IROOKeeper(_keepers[7]).requestToBuy(ia, seqOfDeal, paidOfTarget, seqOfPledge, _msgSender(50000));
    }

    function payOffRejectedDeal(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap
    ) external payable {
        uint receiver = IROOKeeper(_keepers[7]).payOffRejectedDeal(ia, seqOfDeal, seqOfSwap, msg.value, _msgSender(50000));
        _coffers[receiver] += msg.value;
    }

    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap
    ) external {
        IROOKeeper(_keepers[7]).pickupPledgedShare(ia, seqOfDeal, seqOfSwap, _msgSender(50000));        
    }


    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external {
        IROPKeeper(_keepers[8]).createPledge(snOfPld, paid, par, guaranteedAmt, execDays, _msgSender(50000));
    }

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external {
        IROPKeeper(_keepers[8]).transferPledge(seqOfShare, seqOfPld, buyer, amt, _msgSender(50000));
    }

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external {
        IROPKeeper(_keepers[8]).refundDebt(seqOfShare, seqOfPld, amt, _msgSender(30000));
    }

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external {
        IROPKeeper(_keepers[8]).extendPledge(seqOfShare, seqOfPld, extDays, _msgSender(30000));
    }

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external {
        IROPKeeper(_keepers[8]).lockPledge(seqOfShare, seqOfPld, hashLock, _msgSender(50000));
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external {
        IROPKeeper(_keepers[8]).releasePledge(seqOfShare, seqOfPld, hashKey);
    }

    function execPledge(bytes32 snOfDeal, uint256 seqOfPld, uint version, uint buyer, uint groupOfBuyer) external {
        IROPKeeper(_keepers[8]).execPledge(snOfDeal, seqOfPld, version, msg.sender, buyer, groupOfBuyer, _msgSender(60000));
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external {
        IROPKeeper(_keepers[8]).revokePledge(seqOfShare, seqOfPld, _msgSender(10000));
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
        ISHAKeeper(_keepers[9]).execAlongRight(
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
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[9]).acceptAlongDeal(ia, seqOfDeal, _msgSender(60000), sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[9]).execAntiDilution(ia, seqOfDeal, seqOfShare, _msgSender(50000), sigHash);
    }

    function takeGiftShares(address ia, uint256 seqOfDeal) external {
        ISHAKeeper(_keepers[9]).takeGiftShares(ia, seqOfDeal, _msgSender(70000));
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[9]).execFirstRefusal(seqOfRule, seqOfRightholder, ia, seqOfDeal, _msgSender(60000), sigHash);
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external {
        ISHAKeeper(_keepers[9]).computeFirstRefusal(
                ia,
                seqOfDeal,
                _msgSender(60000)
            );
    }

    // ############
    // ##  Fund  ##
    // ############

    function proposeToTransferFund(
        bool toBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external {
        if (toBMM)
            IBMMKeeper(_keepers[3]).proposeToTransferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfVR, 
                executor, 
                _msgSender(50000)
            );
        else IGMMKeeper(_keepers[5]).proposeToTransferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfVR, 
                executor, 
                _msgSender(50000)
            );
    }

    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external {
        if (fromBMM)
            IBMMKeeper(_keepers[3]).transferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfMotion,
                _msgSender(50000)
            );
        else IGMMKeeper(_keepers[5]).transferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfMotion, 
                _msgSender(50000)
            );
        
        if (isCBP)
            _getRC().transfer(to, amt * 10 ** 9);
        else payable(to).transfer(amt * 10 ** 9);
    }

    // ###############
    // ##  Routing  ##
    // ###############

    function getROC() external view returns (IRegisterOfConstitution ) {
        return IRegisterOfConstitution(_books[1]);
    }

    function getSHA() external view returns (IShareholdersAgreement ) {
        return IShareholdersAgreement(IRegisterOfConstitution(_books[1]).pointer());
    }

    function getROD() external view returns (IRegisterOfDirectors ) {
        return IRegisterOfDirectors(_books[2]);
    }

    function getBMM() external view returns (IMeetingMinutes ) {
        return IMeetingMinutes(_books[3]);
    }

    function getROM() external view returns (IRegisterOfMembers ) {
        return IRegisterOfMembers(_books[4]);
    }

    function getGMM() external view returns (IMeetingMinutes ) {
        return IMeetingMinutes(_books[5]);
    }

    function getROA() external view returns (IRegisterOfAgreements) {
        return IRegisterOfAgreements(_books[6]);
    }

    function getROO() external view returns (IRegisterOfOptions ) {
        return IRegisterOfOptions(_books[7]);
    }

    function getROP() external view returns (IRegisterOfPledges ) {
        return IRegisterOfPledges(_books[8]);
    }

    function getROS() external view returns (IRegisterOfShares ) {
        return IRegisterOfShares(_books[9]);
    }
}

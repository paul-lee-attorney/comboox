// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
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

import "./common/access/RoyaltyCharge.sol";
import "./IGeneralKeeper_4.sol";

contract GeneralKeeper_4 is IGeneralKeeper_4, RoyaltyCharge {
    using Address for address;

    CompInfo private _info;

    mapping(uint256 => address) private _books;
    mapping(uint256 => address) private _keepers;
    mapping(uint256 => uint256) private _coffers;

    modifier isNormal() {
        require(_info.state == 0, "GK: deprecated");
        _;
    }

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setCompInfo (
        uint8 _currency,
        bytes19 _symbol,
        string memory _name
    ) external onlyDK {
        _info.currency = _currency;
        _info.symbol = _symbol;
        _info.name = _name;
    }

    function createCorpSeal() external onlyDK {
        _rc.regUser();
        _info.regNum = _rc.getMyUserNo();
        _info.regDate = uint48(block.timestamp);
    }

    function getCompInfo() external view returns(CompInfo memory) {
        return _info;
    }

    function getCompUser() external view onlyOwner returns (UsersRepo.User memory) {
        return _rc.getUser();
    }


    // ---- Keepers ----

    function regKeeper(
        uint256 title, 
        address keeper
    ) external onlyDK {
        _keepers[title] = keeper;
        emit RegKeeper(title, keeper, msg.sender);
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
        emit RegBook(title, book, msg.sender);
    } 

    function getBook(uint256 title) external view returns (address) {
        return _books[title];
    }

    // ##################
    // ##  ROCKeeper   ##
    // ##################

    function createSHA(uint version) external {
        IROCKeeper_2(_keepers[1]).createSHA(version, msg.sender); 
    }

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external {
        IROCKeeper_2(_keepers[1]).circulateSHA(body, docUrl, docHash, msg.sender); 
    }

    function signSHA(address sha, bytes32 sigHash) external {
        IROCKeeper_2(_keepers[1]).signSHA(sha, sigHash, msg.sender); 
    }

    function activateSHA(address body) external {
        IROCKeeper_2(_keepers[1]).activateSHA(body, msg.sender);
    }

    function acceptSHA(bytes32 sigHash) external {
        IROCKeeper_2(_keepers[1]).acceptSHA(sigHash, msg.sender); 
    }

    // ###################
    // ##   RODKeeper   ##
    // ###################

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper_2(_keepers[2]).takeSeat(seqOfMotion, seqOfPos, msg.sender);
    }

    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper_2(_keepers[2]).removeDirector(seqOfMotion, seqOfPos, msg.sender);         
    }

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper_2(_keepers[2]).takePosition(seqOfMotion, seqOfPos, msg.sender);
    }

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper_2(_keepers[2]).removeOfficer(seqOfMotion, seqOfPos, msg.sender);
    }

    function quitPosition(uint256 seqOfPos) external {
        IRODKeeper_2(_keepers[2]).quitPosition(seqOfPos, msg.sender);
    }

    // ###################
    // ##   BMMKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint candidate) external {
        IBMMKeeper_2(_keepers[3]).nominateOfficer(seqOfPos, candidate, msg.sender);
    }

    function createMotionToRemoveOfficer(uint256 seqOfPos) external {
        IBMMKeeper_2(_keepers[3]).createMotionToRemoveOfficer(seqOfPos, msg.sender);
    }

    function createMotionToApproveDoc(uint doc, uint seqOfVR, uint executor) external{
        IBMMKeeper_2(_keepers[3]).createMotionToApproveDoc(doc, seqOfVR, executor, msg.sender); 
    }

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external{
        IBMMKeeper_2(_keepers[3]).createAction(seqOfVR, targets, values, params, desHash, executor, msg.sender);
    }

    function entrustDelegaterForBoardMeeting(uint256 seqOfMotion, uint delegate) external {
        IBMMKeeper_2(_keepers[3]).entrustDelegaterForBoardMeeting(seqOfMotion, delegate, msg.sender); 
    }

    function proposeMotionToBoard (uint seqOfMotion) external {
        IBMMKeeper_2(_keepers[3]).proposeMotionToBoard(seqOfMotion, msg.sender);
    }

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external{
        IBMMKeeper_2(_keepers[3]).castVote(seqOfMotion, attitude, sigHash, msg.sender);
    }

    function voteCounting(uint256 seqOfMotion) external{
        IBMMKeeper_2(_keepers[3]).voteCounting(seqOfMotion, msg.sender);
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external{
        uint contents = IBMMKeeper_2(_keepers[3]).execAction(typeOfAction, targets, values, params, desHash, seqOfMotion, msg.sender);
        _execute(targets, values, params);
        emit ExecAction(contents);
    }

    function _execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params
    ) private {
        for (uint256 i = 0; i < targets.length; i++) {
            Address.valuedCallWithNoReturn(targets[i], params[i], values[i]);
        }
    }

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        IROMKeeper_2(_keepers[4]).setMaxQtyOfMembers(max);
    }

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external onlyDK {
        IROMKeeper_2(_keepers[4]).setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external {
        IROMKeeper_2(_keepers[4]).requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        IROMKeeper_2(_keepers[4]).withdrawPayInAmt(hashLock, seqOfShare);
    }

    function payInCapital(uint seqOfShare, uint amt) external payable {
        IROMKeeper_2(_keepers[4]).payInCapital(seqOfShare, amt, msg.value, msg.sender);
    }

    // ###################
    // ##   GMMKeeper   ##
    // ###################

    function nominateDirector(uint256 seqOfPos, uint candidate) external {
        IGMMKeeper_2(_keepers[5]).nominateDirector(seqOfPos, candidate, msg.sender);
    }

    function createMotionToRemoveDirector(uint256 seqOfPos) external {
        IGMMKeeper_2(_keepers[5]).createMotionToRemoveDirector(seqOfPos, msg.sender);
    }

    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external {
        IGMMKeeper_2(_keepers[5]).proposeDocOfGM(doc, seqOfVR, executor, msg.sender);
    }

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external {
        IGMMKeeper_2(_keepers[5]).createActionOfGM(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            msg.sender
        );
    }

    function proposeToDeprecateGK(address payable receiver) external {
        IGMMKeeper_2(_keepers[5]).proposeToDeprecateGK(receiver, msg.sender);
    }

    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external {
        IGMMKeeper_2(_keepers[5]).entrustDelegaterForGeneralMeeting(seqOfMotion, delegate, msg.sender);
    }

    function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external{
        IGMMKeeper_2(_keepers[5]).proposeMotionToGeneralMeeting(seqOfMotion, msg.sender);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external {
        IGMMKeeper_2(_keepers[5]).castVoteOfGM(seqOfMotion, attitude, sigHash, msg.sender);
    }

    function voteCountingOfGM(uint256 seqOfMotion) external {
        IGMMKeeper_2(_keepers[5]).voteCountingOfGM(seqOfMotion, msg.sender);
    }

    function execActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        uint contents = IGMMKeeper_2(_keepers[5]).execActionOfGM(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            msg.sender
        );
        _execute(targets, values, params);
        emit ExecAction(contents);
    }

    function deprecateGK(address payable receiver, uint seqOfMotion) external {
        IGMMKeeper_2(_keepers[5]).deprecateGK(receiver, seqOfMotion, msg.sender);

        uint balanceOfCBP = _rc.balanceOf(address(this));
        if (balanceOfCBP > 0) _rc.transfer(receiver, balanceOfCBP);

        uint balanceOfETH = address(this).balance;
        if (balanceOfETH > 0) Address.sendValue(receiver, balanceOfETH);

        _info.state = 1;
        _info.name = address(receiver).toString();
        _info.symbol = bytes19("DEPRECATED");

        emit DeprecateGK(receiver, balanceOfCBP, balanceOfETH);
    }

    // ###################
    // ##   ROAKeeper   ##
    // ###################

    function createIA(uint256 snOfIA) external {
        IROAKeeper_2(_keepers[6]).createIA(snOfIA, msg.sender);
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IROAKeeper_2(_keepers[6]).circulateIA(body, docUrl, docHash, msg.sender);
    }

    function signIA(address ia, bytes32 sigHash) external {
        IROAKeeper_2(_keepers[6]).signIA(ia, msg.sender, sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) 
    external{
        IROAKeeper_2(_keepers[6]).pushToCoffer(ia, seqOfDeal, hashLock, closingDeadline, msg.sender);
    }

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external{
        IROAKeeper_2(_keepers[6]).closeDeal(ia, seqOfDeal, hashKey);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external{
        IROAKeeper_2(_keepers[6]).issueNewShare(ia, seqOfDeal, msg.sender);
    }

    function transferTargetShare(address ia, uint256 seqOfDeal) external{
        IROAKeeper_2(_keepers[6]).transferTargetShare(ia, seqOfDeal, msg.sender);
    }

    function terminateDeal(address ia, uint256 seqOfDeal) external{
        IROAKeeper_2(_keepers[6]).terminateDeal(ia, seqOfDeal, msg.sender);
    }

    function payOffApprovedDeal(
        address ia,
        uint seqOfDeal
    ) external payable {
        IROAKeeper_2(_keepers[6]).payOffApprovedDeal(ia, seqOfDeal, msg.value, msg.sender );
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
        IROOKeeper_2(_keepers[7]).updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external{
        IROOKeeper_2(_keepers[7]).execOption(seqOfOpt, msg.sender);
    }

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge
    ) external{
        IROOKeeper_2(_keepers[7]).createSwap(seqOfOpt, seqOfTarget, paidOfTarget, seqOfPledge, msg.sender);
    }

    function payOffSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external payable {
        IROOKeeper_2(_keepers[7]).payOffSwap(seqOfOpt, seqOfSwap, msg.value, msg.sender);
    }

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external{
        IROOKeeper_2(_keepers[7]).terminateSwap(seqOfOpt, seqOfSwap, msg.sender);
    }

    function requestToBuy(address ia, uint seqOfDeal, uint paidOfTarget, uint seqOfPledge) external{
        IROOKeeper_2(_keepers[7]).requestToBuy(ia, seqOfDeal, paidOfTarget, seqOfPledge, msg.sender);
    }

    function payOffRejectedDeal(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap
    ) external payable {
        IROOKeeper_2(_keepers[7]).payOffRejectedDeal(ia, seqOfDeal, seqOfSwap, msg.value, msg.sender);
    }

    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap
    ) external {
        IROOKeeper_2(_keepers[7]).pickupPledgedShare(ia, seqOfDeal, seqOfSwap, msg.sender);        
    }

    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external{
        IROPKeeper_2(_keepers[8]).createPledge(snOfPld, paid, par, guaranteedAmt, execDays, msg.sender);
    }

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external{
        IROPKeeper_2(_keepers[8]).transferPledge(seqOfShare, seqOfPld, buyer, amt, msg.sender);
    }

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external{
        IROPKeeper_2(_keepers[8]).refundDebt(seqOfShare, seqOfPld, amt, msg.sender);
    }

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external{
        IROPKeeper_2(_keepers[8]).extendPledge(seqOfShare, seqOfPld, extDays, msg.sender);
    }

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external{
        IROPKeeper_2(_keepers[8]).lockPledge(seqOfShare, seqOfPld, hashLock, msg.sender);
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external{
        IROPKeeper_2(_keepers[8]).releasePledge(seqOfShare, seqOfPld, hashKey);
    }

    function execPledge(uint seqOfShare, uint256 seqOfPld, uint buyer, uint groupOfBuyer) external{
        IROPKeeper_2(_keepers[8]).execPledge(seqOfShare, seqOfPld, buyer, groupOfBuyer, msg.sender);
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external{
        IROPKeeper_2(_keepers[8]).revokePledge(seqOfShare, seqOfPld, msg.sender);
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
    ) external{
        ISHAKeeper_2(_keepers[9]).execAlongRight(
                ia,
                seqOfDeal,
                false,
                seqOfShare,
                paid,
                par,
                msg.sender,
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
    ) external{
        ISHAKeeper_2(_keepers[9]).execAlongRight(
                ia,
                seqOfDeal,
                true,
                seqOfShare,
                paid,
                par,
                msg.sender,
                sigHash
            );
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external{
        ISHAKeeper_2(_keepers[9]).acceptAlongDeal(ia, seqOfDeal, msg.sender, sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external{
        ISHAKeeper_2(_keepers[9]).execAntiDilution(ia, seqOfDeal, seqOfShare, msg.sender, sigHash);
    }

    function takeGiftShares(address ia, uint256 seqOfDeal) external{
        ISHAKeeper_2(_keepers[9]).takeGiftShares(ia, seqOfDeal, msg.sender);
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external{
        ISHAKeeper_2(_keepers[9]).execFirstRefusal(seqOfRule, seqOfRightholder, ia, seqOfDeal, msg.sender, sigHash);
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external{
        ISHAKeeper_2(_keepers[9]).computeFirstRefusal(
                ia,
                seqOfDeal,
                msg.sender
            );
    }

    // ############
    // ##  Fund  ##
    // ############

    function getCentPrice() external view returns(uint) {
        return _rc.getCentPriceInWei(_info.currency);
    }

    function saveToCoffer(uint acct, uint value) external{

        require (
                msg.sender == _keepers[4] ||
                msg.sender == _keepers[5] ||
                msg.sender == _keepers[6] ||
                msg.sender == _keepers[7] ||
                msg.sender == _keepers[10], 
            "GK.saveToCoffer: not correct Keeper");

        require(address(this).balance >= _coffers[0] + value,
            "GK.saveToCoffer: insufficient Eth");

        _coffers[acct] += value;
        _coffers[0] += value;

        emit SaveToCoffer(acct, value);        
    }

    function pickupDeposit() external isNormal{
 
        uint caller = _msgSender(msg.sender, 18000);
        uint value = _coffers[caller];

        if (value > 0) {

            _coffers[caller] = 0;
            _coffers[0] -= value;

            Address.sendValue(payable(msg.sender), value);

            emit PickupDeposit(msg.sender, caller, value);

        } else revert("GK.pickupDeposit: no balance");
    }

    function proposeToDistributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external{
        IGMMKeeper_2(_keepers[5]).proposeToDistributeProfits(
            amt, 
            expireDate, 
            seqOfVR, 
            executor, 
            msg.sender
        );
    }

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external{
        IGMMKeeper_2(_keepers[5]).distributeProfits(
            amt,
            expireDate, 
            seqOfMotion,
            msg.sender
        );

        emit DistributeProfits(amt, expireDate, seqOfMotion);
    }

    function proposeToTransferFund(
        bool toBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external{
        if (toBMM)
            IBMMKeeper_2(_keepers[3]).proposeToTransferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfVR, 
                executor, 
                msg.sender
            );
        else IGMMKeeper_2(_keepers[5]).proposeToTransferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfVR, 
                executor, 
                msg.sender
            );
    }

    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external isNormal{
        if (fromBMM)
            IBMMKeeper_2(_keepers[3]).transferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfMotion,
                msg.sender
            );
        else IGMMKeeper_2(_keepers[5]).transferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfMotion, 
                msg.sender
            );

        if (isCBP)
            _rc.transfer(to, amt);
        else {
            require (address(this).balance >= _coffers[0] + amt,
                "GK.tf: insufficient balance");

            Address.sendValue(payable(to), amt);
        }
    }

    receive() external payable {
        emit ReceivedCash(msg.sender, msg.value);
    }

    // #################
    // ##  LOOKeeper  ##
    // #################

    function regInvestor(uint groupRep, bytes32 idHash) external{
        ILOOKeeper_2(_keepers[10]).regInvestor(msg.sender, groupRep, idHash);
    }

    function approveInvestor(uint userNo, uint seqOfLR) external{
        ILOOKeeper_2(_keepers[10]).approveInvestor(userNo, msg.sender,seqOfLR);        
    }

    function revokeInvestor(uint userNo, uint seqOfLR) external{
        ILOOKeeper_2(_keepers[10]).revokeInvestor(userNo, msg.sender,seqOfLR);        
    }

    function placeInitialOffer(
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external{
        ILOOKeeper_2(_keepers[10]).placeInitialOffer(
            msg.sender,
            classOfShare,
            execHours,
            paid,
            price,
            seqOfLR
        );
    }

    function withdrawInitialOffer(
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external{
        ILOOKeeper_2(_keepers[10]).withdrawInitialOffer(
            msg.sender,
            classOfShare,
            seqOfOrder,
            seqOfLR
        );        
    }

    function placeSellOrder(
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR,
        bool sortFromHead
    ) external{
        ILOOKeeper_2(_keepers[10]).placeSellOrder(
            msg.sender,
            seqOfClass,
            execHours,
            paid,
            price,
            seqOfLR,
            sortFromHead
        );
    }

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external{
        ILOOKeeper_2(_keepers[10]).withdrawSellOrder(
            msg.sender,
            classOfShare,
            seqOfOrder
        );        
    }

    function placeBuyOrder(uint classOfShare, uint paid, uint price) external payable{
        ILOOKeeper_2(_keepers[10]).placeBuyOrder(
            msg.sender,
            classOfShare,
            paid,
            price,
            msg.value
        );
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

    function getLOO() external view returns (IListOfOrders ) {
        return IListOfOrders(_books[10]);
    }

    // ---- Eth ----

    function depositOfMine(uint user) external view returns(uint) {
        return _coffers[user];
    }

    function totalDeposits() external view returns(uint) {
        return _coffers[0];
    }
}

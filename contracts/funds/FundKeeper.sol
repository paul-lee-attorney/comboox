// SPDX-License-Identifier: UNLICENSED

/* *
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

import "../comps/common/access/AccessControl.sol";
import "./IFundKeeper.sol";

contract FundKeeper is IFundKeeper, AccessControl {
    using Address for address;

    CompInfo private _info;

    mapping(uint256 => address) private _books;
    mapping(uint256 => address) private _keepers;
    mapping(address => uint256) private _titleOfKeeper;
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
        _titleOfKeeper[_keepers[title]] = 0;
        _keepers[title] = keeper;
        _titleOfKeeper[keeper] = title;
        emit RegKeeper(title, keeper, msg.sender);
    }

    function isKeeper(address caller) external view returns (bool) {   
        return _titleOfKeeper[caller] > 0;
    }

    function getKeeper(uint256 title) external view returns (address) {
        return _keepers[title];
    }

    function getTitleOfKeeper(address keeper) external view returns (uint) {
        return _titleOfKeeper[keeper];
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
        IROCKeeper(_keepers[1]).createSHA(version, msg.sender); 
    }

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external {
        IROCKeeper(_keepers[1]).circulateSHA(body, docUrl, docHash, msg.sender); 
    }

    function signSHA(address sha, bytes32 sigHash) external {
        IROCKeeper(_keepers[1]).signSHA(sha, sigHash, msg.sender); 
    }

    function activateSHA(address body) external {
        IROCKeeper(_keepers[1]).activateSHA(body, msg.sender);
    }

    function acceptSHA(bytes32 sigHash) external {
        IROCKeeper(_keepers[1]).acceptSHA(sigHash, msg.sender); 
    }

    // ###################
    // ##   RODKeeper   ##
    // ###################

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).takeSeat(seqOfMotion, seqOfPos, msg.sender);
    }

    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).removeDirector(seqOfMotion, seqOfPos, msg.sender);
    }

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).takePosition(seqOfMotion, seqOfPos, msg.sender);
    }

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).removeOfficer(seqOfMotion, seqOfPos, msg.sender);
    }

    function quitPosition(uint256 seqOfPos) external {
        IRODKeeper(_keepers[2]).quitPosition(seqOfPos, msg.sender);
    }

    // ###################
    // ##   BMMKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint candidate) external {
        IBMMKeeper(_keepers[3]).nominateOfficer(seqOfPos, candidate, msg.sender);
    }

    function createMotionToRemoveOfficer(uint256 seqOfPos) external {
        IBMMKeeper(_keepers[3]).createMotionToRemoveOfficer(seqOfPos, msg.sender);
    }

    function createMotionToApproveDoc(uint doc, uint seqOfVR, uint executor) external{
        IBMMKeeper(_keepers[3]).createMotionToApproveDoc(doc, seqOfVR, executor, msg.sender); 
    }

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external{
        IBMMKeeper(_keepers[3]).createAction(seqOfVR, targets, values, params, desHash, executor, msg.sender);
    }

    function entrustDelegaterForBoardMeeting(uint256 seqOfMotion, uint delegate) external {
        IBMMKeeper(_keepers[3]).entrustDelegaterForBoardMeeting(seqOfMotion, delegate, msg.sender); 
    }

    function proposeMotionToBoard (uint seqOfMotion) external {
        IBMMKeeper(_keepers[3]).proposeMotionToBoard(seqOfMotion, msg.sender);
    }

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external{
        IBMMKeeper(_keepers[3]).castVote(seqOfMotion, attitude, sigHash, msg.sender);
    }

    function voteCounting(uint256 seqOfMotion) external{
        IBMMKeeper(_keepers[3]).voteCounting(seqOfMotion, msg.sender);
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external{
        uint contents = IBMMKeeper(_keepers[3]).execAction(typeOfAction, targets, values, params, desHash, seqOfMotion, msg.sender);
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

    function payInCapital(ICashier.TransferAuth memory auth, uint seqOfShare, uint paid) external {
        IROMKeeper(_keepers[4]).payInCapital(auth, seqOfShare, paid, msg.sender);
    }

    // ###################
    // ##   GMMKeeper   ##
    // ###################

    function nominateDirector(uint256 seqOfPos, uint candidate) external {
        IGMMKeeper(_keepers[5]).nominateDirector(seqOfPos, candidate, msg.sender);
    }

    function createMotionToRemoveDirector(uint256 seqOfPos) external {
        IGMMKeeper(_keepers[5]).createMotionToRemoveDirector(seqOfPos, msg.sender);
    }

    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external {
        IGMMKeeper(_keepers[5]).proposeDocOfGM(doc, seqOfVR, executor, msg.sender);
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
            msg.sender
        );
    }

    function proposeToDeprecateGK(address payable receiver) external {
        IGMMKeeper(_keepers[5]).proposeToDeprecateGK(receiver, msg.sender);
    }

    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external {
        IGMMKeeper(_keepers[5]).entrustDelegaterForGeneralMeeting(seqOfMotion, delegate, msg.sender);
    }

    function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external{
        IGMMKeeper(_keepers[5]).proposeMotionToGeneralMeeting(seqOfMotion, msg.sender);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external {
        IGMMKeeper(_keepers[5]).castVoteOfGM(seqOfMotion, attitude, sigHash, msg.sender);
    }

    function voteCountingOfGM(uint256 seqOfMotion) external {
        IGMMKeeper(_keepers[5]).voteCountingOfGM(seqOfMotion, msg.sender);
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
            msg.sender
        );
        _execute(targets, values, params);
        emit ExecAction(contents);
    }

    function deprecateGK(address payable receiver, uint seqOfMotion) external {
        IGMMKeeper(_keepers[5]).deprecateGK(receiver, seqOfMotion, msg.sender);

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
        IROAKeeper(_keepers[6]).createIA(snOfIA, msg.sender);
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IROAKeeper(_keepers[6]).circulateIA(body, docUrl, docHash, msg.sender);
    }

    function signIA(address ia, bytes32 sigHash) external {
        IROAKeeper(_keepers[6]).signIA(ia, msg.sender, sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) 
    external{
        IROAKeeper(_keepers[6]).pushToCoffer(ia, seqOfDeal, hashLock, closingDeadline, msg.sender);
    }

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external{
        IROAKeeper(_keepers[6]).closeDeal(ia, seqOfDeal, hashKey);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external{
        IROAKeeper(_keepers[6]).issueNewShare(ia, seqOfDeal, msg.sender);
    }

    function transferTargetShare(address ia, uint256 seqOfDeal) external{
        IROAKeeper(_keepers[6]).transferTargetShare(ia, seqOfDeal, msg.sender);
    }

    function terminateDeal(address ia, uint256 seqOfDeal) external{
        IROAKeeper(_keepers[6]).terminateDeal(ia, seqOfDeal, msg.sender);
    }

    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, address to
    ) external {
        IROAKeeper(_keepers[6]).payOffApprovedDeal(
            auth, ia, seqOfDeal, to, msg.sender
        );
    }


    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external{
        IROPKeeper(_keepers[8]).createPledge(snOfPld, paid, par, guaranteedAmt, execDays, msg.sender);
    }

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external{
        IROPKeeper(_keepers[8]).transferPledge(seqOfShare, seqOfPld, buyer, amt, msg.sender);
    }

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external{
        IROPKeeper(_keepers[8]).refundDebt(seqOfShare, seqOfPld, amt, msg.sender);
    }

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external{
        IROPKeeper(_keepers[8]).extendPledge(seqOfShare, seqOfPld, extDays, msg.sender);
    }

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external{
        IROPKeeper(_keepers[8]).lockPledge(seqOfShare, seqOfPld, hashLock, msg.sender);
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external{
        IROPKeeper(_keepers[8]).releasePledge(seqOfShare, seqOfPld, hashKey);
    }

    function execPledge(uint seqOfShare, uint256 seqOfPld, uint buyer, uint groupOfBuyer) external{
        IROPKeeper(_keepers[8]).execPledge(seqOfShare, seqOfPld, buyer, groupOfBuyer, msg.sender);
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external{
        IROPKeeper(_keepers[8]).revokePledge(seqOfShare, seqOfPld, msg.sender);
    }

    // ############
    // ##  Fund  ##
    // ############
    
    function initClass(uint class) external onlyDK {
        IAccountant(_keepers[12]).initClass(class);
    }

    function proposeToDistributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint seqOfDR,
        uint para,
        uint executor
    ) external {
        IGMMKeeper(_keepers[5]).proposeToDistributeUsd(
            amt, 
            expireDate,
            seqOfVR,
            seqOfDR,
            para,
            executor,
            msg.sender
        );
    }

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion
    ) external{
        IAccountant(_keepers[12]).distrProfits(
            amt,
            expireDate,
            seqOfDR,
            seqOfMotion,
            msg.sender
        );
    }

    function distributeIncome(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint fundManager,
        uint seqOfMotion
    ) external{
        IAccountant(_keepers[12]).distrIncome(
            amt,
            expireDate,
            seqOfDR,
            fundManager,
            seqOfMotion,
            msg.sender
        );
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
            IBMMKeeper(_keepers[3]).proposeToTransferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfVR, 
                executor, 
                msg.sender
            );
        else IGMMKeeper(_keepers[5]).proposeToTransferFund(
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
        IAccountant(_keepers[12]).transferFund(
            fromBMM, 
            to, 
            isCBP, 
            amt, 
            expireDate, 
            seqOfMotion, 
            msg.sender
        );
        if (isCBP) _rc.transfer(to, amt);
    }

    receive() external payable {
        emit ReceivedCash(msg.sender, msg.value);
    }

    // #################
    // ##  LOOKeeper  ##
    // #################

    function placeInitialOffer(
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external{
        ILOOKeeper(_keepers[10]).placeInitialOffer(
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
        ILOOKeeper(_keepers[10]).withdrawInitialOffer(
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
        uint seqOfLR
    ) external{
        ILOOKeeper(_keepers[10]).placeSellOrder(
            msg.sender,
            seqOfClass,
            execHours,
            paid,
            price,
            seqOfLR
        );
    }

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external{
        ILOOKeeper(_keepers[10]).withdrawSellOrder(
            msg.sender,
            classOfShare,
            seqOfOrder
        );        
    }

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, 
        uint paid, uint price, uint execHours
    ) external {
        ILOOKeeper(_keepers[10]).placeBuyOrder(
            auth, msg.sender, classOfShare, paid, price, execHours
        );
    }

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, 
        uint paid, uint execHours
    ) external{
        ILOOKeeper(_keepers[10]).placeMarketBuyOrder(
            auth, msg.sender, classOfShare, paid, execHours
        );
    }

    function withdrawBuyOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external {
        ILOOKeeper(_keepers[10]).withdrawBuyOrder(
            msg.sender,
            classOfShare,
            seqOfOrder
        );
    }

    // #################
    // ##  ROIKeeper  ##
    // #################

    function regInvestor(address bKey, uint groupRep, bytes32 idHash) external {
        IROIKeeper(_keepers[11]).regInvestor(
            msg.sender, bKey, groupRep, idHash
        );
    }

    function approveInvestor(uint userNo, uint seqOfLR) external{
        IROIKeeper(_keepers[11]).approveInvestor(userNo, msg.sender,seqOfLR);
    }

    function revokeInvestor(uint userNo, uint seqOfLR) external{
        IROIKeeper(_keepers[11]).revokeInvestor(userNo, msg.sender,seqOfLR);
    }

    // Add: burn Shares ?

    // #################
    // ##  RORKeeper  ##
    // #################

    function addRedeemableClass(uint class) external {
        IRORKeeper(_keepers[16]).addRedeemableClass(class, msg.sender);
    }

    function removeRedeemableClass(uint class) external {
        IRORKeeper(_keepers[16]).removeRedeemableClass(class, msg.sender);
    }

    function updateNavPrice(uint class, uint price) external {
        IRORKeeper(_keepers[16]).updateNavPrice(class, price, msg.sender);
    }

    function requestForRedemption(uint class, uint paid) external {
        IRORKeeper(_keepers[16]).requestForRedemption(class, paid, msg.sender);
    }

    function redeem(uint class, uint seqOfPack) external {
        IRORKeeper(_keepers[16]).redeem(class, seqOfPack, msg.sender);
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

    function getROP() external view returns (IRegisterOfPledges ) {
        return IRegisterOfPledges(_books[8]);
    }

    function getROS() external view returns (IRegisterOfShares ) {
        return IRegisterOfShares(_books[9]);
    }

    function getLOO() external view returns (IListOfOrders) {
        return IListOfOrders(_books[10]);
    }

    function getROI() external view returns (IRegisterOfInvestors) {
        return IRegisterOfInvestors(_books[11]);
    }

    function getBank() external view returns (IUSDC) {
        return IUSDC(_books[12]);
    }

    function getCashier() external view returns (ICashier) {
        return ICashier(_books[15]);
    }

    function getROR() external view returns (IRegisterOfRedemptions) {
        return IRegisterOfRedemptions(_books[16]);
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
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

import "./BaseKeeper.sol";

import "./ICoreKeeper.sol";

abstract contract CoreKeeper is ICoreKeeper, BaseKeeper {
    using Address for address;
    
    // ##################
    // ##  ROCKeeper   ##
    // ##################

    function createSHA(uint version) external {
        IROCKeeper(_keepers[uint8(TitleOfKeepers.ROCK)]).createSHA(version, msg.sender); 
    }

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external {
        IROCKeeper(_keepers[uint8(TitleOfKeepers.ROCK)]).circulateSHA(body, docUrl, docHash, msg.sender); 
    }

    function signSHA(address sha, bytes32 sigHash) external {
        IROCKeeper(_keepers[uint8(TitleOfKeepers.ROCK)]).signSHA(sha, sigHash, msg.sender); 
    }

    function activateSHA(address body) external {
        IROCKeeper(_keepers[uint8(TitleOfKeepers.ROCK)]).activateSHA(body, msg.sender);
    }

    function acceptSHA(bytes32 sigHash) external {
        IROCKeeper(_keepers[uint8(TitleOfKeepers.ROCK)]).acceptSHA(sigHash, msg.sender); 
    }

    // ###################
    // ##   BMMKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint candidate) external {
        IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).nominateOfficer(seqOfPos, candidate, msg.sender);
    }

    function createMotionToRemoveOfficer(uint256 seqOfPos) external {
        IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).createMotionToRemoveOfficer(seqOfPos, msg.sender);
    }

    function createMotionToApproveDoc(uint doc, uint seqOfVR, uint executor) external{
        IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).createMotionToApproveDoc(doc, seqOfVR, executor, msg.sender); 
    }

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external{
        IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).createAction(seqOfVR, targets, values, params, desHash, executor, msg.sender);
    }

    function entrustDelegaterForBoardMeeting(uint256 seqOfMotion, uint delegate) external {
        IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).entrustDelegaterForBoardMeeting(seqOfMotion, delegate, msg.sender); 
    }

    function proposeMotionToBoard (uint seqOfMotion) external {
        IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).proposeMotionToBoard(seqOfMotion, msg.sender);
    }

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external{
        IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).castVote(seqOfMotion, attitude, sigHash, msg.sender);
    }

    function voteCounting(uint256 seqOfMotion) external{
        IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).voteCounting(seqOfMotion, msg.sender);
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        uint contents = IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).execAction(typeOfAction, targets, values, params, desHash, seqOfMotion, msg.sender);
        _execute(targets, values, params);
        emit ExecAction(contents);
    }

    // ###################
    // ##   RODKeeper   ##
    // ###################

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[uint8(TitleOfKeepers.RODK)]).takeSeat(seqOfMotion, seqOfPos, msg.sender);
    }

    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[uint8(TitleOfKeepers.RODK)]).removeDirector(seqOfMotion, seqOfPos, msg.sender);         
    }

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[uint8(TitleOfKeepers.RODK)]).takePosition(seqOfMotion, seqOfPos, msg.sender);
    }

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external {
        IRODKeeper(_keepers[uint8(TitleOfKeepers.RODK)]).removeOfficer(seqOfMotion, seqOfPos, msg.sender);
    }

    function quitPosition(uint256 seqOfPos) external {
        IRODKeeper(_keepers[uint8(TitleOfKeepers.RODK)]).quitPosition(seqOfPos, msg.sender);
    }

    // ###################
    // ##   GMMKeeper   ##
    // ###################

    function nominateDirector(uint256 seqOfPos, uint candidate) external {
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).nominateDirector(seqOfPos, candidate, msg.sender);
    }

    function createMotionToRemoveDirector(uint256 seqOfPos) external {
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).createMotionToRemoveDirector(seqOfPos, msg.sender);
    }

    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external {
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).proposeDocOfGM(doc, seqOfVR, executor, msg.sender);
    }

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external {
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).createActionOfGM(
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
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).proposeToDeprecateGK(receiver, msg.sender);
    }

    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external {
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).entrustDelegaterForGeneralMeeting(seqOfMotion, delegate, msg.sender);
    }

    function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external{
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).proposeMotionToGeneralMeeting(seqOfMotion, msg.sender);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external {
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).castVoteOfGM(seqOfMotion, attitude, sigHash, msg.sender);
    }

    function voteCountingOfGM(uint256 seqOfMotion) external {
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).voteCountingOfGM(seqOfMotion, msg.sender);
    }

    function execActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        uint contents = IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).execActionOfGM(
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

    function _execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params
    ) private {
        for (uint256 i = 0; i < targets.length; i++) {
            Address.valuedCallWithNoReturn(targets[i], params[i], values[i]);
        }
    }

    function deprecateGK(address payable receiver, uint seqOfMotion) external {
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).deprecateGK(receiver, seqOfMotion, msg.sender);

        uint balanceOfCBP = _rc.balanceOf(address(this));
        if (balanceOfCBP > 0) _rc.transfer(receiver, balanceOfCBP);

        uint balanceOfETH = address(this).balance;
        if (balanceOfETH > 0) Address.sendValue(receiver, balanceOfETH);

        _info.state = 1;
        _info.name = address(receiver).toString();
        _info.symbol = bytes18("DEPRECATED");

        emit DeprecateGK(receiver, balanceOfCBP, balanceOfETH);
    }

    // ############
    // ##  Fund  ##
    // ############
    
    function proposeToDistributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint seqOfDR,
        uint fundManager,
        uint executor
    ) external{
        IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).proposeToDistributeUsd(
            amt, 
            expireDate,
            seqOfVR,
            seqOfDR,
            fundManager,
            executor,
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
            IBMMKeeper(_keepers[uint8(TitleOfKeepers.BMMK)]).proposeToTransferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfVR, 
                executor, 
                msg.sender
            );
        else IGMMKeeper(_keepers[uint8(TitleOfKeepers.GMMK)]).proposeToTransferFund(
                to, 
                isCBP, 
                amt, 
                expireDate, 
                seqOfVR, 
                executor, 
                msg.sender
            );
    }

    // ---- Receive ETH ----

    receive() external payable {
        emit ReceivedCash(msg.sender, msg.value);
    }

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        IROMKeeper(_keepers[uint8(TitleOfKeepers.ROMK)]).setMaxQtyOfMembers(max);
    }

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external onlyDK {
        IROMKeeper(_keepers[uint8(TitleOfKeepers.ROMK)]).setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external {
        IROMKeeper(_keepers[uint8(TitleOfKeepers.ROMK)]).requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        IROMKeeper(_keepers[uint8(TitleOfKeepers.ROMK)]).withdrawPayInAmt(hashLock, seqOfShare);
    }

    function payInCapital(ICashier.TransferAuth memory auth, uint seqOfShare, uint paid) external {
        IROMKeeper(_keepers[uint8(TitleOfKeepers.ROMK)]).payInCapital(auth, seqOfShare, paid, msg.sender);
    }

    // ###################
    // ##   ROAKeeper   ##
    // ###################

    function createIA(uint256 snOfIA) external {
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).createIA(snOfIA, msg.sender);
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).circulateIA(body, docUrl, docHash, msg.sender);
    }

    function signIA(address ia, bytes32 sigHash) external {
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).signIA(ia, msg.sender, sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) 
    external{
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).pushToCoffer(ia, seqOfDeal, hashLock, closingDeadline, msg.sender);
    }

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external{
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).closeDeal(ia, seqOfDeal, hashKey);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external{
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).issueNewShare(ia, seqOfDeal, msg.sender);
    }

    function transferTargetShare(address ia, uint256 seqOfDeal) external{
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).transferTargetShare(ia, seqOfDeal, msg.sender);
    }

    function terminateDeal(address ia, uint256 seqOfDeal) external{
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).terminateDeal(ia, seqOfDeal, msg.sender);
    }

    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, address to
    ) external {
        IROAKeeper(_keepers[uint8(TitleOfKeepers.ROAK)]).payOffApprovedDeal(
            auth, ia, seqOfDeal, to, msg.sender
        );
    }

    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external{
        IROPKeeper(_keepers[uint8(TitleOfKeepers.ROPK)]).createPledge(snOfPld, paid, par, guaranteedAmt, execDays, msg.sender);
    }

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external{
        IROPKeeper(_keepers[uint8(TitleOfKeepers.ROPK)]).transferPledge(seqOfShare, seqOfPld, buyer, amt, msg.sender);
    }

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external{
        IROPKeeper(_keepers[uint8(TitleOfKeepers.ROPK)]).refundDebt(seqOfShare, seqOfPld, amt, msg.sender);
    }

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external{
        IROPKeeper(_keepers[uint8(TitleOfKeepers.ROPK)]).extendPledge(seqOfShare, seqOfPld, extDays, msg.sender);
    }

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external{
        IROPKeeper(_keepers[uint8(TitleOfKeepers.ROPK)]).lockPledge(seqOfShare, seqOfPld, hashLock, msg.sender);
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external{
        IROPKeeper(_keepers[uint8(TitleOfKeepers.ROPK)]).releasePledge(seqOfShare, seqOfPld, hashKey);
    }

    function execPledge(uint seqOfShare, uint256 seqOfPld, uint buyer, uint groupOfBuyer) external{
        IROPKeeper(_keepers[uint8(TitleOfKeepers.ROPK)]).execPledge(seqOfShare, seqOfPld, buyer, groupOfBuyer, msg.sender);
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external{
        IROPKeeper(_keepers[uint8(TitleOfKeepers.ROPK)]).revokePledge(seqOfShare, seqOfPld, msg.sender);
    }

    // ###################
    // ##  Accountants  ##
    // ###################

    function _getAccountant() private view returns(IAccountant) {
        return IAccountant(_gk.getKeeper(12));
    }

    function initClass(uint class) external onlyDK {
        _getAccountant().initClass(class);
    }

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion
    ) external{
        _getAccountant().distrProfits(
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
    ) external {
        _getAccountant().distrIncome(
            amt,
            expireDate,
            seqOfDR,
            fundManager,
            seqOfMotion,
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
    ) external {
        _getAccountant().transferFund(
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

    // #################
    // ##  ROIKeeper  ##
    // #################

    function regInvestor(address bKey, uint groupRep, bytes32 idHash) external {
        IROIKeeper(_keepers[uint8(TitleOfKeepers.ROIK)]).regInvestor(
            msg.sender, bKey, groupRep, idHash
        );
    }

    function approveInvestor(uint userNo, uint seqOfLR) external{
        IROIKeeper(_keepers[uint8(TitleOfKeepers.ROIK)]).approveInvestor(userNo, msg.sender,seqOfLR);        
    }

    function revokeInvestor(uint userNo, uint seqOfLR) external{
        IROIKeeper(_keepers[uint8(TitleOfKeepers.ROIK)]).revokeInvestor(userNo, msg.sender,seqOfLR);
    }

}

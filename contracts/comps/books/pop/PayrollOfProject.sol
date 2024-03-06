// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
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

import "../../common/access/AccessControl.sol";

import "../../../lib/EnumerableSet.sol";
import "../../../lib/TeamsRepo.sol";

contract PayrollOfProject is AccessControl {
    using TeamsRepo for TeamsRepo.Repo;

    TeamsRepo.Repo private _pop;
	uint8 private _currency;

    function _msgSender(uint price) private returns (uint40 usr) {
        usr = _rc.getUserNo(
            msg.sender, 
            price * (10 ** 10), 
            _rc.getAuthorByBody(address(this))
        );
    }

    ///////////////////
    //   Write I/O   //
    ///////////////////

	function setManager(uint acct) external onlyOwner {
		_pop.setManager(acct);
	}

	function setCurrency(uint8 currency) external onlyOwner {
		_currency = currency;
	}

    function transferProject(uint newManager) external {
		_pop.transferProject(_msgSender(18000), newManager);
    }

    // ---- Project ----

    function setBudget(uint rate,uint estimated) external {
		_pop.setBudget(_msgSender(18000), rate, estimated);
	}

    function fixBudget() external {
		_pop.fixBudget(_msgSender(18000));
	}

    function increaseBudget(uint deltaQty) external {
		_pop.increaseBudget(_msgSender(18000), deltaQty);
	}

	// ---- Team ----

    function createTeam(uint rate, uint estimated) external {
		_pop.createTeam(_msgSender(18000), rate, estimated);
	}

    function updateTeam(
        uint seqOfTeam,
        uint rate,
        uint estimated
    ) external {
		_pop.updateTeam(_msgSender(18000), seqOfTeam, rate, estimated);
	}

    function enrollTeam(uint seqOfTeam) external {
		_pop.enrollTeam(_msgSender(18000), seqOfTeam);
	}

    function replaceLeader(uint seqOfTeam, uint leader) external {
		_pop.replaceLeader(_msgSender(18000), seqOfTeam, leader);
	}

    function increaseTeamBudget(uint seqOfTeam,uint deltaQty) external {
		_pop.increaseTeamBudget(_msgSender(18000), seqOfTeam, deltaQty);
	}

    // ---- Member ----

    function enrollMember(
        uint seqOfTeam,
        uint userNo,
        uint rate,
        uint estimated
    ) external {
		_pop.enrollMember(_msgSender(18000), seqOfTeam, userNo, rate, estimated);
	}    

	function removeMember(uint seqOfTeam, uint userNo) external {
		_pop.removeMember(_msgSender(18000), seqOfTeam, userNo);
	}

	function restoreMember(uint seqOfTeam, uint userNo) external {
		_pop.restoreMember(_msgSender(18000), seqOfTeam, userNo);
	}

	function extendPeriod(
		uint seqOfTeam,
		uint userNo,
		uint deltaQty
	) external {
		_pop.extendPeriod(_msgSender(18000), seqOfTeam, userNo, deltaQty);
	}

	// ---- Work ----

	function applyWorkingHour(uint seqOfTeam, uint hrs) external {
		_pop.applyWorkingHour(_msgSender(18000), seqOfTeam, hrs);
	}

	function verifyMemberWork(
		uint seqOfTeam,
		uint userNo,
		uint ratio
	) external {
		_pop.verifyMemberWork(_msgSender(18000), seqOfTeam, userNo, ratio);
	}

	function verifyTeamWork(uint seqOfTeam, uint ratio) external {
		_pop.verifyTeamWork(_msgSender(18000), seqOfTeam, ratio);
	}

	function payWages() external payable {
		_pop.distributePayment(msg.value, _rc.getCentPriceInWei(_currency));
	}

	function pickupDeposit(uint amt) external {
		_pop.pickupDeposit(_msgSender(18000), amt);
		payable(msg.sender).transfer(amt);
	}

    ///////////////////
    //   Read I/O    //
    ///////////////////

	function isManager(uint acct) external view returns(bool) {
		return _pop.isManager(acct);
	}

	function getProjectInfo() external view returns(TeamsRepo.Member memory) {
		return _pop.getProjectInfo();
	}

	// ---- Teams ----

	function qtyOfTeams () external view returns(uint) {
		return _pop.qtyOfTeams();
	}

	function qtyOfEnrolledTeams () external view returns(uint) {
		return _pop.qtyOfEnrolledTeams();
	}

	function getListOfTeams() external view returns(uint[] memory) {
		return _pop.getListOfTeams();
	}

	function teamIsEnrolled(uint seqOfTeam) external view returns(bool) {
		return _pop.teamIsEnrolled(seqOfTeam);
	}

	// ---- TeamInfo ----

	function isTeamLeader(uint acct, uint seqOfTeam) external view returns(bool) {
		return _pop.isTeamLeader(acct, seqOfTeam);
	}

	function getTeamInfo(uint seqOfTeam) external view returns(TeamsRepo.Member memory info) {
		return _pop.getTeamInfo(seqOfTeam);
	}

	// ---- Member ----

	function isMember(uint acct,uint seqOfTeam) external view returns (bool) {
		return _pop.isMember(acct, seqOfTeam);
	}

	function isEnrolledMember(uint acct,uint seqOfTeam) external view returns (bool) {
		return _pop.isEnrolledMember(acct, seqOfTeam);
	}

	function getMemberInfo(uint acct, uint seqOfTeam) external view 
		returns (TeamsRepo.Member memory m) 
	{
		m = _pop.getMemberInfo(acct, seqOfTeam);
	}

	// ---- Payroll ----

	function getPayroll() external view returns (uint[] memory list) {
		return _pop.getPayroll();
	}

	function inPayroll(uint acct) external view returns(bool) {
		return _pop.inPayroll(acct);
	}

	function getBalanceOf(uint acct) external view returns(uint) {
		return _pop.getBalanceOf(acct);
	}

	// ---- FullInfo ----

	function getFullInfo() external view returns(TeamsRepo.Member[] memory) {
		return _pop.getFullInfo();
	}

}





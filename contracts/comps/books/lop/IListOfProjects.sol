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

import "../../../lib/TeamsRepo.sol";

interface IListOfProjects {

	event SetManager(uint indexed manager);
	event SetCurrency(uint indexed currency);

	event SetBudget(uint indexed budget);
	event IncreaseBudget(uint indexed deltaAmt);

	event EnrollTeam(uint indexed seqOfTeam);
	event ReplaceLeader(uint indexed seqOfTeam, uint indexed leader);

	event VerifyMemberWork(uint indexed seqOfTeam, uint indexed userNo, uint indexed ratio);
	event VerifyTeamWork(uint indexed seqOfTeam, uint indexed ratio);

	event PayWages(uint indexed amt, uint indexed exRate);
	event PickupDeposit(address indexed caller, uint indexed amt);

    ///////////////////
    //   Write I/O   //
    ///////////////////

	function setManager(uint acct) external;

	function setCurrency(uint8 currency) external;

	// ---- Project ----

	function setBudget(uint budget) external;

	function fixBudget() external;

	function increaseBudget(uint deltaAmt) external;

	// ---- Team ----

	function createTeam(uint budget) external;

	function updateTeam(uint seqOfTeam, uint budget) external;

	function enrollTeam(uint seqOfTeam) external;

	function replaceLeader(uint seqOfTeam, uint leader) external;

	function increaseTeamBudget(uint seqOfTeam,uint deltaQty) external;

	// ---- Member ----

	function enrollMember(
		uint seqOfTeam,
		uint userNo,
		uint rate,
		uint estimated
	) external;

	function removeMember(uint seqOfTeam, uint userNo) external;

	function restoreMember(uint seqOfTeam, uint userNo) external;

	function increaseMemberBudget(
		uint seqOfTeam,
		uint userNo,
		uint delta
	) external;

	// ---- Work ----

	function applyWorkingHour(uint seqOfTeam, uint hrs) external;

	function verifyMemberWork(
		uint seqOfTeam,
		uint userNo,
		uint ratio
	) external;

	function verifyTeamWork(uint seqOfTeam, uint ratio) external;

	function payWages() external payable;

	function pickupDeposit(uint amt) external;

    ///////////////////
    //   Read I/O    //
    ///////////////////

	function getCurrency() external view returns(uint8);

	function isManager(uint acct) external view returns(bool);

	function getProjectInfo() external view returns(TeamsRepo.Member memory);

	// ---- Teams ----

	function qtyOfTeams () external view returns(uint);

	function getListOfTeams() external view returns(uint[] memory);

	function teamIsEnrolled(uint seqOfTeam) external view returns(bool);

	// ---- TeamInfo ----

	function isTeamLeader(uint acct, uint seqOfTeam) external view returns(bool);

	function getTeamInfo(uint seqOfTeam) external view returns(TeamsRepo.Member memory info);

	// ---- Member ----

	function isMember(uint acct,uint seqOfTeam) external view returns (bool);

	function isEnrolledMember(uint acct,uint seqOfTeam) external view returns (bool);

	function getTeamMembersList(uint seqOfTeam) external view returns(uint[] memory);

	function getMemberInfo(uint acct, uint seqOfTeam) external view 
			returns (TeamsRepo.Member memory m);

	function getMembersOfTeam(uint seqOfTeam) external view 
		returns (TeamsRepo.Member[] memory ls);

	// ---- Payroll ----

	function getPayroll() external view returns (uint[] memory list);

	function inPayroll(uint acct) external view returns(bool);

	function getBalanceOf(uint acct) external view returns(uint);

}
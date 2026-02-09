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

pragma solidity ^0.8.8;

import "../../../lib/TeamsRepo.sol";

/// @title IListOfProjects
/// @notice Project/team management interface for budgets, work, and payroll.
interface IListOfProjects {

	/// @notice Emitted when project manager is set.
	/// @param manager Manager user number.
	event SetManager(uint indexed manager);
	/// @notice Emitted when project currency is set.
	/// @param currency Currency code.
	event SetCurrency(uint indexed currency);

	/// @notice Emitted when project budget is initialized.
	/// @param budget Budget amount.
	event SetBudget(uint indexed budget);
	/// @notice Emitted when project budget is increased.
	/// @param deltaAmt Budget delta amount.
	event IncreaseBudget(uint indexed deltaAmt);

	/// @notice Emitted when a team is enrolled.
	/// @param seqOfTeam Team sequence.
	event EnrollTeam(uint indexed seqOfTeam);
	/// @notice Emitted when a team leader is replaced.
	/// @param seqOfTeam Team sequence.
	/// @param leader New leader user number.
	event ReplaceLeader(uint indexed seqOfTeam, uint indexed leader);

	/// @notice Emitted when a member's work is verified.
	/// @param seqOfTeam Team sequence.
	/// @param userNo Member user number.
	/// @param ratio Verification ratio.
	event VerifyMemberWork(uint indexed seqOfTeam, uint indexed userNo, uint indexed ratio);
	/// @notice Emitted when a team's work is verified.
	/// @param seqOfTeam Team sequence.
	/// @param ratio Verification ratio.
	event VerifyTeamWork(uint indexed seqOfTeam, uint indexed ratio);

	/// @notice Emitted when wages are paid.
	/// @param amt Wage amount.
	/// @param exRate Exchange rate.
	event PayWages(uint indexed amt, uint indexed exRate);
	/// @notice Emitted when a deposit is picked up.
	/// @param caller Caller address.
	/// @param amt Amount.
	event PickupDeposit(address indexed caller, uint indexed amt);

    ///////////////////
    //   Write I/O   //
    ///////////////////

	/// @notice Set project manager.
	/// @param acct Manager user number.
	function setManager(uint acct) external;

	/// @notice Set project currency code.
	/// @param currency Currency code (uint8).
	function setCurrency(uint8 currency) external;

	// ---- Project ----

	/// @notice Set initial project budget.
	/// @param budget Budget amount.
	function setBudget(uint budget) external;

	/// @notice Fix budget (lock initial state).
	function fixBudget() external;

	/// @notice Increase project budget.
	/// @param deltaAmt Increase amount.
	function increaseBudget(uint deltaAmt) external;

	// ---- Team ----

	/// @notice Create a new team.
	/// @param budget Team budget.
	function createTeam(uint budget) external;

	/// @notice Update team budget before approval.
	/// @param seqOfTeam Team sequence.
	/// @param budget New budget.
	function updateTeam(uint seqOfTeam, uint budget) external;

	/// @notice Approve and enroll a team.
	/// @param seqOfTeam Team sequence.
	function enrollTeam(uint seqOfTeam) external;

	/// @notice Replace team leader.
	/// @param seqOfTeam Team sequence.
	/// @param leader New leader user number.
	function replaceLeader(uint seqOfTeam, uint leader) external;

	/// @notice Increase team budget.
	/// @param seqOfTeam Team sequence.
	/// @param deltaQty Increase amount.
	function increaseTeamBudget(uint seqOfTeam,uint deltaQty) external;

	// ---- Member ----

	/// @notice Enroll a member into a team.
	/// @param seqOfTeam Team sequence.
	/// @param userNo Member user number.
	/// @param rate Pay rate.
	/// @param estimated Estimated budget.
	function enrollMember(
		uint seqOfTeam,
		uint userNo,
		uint rate,
		uint estimated
	) external;

	/// @notice Remove a member from a team.
	/// @param seqOfTeam Team sequence.
	/// @param userNo Member user number.
	function removeMember(uint seqOfTeam, uint userNo) external;

	/// @notice Restore a removed member.
	/// @param seqOfTeam Team sequence.
	/// @param userNo Member user number.
	function restoreMember(uint seqOfTeam, uint userNo) external;

	/// @notice Increase member budget.
	/// @param seqOfTeam Team sequence.
	/// @param userNo Member user number.
	/// @param delta Increase amount.
	function increaseMemberBudget(
		uint seqOfTeam,
		uint userNo,
		uint delta
	) external;

	// ---- Work ----

	/// @notice Apply working hours for approval.
	/// @param seqOfTeam Team sequence.
	/// @param hrs Working hours.
	function applyWorkingHour(uint seqOfTeam, uint hrs) external;

	/// @notice Verify a member's work.
	/// @param seqOfTeam Team sequence.
	/// @param userNo Member user number.
	/// @param ratio Approve ratio (0-10000).
	function verifyMemberWork(
		uint seqOfTeam,
		uint userNo,
		uint ratio
	) external;

	/// @notice Verify team work.
	/// @param seqOfTeam Team sequence.
	/// @param ratio Approve ratio (0-10000).
	function verifyTeamWork(uint seqOfTeam, uint ratio) external;

	/// @notice Pay wages to teams (payable in ETH/USDC rate context).
	function payWages() external payable;

	/// @notice Withdraw deposit from payroll.
	/// @param amt Amount.
	function pickupDeposit(uint amt) external;

    ///////////////////
    //   Read I/O    //
    ///////////////////

	/// @notice Get currency code.
	/// @return Currency code.
	function getCurrency() external view returns(uint8);

	/// @notice Check if user is manager.
	/// @param acct User number.
	/// @return True if manager.
	function isManager(uint acct) external view returns(bool);

	/// @notice Get project info record.
	/// @return Project info.
	function getProjectInfo() external view returns(TeamsRepo.Member memory);

	// ---- Teams ----

	/// @notice Get number of teams.
	/// @return Team count.
	function qtyOfTeams () external view returns(uint);

	/// @notice Get list of team ids.
	/// @return Team ids.
	function getListOfTeams() external view returns(uint[] memory);

	/// @notice Check if team is enrolled.
	/// @param seqOfTeam Team sequence.
	/// @return True if enrolled.
	function teamIsEnrolled(uint seqOfTeam) external view returns(bool);

	// ---- TeamInfo ----

	/// @notice Check if user is team leader.
	/// @param acct User number.
	/// @param seqOfTeam Team sequence.
	/// @return True if leader.
	function isTeamLeader(uint acct, uint seqOfTeam) external view returns(bool);

	/// @notice Get team info.
	/// @param seqOfTeam Team sequence.
	/// @return info Team info.
	function getTeamInfo(uint seqOfTeam) external view returns(TeamsRepo.Member memory info);

	// ---- Member ----

	/// @notice Check if user is team member.
	/// @param acct User number.
	/// @param seqOfTeam Team sequence.
	/// @return True if member.
	function isMember(uint acct,uint seqOfTeam) external view returns (bool);

	/// @notice Check if member is enrolled.
	/// @param acct User number.
	/// @param seqOfTeam Team sequence.
	/// @return True if enrolled.
	function isEnrolledMember(uint acct,uint seqOfTeam) external view returns (bool);

	/// @notice Get team member list.
	/// @param seqOfTeam Team sequence.
	/// @return Member list.
	function getTeamMembersList(uint seqOfTeam) external view returns(uint[] memory);

	/// @notice Get member info.
	/// @param acct User number.
	/// @param seqOfTeam Team sequence.
	/// @return m Member info.
	function getMemberInfo(uint acct, uint seqOfTeam) external view 
			returns (TeamsRepo.Member memory m);

	/// @notice Get members of a team.
	/// @param seqOfTeam Team sequence.
	/// @return ls Member list.
	function getMembersOfTeam(uint seqOfTeam) external view 
		returns (TeamsRepo.Member[] memory ls);

	// ---- Payroll ----

	/// @notice Get payroll list.
	/// @return list Payroll user ids.
	function getPayroll() external view returns (uint[] memory list);

	/// @notice Check if user is in payroll.
	/// @param acct User number.
	/// @return True if in payroll.
	function inPayroll(uint acct) external view returns(bool);

	/// @notice Get payroll balance.
	/// @param acct User number.
	/// @return Balance amount.
	function getBalanceOf(uint acct) external view returns(uint);

}
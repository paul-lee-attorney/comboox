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

pragma solidity ^0.8.24;

import "../../openzeppelin/utils/structs/EnumerableSet.sol";

/// @title TeamsRepo
/// @notice Repository for project teams, members, and payroll flows.
library TeamsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

	/// @notice Member or team/project info record.
	struct Member {
        uint16 seqOfTeam;
        uint40 userNo;
        uint8 state;
        uint32 rate; 
				uint32 workHours; // appliedAmt for Team / Project
        uint32 budgetAmt;
        uint32 approvedAmt;
        uint32 receivableAmt;
        uint32 paidAmt;
    }

	/// @notice Team with member list and records.
	struct Team {
        EnumerableSet.UintSet membersList;
        mapping(uint256 => Member) members;
    }

	/// @notice Repository of teams and payroll balances.
	struct Repo {
        EnumerableSet.UintSet teamsList;
        mapping(uint256 => Team) teams;
        EnumerableSet.UintSet payroll;
        mapping(uint256 => uint256) cashBox;
    }

	/// @notice Ensure caller is project manager.
	modifier onlyManager(Repo storage repo, uint caller) {
        if (!isManager(repo, caller)) {
            revert TR_WrongParty(bytes32("TR_NotManager"));
        }
        _;
    }

	/// @notice Ensure team exists in list.
	modifier onlyListedTeam(
        Repo storage repo,
        uint seqOfTeam
    ) {
        if (!teamIsListed(repo, seqOfTeam)) {
            revert TR_WrongInput(bytes32("TR_NotListedTeam"));
        }
        _;
    }
  
	/// @notice Ensure caller is team leader.
	modifier onlyTeamLeader(
        Repo storage repo, 
        uint caller,
        uint seqOfTeam
    ) {
        if (!isTeamLeader(repo, caller, seqOfTeam)) {
            revert TR_WrongParty(bytes32("TR_NotTeamLeader"));
        }
        _;
    }

    ///////////////////
    //     Error    //
    //////////////////

	error TR_WrongInput(bytes32 reason);
	error TR_WrongState(bytes32 reason);
	error TR_Overflow(bytes32 reason);
	error TR_WrongParty(bytes32 reason);

    ///////////////////
    //   Write I/O   //
    ///////////////////

	/// @notice Set initial project manager.
	/// @param repo Storage repo.
	/// @param acct Manager user number.
	function setManager(Repo storage repo, uint acct) public {
        repo.teams[0].members[0].userNo = uint40(acct);    
    }

	/// @notice Transfer project manager role.
	/// @param repo Storage repo.
	/// @param caller Current manager user number.
	/// @param newManager New manager user number.
	function transferProject(
        Repo storage repo,
        uint caller,
        uint newManager
    ) public onlyManager(repo, caller) {
        repo.teams[0].members[0].userNo = uint40(newManager);    
    }

    // ---- Project ----

	/// @notice Set initial project budget.
	/// @param repo Storage repo.
	/// @param caller Manager user number.
	/// @param budget Budget amount.
	function setBudget(
        Repo storage repo,
        uint caller,
        uint budget
    ) public onlyManager(repo, caller) {
        Member storage info = repo.teams[0].members[0];
        if (info.state != 0) {
			revert TR_WrongState(bytes32("TR_BudgetAlreadySet"));
		}
        info.budgetAmt = uint32(budget);
    }

	/// @notice Fix project budget (lock initial state).
	/// @param repo Storage repo.
	/// @param caller Manager user number.
	function fixBudget(Repo storage repo, uint caller) 
			public onlyManager(repo, caller) 
		{
        Member storage info = repo.teams[0].members[0];
        if (info.state != 0) {
			revert TR_WrongState(bytes32("TR_BudgetAlreadyFixed"));
		}
        info.state = 1;
    }

		/// @notice Increase project budget after fixation.
		/// @param repo Storage repo.
		/// @param caller Manager user number.
		/// @param deltaAmt Increase amount.
		function increaseBudget(
        Repo storage repo,
        uint caller,
				uint deltaAmt
    ) public onlyManager(repo, caller) {
        Member storage info = repo.teams[0].members[0];
        if (info.state == 0) {
			revert TR_WrongState(bytes32("TR_BudgetStillPending"));
		}
				info.budgetAmt += uint32(deltaAmt);
    }

    // ---- Team ----

	/// @notice Create a new team with leader and budget.
	/// @param repo Storage repo.
	/// @param caller Team leader user number.
	/// @param budget Team budget.
	function createTeam(
        Repo storage repo,
        uint caller,
        uint budget
    ) public {
				uint40 acct = uint40(caller);

        if (acct == 0) {
            revert TR_WrongInput(bytes32("TR_AddTeamZeroLeader"));
        }

        Member storage projInfo = 
            repo.teams[0].members[0];

        projInfo.seqOfTeam++;
				        
        Member storage teamInfo = 
						repo.teams[projInfo.seqOfTeam].members[0];

				teamInfo.seqOfTeam = projInfo.seqOfTeam;			
				teamInfo.userNo = acct;
				teamInfo.budgetAmt = uint32(budget);

				repo.teamsList.add(projInfo.seqOfTeam);
    }

	/// @notice Update team budget before approval.
	/// @param repo Storage repo.
	/// @param caller Team leader user number.
	/// @param seqOfTeam Team sequence.
	/// @param budget New budget.
	function updateTeam(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint budget
    ) public onlyTeamLeader(repo, caller, seqOfTeam){

        Member storage teamInfo = 
            repo.teams[seqOfTeam].members[0];

        if (teamInfo.state != 0) {
			revert TR_WrongState(bytes32("TR_TeamAlreadyApproved"));
		}

				teamInfo.budgetAmt = uint32(budget);
    }

	/// @notice Approve and enroll a listed team.
	/// @param repo Storage repo.
	/// @param caller Manager user number.
	/// @param seqOfTeam Team sequence.
	function enrollTeam(
        Repo storage repo,
        uint caller,
        uint seqOfTeam
    ) public onlyManager(repo, caller) 
			onlyListedTeam(repo, seqOfTeam)	
		{
        Member storage projInfo = 
            repo.teams[0].members[0];
        
        Member storage teamInfo = 
            repo.teams[seqOfTeam].members[0];

				_enrollMember(projInfo, teamInfo);
    }

		function _enrollMember(
			Member storage teamInfo,
			Member storage member
		) private {
        if (member.state != 0) {
			revert TR_WrongState(bytes32("TR_AlreadyEnrolled"));
		}

        if (teamInfo.budgetAmt < (teamInfo.approvedAmt + member.budgetAmt)) {
			revert TR_WrongState(bytes32("TR_BudgetOverflow"));
		}

        member.state = 1;
        teamInfo.approvedAmt += member.budgetAmt;
		}

	/// @notice Replace team leader.
	/// @param repo Storage repo.
	/// @param caller Manager user number.
	/// @param seqOfTeam Team sequence.
	/// @param leader New leader user number.
	function replaceLeader(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint leader
    ) public onlyManager(repo, caller) 
			onlyListedTeam(repo, seqOfTeam)
    {
				uint40 acct = uint40(leader);
				if (acct == 0) {
					revert TR_WrongInput(bytes32("TR_ZeroAcct"));
				}
				repo.teams[seqOfTeam].members[0].userNo = acct;
    }

	/// @notice Increase team budget by delta.
	/// @param repo Storage repo.
	/// @param caller Manager user number.
	/// @param seqOfTeam Team sequence.
	/// @param delta Increase amount.
	function increaseTeamBudget(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
				uint delta
    ) public onlyManager(repo, caller) 
        onlyListedTeam(repo, seqOfTeam)
    {
        Member storage projInfo = repo.teams[0].members[0];
        Member storage teamInfo = repo.teams[seqOfTeam].members[0];

				_increaseBudget(projInfo, teamInfo, delta);
    }

		function _increaseBudget(
			Member storage teamInfo,
			Member storage member,
			uint delta
		)	private {

			uint32 amt = uint32(delta);

			 if (amt == 0) {
					revert TR_WrongInput(bytes32("TR_ZeroAmt"));
				}
			
			if (teamInfo.budgetAmt < teamInfo.approvedAmt + amt) {
				revert TR_WrongState(bytes32("TR_BudgetOverflow"));
			}
			
			member.budgetAmt += amt;
			teamInfo.approvedAmt += amt;
		}

    // ---- Member ----

	/// @notice Enroll a member into a team.
	/// @param repo Storage repo.
	/// @param caller Team leader user number.
	/// @param seqOfTeam Team sequence.
	/// @param userNo Member user number.
	/// @param rate Pay rate.
	/// @param budgetAmt Member budget.
	function enrollMember(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint userNo,
        uint rate,
        uint budgetAmt
    ) public onlyTeamLeader(repo, caller, seqOfTeam) {    
        Team storage t = repo.teams[seqOfTeam];
        Member storage teamInfo = t.members[0];

				uint40 acct = uint40(userNo);
        if (acct == 0) {
            revert TR_WrongInput(bytes32("TR_ZeroAcct"));
        }

        if (t.membersList.contains(acct)) {
            revert TR_WrongState(bytes32("TR_AlreadyEnrolled"));
        }

        Member storage member = t.members[acct];

				member.seqOfTeam = teamInfo.seqOfTeam;
        member.userNo = acct;
				member.rate = uint32(rate);
				member.budgetAmt = uint32(budgetAmt);

				_enrollMember(teamInfo, member);				

        t.membersList.add(acct);
        repo.payroll.add(acct);
    }

		/// @notice Remove a member from team.
		/// @param repo Storage repo.
		/// @param caller Team leader user number.
		/// @param seqOfTeam Team sequence.
		/// @param userNo Member user number.
		function removeMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo
		) public {

				(Member storage teamInfo, Member storage member) = 
						_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);
				
				if (member.state == 0) {
					revert TR_WrongState(bytes32("TR_NotEnrolled"));
				}

				member.state = 0;

				teamInfo.approvedAmt -= (member.budgetAmt - member.receivableAmt);
				teamInfo.workHours -= (member.approvedAmt);
		}

		function _getTeamInfoAndMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo
		) private view returns(
				Member storage teamInfo,
				Member storage member 
		) {
				(teamInfo, member) = _getInfoAndMember(repo, seqOfTeam, userNo);
				if (teamInfo.userNo != caller) {
					revert TR_WrongParty(bytes32("TR_NotTeamLeader"));
				}
		}

		function _getInfoAndMember(
				Repo storage repo,
				uint seqOfTeam,
				uint userNo
		) private view onlyListedTeam(repo, seqOfTeam) returns(
				Member storage teamInfo,
				Member storage member 
		) {				
				Team storage t = repo.teams[seqOfTeam];
				teamInfo = t.members[0];
				
				if (!t.membersList.contains(userNo)) {
					revert TR_WrongState(bytes32("TR_NotListed"));
				}

				member = t.members[userNo];
		}


		/// @notice Restore a previously removed member.
		/// @param repo Storage repo.
		/// @param caller Team leader user number.
		/// @param seqOfTeam Team sequence.
		/// @param userNo Member user number.
		function restoreMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo
		) public {
			
				(Member storage teamInfo, Member storage member) = 
					_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);
				
				if (member.state != 0) {
					revert TR_WrongState(bytes32("TR_AlreadyEnrolled"));
				}

				uint32 balance = (member.budgetAmt - member.receivableAmt);
				if (teamInfo.budgetAmt < teamInfo.approvedAmt + balance) {
					revert TR_WrongState(bytes32("TR_BudgetOverflow"));
				}
				teamInfo.budgetAmt += balance;

				if (member.approvedAmt > 0) {
					member.state = 2;
					teamInfo.workHours += member.approvedAmt;				
				} else {
					member.state = 1;
				}
		}

		/// @notice Increase a member's budget within team.
		/// @param repo Storage repo.
		/// @param caller Team leader user number.
		/// @param seqOfTeam Team sequence.
		/// @param userNo Member user number.
		/// @param delta Increase amount.
		function increaseMemberBudget(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo,
				uint delta
		) public {
			
				(Member storage teamInfo, Member storage member) =
						_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);

				if (member.state == 0) {
					revert TR_WrongState(bytes32("TR_NotEnrolled"));
				}

				_increaseBudget(teamInfo, member, delta);
		}

		/// @notice Adjust a member's rate.
		/// @param repo Storage repo.
		/// @param caller Team leader user number.
		/// @param seqOfTeam Team sequence.
		/// @param userNo Member user number.
		/// @param increase True to increase, false to decrease.
		/// @param delta Rate delta.
		function adjustSalary(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo,
				bool increase,
				uint delta
		) public {

				( , Member storage member) = 
						_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);

				if (member.state == 0) {
					revert TR_WrongState(bytes32("TR_NotEnrolled"));
				}
				
				uint32 amt = uint32(delta);

				if (increase) {
					member.rate += amt;
				} else {
					if (member.rate < amt) {
						revert TR_WrongState(bytes32("TR_InsufficientAmt"));
					}
					member.rate -= amt;
				}
		}

	  // ---- Work ----

		/// @notice Apply working hours for approval.
		/// @param repo Storage repo.
		/// @param caller Member user number.
		/// @param seqOfTeam Team sequence.
		/// @param hrs Working hours.
		function applyWorkingHour(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint hrs
		) public {

				(, Member storage member) = _getInfoAndMember(repo, seqOfTeam, caller);

				if (member.state != 1) {
					revert TR_WrongState(bytes32("TR_WrongState"));
				}

				uint32 delta = uint32(member.rate * hrs);

				if (member.budgetAmt < member.receivableAmt + delta) {
					revert TR_WrongState(bytes32("TR_ExceedBudget"));
				}

				member.workHours += uint32(hrs);
				member.approvedAmt = delta;

				member.state = 2;
		}

		/// @notice Verify a member's applied work.
		/// @param repo Storage repo.
		/// @param caller Team leader user number.
		/// @param seqOfTeam Team sequence.
		/// @param userNo Member user number.
		/// @param ratio Approve ratio (0-10000).
		function verifyMemberWork(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo,
				uint ratio
		) public {
				if (ratio > 10000) {
					revert TR_WrongInput(bytes32("TR_RatioOverflow"));
				}

				(Member storage teamInfo, Member storage member) = 
					_getTeamInfoAndMember(repo, caller, seqOfTeam, userNo);

				if (member.state != 2) {
					revert TR_WrongState(bytes32("TR_WrongState"));
				}

				member.approvedAmt = uint32(member.approvedAmt * ratio / 10000);
				member.state = 3;

				teamInfo.workHours += member.approvedAmt;
		}

		/// @notice Verify team work and update receivables.
		/// @param repo Storage repo.
		/// @param caller Manager user number.
		/// @param seqOfTeam Team sequence.
		/// @param ratio Approve ratio (0-10000).
		function verifyTeamWork(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint ratio
		) public onlyManager(repo, caller) 
				onlyListedTeam(repo, seqOfTeam)
		{
				if (ratio > 10000) {
					revert TR_WrongInput(bytes32("TR_RatioOverflow"));
				}

				Team storage t = repo.teams[seqOfTeam];
				Member storage teamInfo = t.members[0];

				if (teamInfo.workHours == 0) {
					revert TR_WrongState(bytes32("TR_ZeroApplied"));
				}

				uint32 deltaAmt = uint32(teamInfo.workHours * ratio / 10000);
				teamInfo.receivableAmt += deltaAmt;

				Member storage proInfo = repo.teams[0].members[0];
				proInfo.receivableAmt += deltaAmt;

				_confirmTeamWork(t, ratio);

				teamInfo.workHours = 0;
		}

		function _confirmTeamWork(
				Team storage t,
				uint ratio
		) private {
				uint[] memory ls = t.membersList.values();
				uint len = ls.length;

				while (len > 0) {
						Member storage m = t.members[ls[len-1]];
						if (m.state == 3) {
								m.receivableAmt += uint32(m.approvedAmt * ratio / 10000);
								m.approvedAmt = 0;
								m.state = 1;
						}
						len--;
				}
		}

		/// @notice Distribute payment to all teams by receivables.
		/// @param repo Storage repo.
		/// @param amtInWei Amount in wei.
		/// @param centPriceInWei Cent price in wei.
		function distributePayment(
				Repo storage repo,
				uint amtInWei,
				uint centPriceInWei
		) public {

				uint[] memory ls = repo.teamsList.values();
				uint len = ls.length;
		
				Member storage projInfo = repo.teams[0].members[0];
		
				uint rate = amtInWei * 10000 / (projInfo.receivableAmt - projInfo.paidAmt);
				uint32 sum = 0;

				while (len > 0) {
						Team storage t = repo.teams[ls[len-1]];
						Member storage info = t.members[0];
						
						if (info.receivableAmt > info.paidAmt) {
								uint32 amt = _distributePackage(repo, t, rate, centPriceInWei);
								info.paidAmt += amt;	
								sum += amt;
						}
						
						len--;
				}

				projInfo.paidAmt += sum;
				repo.cashBox[0] += amtInWei;
		}

		function _distributePackage(
				Repo storage repo,
				Team storage t,
				uint rate,
				uint centPriceInWei
		) private returns (uint32 sum) {
				uint[] memory ls = t.membersList.values();
				uint len = ls.length;
				sum = 0;

				while (len > 0) {
						Member storage m = t.members[ls[len-1]];

						uint outstandingAmt = m.receivableAmt - m.paidAmt;

						if (outstandingAmt > 0) {
							repo.cashBox[m.userNo] += rate * outstandingAmt / 10000;

							uint32 amtFiat = uint32(rate * outstandingAmt / centPriceInWei / 10 ** 4);

							m.paidAmt += amtFiat;
							sum += amtFiat;
						}

						len--;
				}
		}

		/// @notice Withdraw balance from payroll.
		/// @param repo Storage repo.
		/// @param caller User number.
		/// @param amt Amount in wei.
		function pickupDeposit(
				Repo storage repo,
				uint caller,
				uint amt
		) public {
				if (!repo.payroll.contains(caller)) {
					revert TR_WrongState(bytes32("TR_NotInPayroll"));
				}

				uint balance = repo.cashBox[caller];

				if (balance < amt) {
					revert TR_WrongState(bytes32("TR_InsufficientBalance"));
				}
				
				repo.cashBox[caller] -= amt;
				repo.cashBox[0] -= amt;
		}

		///////////////////
		//   Read I/O    //
		///////////////////

		/// @notice Check if user is project manager.
		/// @param repo Storage repo.
		/// @param acct User number.
		function isManager(
				Repo storage repo,
				uint acct
		) public view returns(bool) {
				return acct > 0 &&
						repo.teams[0].members[0].userNo == acct;
		}

		/// @notice Get project info record.
		/// @param repo Storage repo.
		function getProjectInfo(
				Repo storage repo
		) public view returns(Member memory info) {
				info = repo.teams[0].members[0];
		}

		// ---- Teams ----

		/// @notice Get number of teams.
		/// @param repo Storage repo.
		function qtyOfTeams (
				Repo storage repo
		) public view returns(uint) {
				return repo.teams[0].members[0].seqOfTeam;
		}

		/// @notice Get list of team ids.
		/// @param repo Storage repo.
		function getListOfTeams(
				Repo storage repo
		) public view returns(uint[] memory) {
				return repo.teamsList.values();
		}

		/// @notice Check if team is listed.
		/// @param repo Storage repo.
		/// @param seqOfTeam Team sequence.
		function teamIsListed(
				Repo storage repo,
				uint seqOfTeam
		) public view returns(bool) {
				return repo.teamsList.contains(seqOfTeam);
		}

		/// @notice Check if team is enrolled.
		/// @param repo Storage repo.
		/// @param seqOfTeam Team sequence.
		function teamIsEnrolled(
				Repo storage repo,
				uint seqOfTeam
		) public view returns(bool) {
				return repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].members[0].state == 1;
		}

		// ---- TeamInfo ----

		/// @notice Check if user is team leader.
		/// @param repo Storage repo.
		/// @param acct User number.
		/// @param seqOfTeam Team sequence.
		function isTeamLeader(
				Repo storage repo,
				uint acct,
				uint seqOfTeam
		) public view returns(bool) {
				return repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].members[0].userNo == acct;
		}

		/// @notice Get team info record.
		/// @param repo Storage repo.
		/// @param seqOfTeam Team sequence.
		function getTeamInfo(
				Repo storage repo,
				uint seqOfTeam
		) public view returns(Member memory info) {
				if (repo.teamsList.contains(seqOfTeam)) {
					info = repo.teams[seqOfTeam].members[0];
				}
		}

		// ---- Member ----

		/// @notice Check if user is a team member.
		/// @param repo Storage repo.
		/// @param acct User number.
		/// @param seqOfTeam Team sequence.
		function isMember(
				Repo storage repo,
				uint acct,
				uint seqOfTeam
		) public view  returns (bool) {
				return repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].membersList.contains(acct);
		}

		/// @notice Check if member is enrolled.
		/// @param repo Storage repo.
		/// @param acct User number.
		/// @param seqOfTeam Team sequence.
		function isEnrolledMember(
				Repo storage repo,
				uint acct,
				uint seqOfTeam
		) public view returns (bool) {
				return repo.teamsList.contains(seqOfTeam) &&
					repo.teams[seqOfTeam].membersList.contains(acct) &&
					repo.teams[seqOfTeam].members[acct].state > 0;
		}

		/// @notice Get member list of a team.
		/// @param repo Storage repo.
		/// @param seqOfTeam Team sequence.
		function getTeamMembersList(
				Repo storage repo,
				uint seqOfTeam
		) public view returns (uint[] memory ls) {
				if (repo.teamsList.contains(seqOfTeam)) {
					ls = repo.teams[seqOfTeam].membersList.values();
				}
		}

		/// @notice Get member info for a team.
		/// @param repo Storage repo.
		/// @param acct User number.
		/// @param seqOfTeam Team sequence.
		function getMemberInfo(
				Repo storage repo,
				uint acct,
				uint seqOfTeam
		) public view returns (Member memory m) {

				if (repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].membersList.contains(acct)
				) {
					m = repo.teams[seqOfTeam].members[acct];
				}
		}

		/// @notice Get all members of a team.
		/// @param repo Storage repo.
		/// @param seqOfTeam Team sequence.
		function getMembersOfTeam(Repo storage repo,uint seqOfTeam) 
				public view returns (Member[] memory) 
		{
				uint[] memory ls = getTeamMembersList(repo, seqOfTeam);
				uint len = ls.length;
				Member[] memory output = new Member[](len);
				
				Team storage t = repo.teams[seqOfTeam];

				while (len > 0) {
						output[len-1] = t.members[ls[len-1]];
						len--;
				}

				return output;
		}

		// ---- Payroll ----

		/// @notice Get payroll user list.
		/// @param repo Storage repo.
		function getPayroll(
				Repo storage repo
		) public view returns (uint[] memory list) {
				return repo.payroll.values();
		}

		/// @notice Check if user is in payroll.
		/// @param repo Storage repo.
		/// @param acct User number.
		function inPayroll(
				Repo storage repo,
				uint acct
		) public view returns(bool) {
				return repo.payroll.contains(acct);
		}

		/// @notice Get payroll balance for user.
		/// @param repo Storage repo.
		/// @param acct User number.
		function getBalanceOf(
				Repo storage repo,
				uint acct
		) public view returns(uint) {
				return repo.cashBox[acct];
		}
}
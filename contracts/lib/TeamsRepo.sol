// SPDX-License-Identifier: UNLICENSED

/* *
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

import "./EnumerableSet.sol";

library TeamsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Member {
        uint16 seqOfTeam;
        uint40 userNo;
        uint8 state;
        uint32 rate;
        uint16 estimated;
        uint16 applied;
        uint32 budgetAmt;
        uint32 pendingAmt;
        uint32 receivableAmt;
        uint32 paidAmt;
    }

    struct Team {
        EnumerableSet.UintSet membersList;
        mapping(uint256 => Member) members;
    }

    struct Repo {
        EnumerableSet.UintSet teamsList;
        mapping(uint256 => Team) teams;
        EnumerableSet.UintSet payroll;
        mapping(uint256 => uint256) piggyBox;
    }

    modifier onlyManager(Repo storage repo, uint caller) {
        require(isManager(repo, caller),
            "TR.onlyManager: not");
        _;
    }

    modifier onlyListedTeam(
        Repo storage repo,
        uint seqOfTeam
    ) {
        require(teamIsListed(repo, seqOfTeam),
          "TR.onlyListedTeam: not");
        _;
    }
  
    modifier onlyTeamLeader(
        Repo storage repo, 
        uint caller,
        uint seqOfTeam
    ) {
        require(isTeamLeader(repo, caller, seqOfTeam),
            "TR.onlyTeamLeader: not");
        _;
    }

    ///////////////////
    //   Write I/O   //
    ///////////////////

    function setManager(
        Repo storage repo,
        uint acct
    ) public {
        repo.teams[0].members[0].userNo = uint40(acct);    
    }

    function transferProject(
        Repo storage repo,
        uint caller,
        uint newManager
    ) public onlyManager(repo, caller) {
        repo.teams[0].members[0].userNo = uint40(newManager);    
    }

    // ---- Project ----

    function setBudget(
        Repo storage repo,
        uint caller,
        uint rate,
        uint estimated
    ) public onlyManager(repo, caller) {

        Member storage info = repo.teams[0].members[0];

        require (info.state == 0,
            "TR.setProject: already approved");

        info.rate = uint32(rate);
        info.estimated = uint16(estimated);
    }

    function fixBudget(
        Repo storage repo,
        uint caller
    ) public onlyManager(repo, caller) {
        Member storage info = repo.teams[0].members[0];

        require (info.state == 0,
            "TR.approveProject: already fixed");

        require (info.rate * info.estimated > 0,
            "TR.approveProject: zero budget");

        info.budgetAmt = info.rate * info.estimated;
        info.state = 1;
    }

    function increaseBudget(
        Repo storage repo,
        uint caller,
        uint deltaQty
    ) public onlyManager(repo, caller) {
        require (deltaQty > 0,
            "TR.increaseProBudget: zero delta qty");

        Member storage info = repo.teams[0].members[0];

        require (info.state == 1,
            "TR.increaseProBudget: pending project");

        info.estimated += uint16(deltaQty);
        info.budgetAmt += uint32(info.rate * deltaQty);
    }

    // ---- Team ----

    function createTeam(
        Repo storage repo,
        uint caller,
        uint rate,
        uint estimated
    ) public {
        require(caller > 0,
            "TR.addTeam: zero leader");

        Member storage projInfo = 
            repo.teams[0].members[0];

        projInfo.seqOfTeam++;
				        
        Member storage teamInfo = 
						repo.teams[projInfo.seqOfTeam].members[0];

        teamInfo.userNo = uint16(caller);
        teamInfo.rate = uint32(rate);
        teamInfo.estimated = uint16(estimated);

        teamInfo.seqOfTeam = projInfo.seqOfTeam;

				repo.teamsList.add(projInfo.seqOfTeam);
    }

    function updateTeam(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint rate,
        uint estimated
    ) public onlyTeamLeader(repo, caller, seqOfTeam){

        Member storage teamInfo = 
            repo.teams[seqOfTeam].members[0];

        require(teamInfo.state == 0,
            "updateTeam: already approved");

        teamInfo.rate = uint32(rate);
        teamInfo.estimated = uint16(estimated);
    }

    function enrollTeam(
        Repo storage repo,
        uint caller,
        uint seqOfTeam
    ) public onlyManager(repo, caller) {

        Member storage projInfo = 
            repo.teams[0].members[0];
        
        require(repo.teamsList.contains(seqOfTeam),
            "enrollTeam: not listed");

        Member storage teamInfo = 
            repo.teams[seqOfTeam].members[0];

        require(teamInfo.state == 0,
            "enrollTeam: already enrolled");

        uint32 budget = 
            teamInfo.rate * teamInfo.estimated;

        require(projInfo.budgetAmt >= 
            (projInfo.pendingAmt + budget),
            "enrollTeam: budget overflow");

        teamInfo.state = 1;

        projInfo.pendingAmt += budget;
    }

    function replaceLeader(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint leader
    ) public onlyManager(repo, caller) 
        onlyListedTeam(repo, seqOfTeam)
    {
        repo.teams[seqOfTeam].members[0].userNo = 
            uint40(leader);
    }

    function increaseTeamBudget(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint deltaQty
    ) public onlyManager(repo, caller) 
        onlyListedTeam(repo, seqOfTeam)
    {

        require (deltaQty > 0,
            "TR.increaseTeamBudget: zero delta");

        Member storage projInfo = repo.teams[0].members[0];

        Member storage teamInfo = repo.teams[seqOfTeam].members[0];

        uint32 deltaBudget = uint32 (teamInfo.rate * deltaQty);

        require (projInfo.budgetAmt >= 
            (projInfo.pendingAmt + deltaBudget),
            "TR.increaseTeamBudget: budget overflow");
        
        teamInfo.estimated += uint16(deltaQty);
        // teamInfo.budgetAmt += deltaBudget;

        projInfo.pendingAmt += deltaBudget;
    }

    // ---- Member ----

    function enrollMember(
        Repo storage repo,
        uint caller,
        uint seqOfTeam,
        uint userNo,
        uint rate,
        uint estimated
    ) public onlyTeamLeader(repo, caller, seqOfTeam) {    
        Team storage t = repo.teams[seqOfTeam];
        Member storage teamInfo = t.members[0];
        Member memory input;

        input.userNo = uint40(userNo);
        input.rate = uint32(rate);
        input.estimated = uint16(estimated);
        
        require(input.userNo > 0,
            "enrollMember: zero userNo");

        require(!t.membersList.contains(input.userNo),
            "enrollMember: already listed");

        input.budgetAmt = input.rate * input.estimated;

        require(input.budgetAmt > 0,
	          "enrollMember: zero budget");

        require((teamInfo.rate * teamInfo.estimated) >= 
  	        (teamInfo.budgetAmt + input.budgetAmt),
    	      "enrollMember: budget overflow");

        Member storage m = t.members[input.userNo];

        m.userNo = input.userNo;
        m.rate = input.rate;
        m.estimated = input.estimated;
        m.budgetAmt = input.budgetAmt;
				
				m.seqOfTeam = teamInfo.seqOfTeam;

        m.state = 1;

        t.membersList.add(input.userNo);
        teamInfo.budgetAmt += input.budgetAmt;

        repo.payroll.add(input.userNo);
    }

		function removeMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo
		) public onlyTeamLeader(repo, caller, seqOfTeam) {

				Team storage t = repo.teams[seqOfTeam];
				Member storage teamInfo = t.members[0];
				
				require(t.membersList.contains(userNo),
						"removeMember: not listed");

				Member storage m = t.members[userNo];
				
				require(m.state == 1,
						"removeMember: not enrolled");

				m.state = 0;

				teamInfo.budgetAmt -= (m.budgetAmt - m.receivableAmt);
		}

		function restoreMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo
		) public onlyTeamLeader(repo, caller, seqOfTeam) {
			
				Team storage t = repo.teams[seqOfTeam];
				Member storage teamInfo = t.members[0];

				require(t.membersList.contains(userNo),
						"removeMember: not listed");

				Member storage m = t.members[userNo];
				
				require(m.state == 0,
						"removeMember: already enrolled");

				uint32 balance = (m.budgetAmt - m.receivableAmt);

				require((teamInfo.rate * teamInfo.estimated) >=
						(teamInfo.budgetAmt + balance),
						"enrollMember: budget overflow");

				m.state = 1;
				teamInfo.budgetAmt += balance;
		}

		function extendPeriod(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo,
				uint deltaQty
		) public onlyTeamLeader(repo, caller, seqOfTeam) {
			
				Team storage t = repo.teams[seqOfTeam];
				Member storage teamInfo = t.members[0];
				
				require(t.membersList.contains(userNo),
						"extendPeriod: not listed");

				Member storage m = t.members[userNo];

				require(m.state > 0,
						"extendPeriod: not enrolled");

				uint32 deltaAmt = uint32(m.rate * deltaQty);

				require((teamInfo.rate * teamInfo.estimated) >=
						(teamInfo.budgetAmt + deltaAmt),
						"extendPeriod: budget overflow");

				m.estimated += uint16(deltaQty);

				m.budgetAmt += deltaAmt;
				teamInfo.budgetAmt += deltaAmt;
		}

	  // ---- Work ----

		function applyWorkingHour(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint hrs
		) public onlyListedTeam(repo, seqOfTeam) {

				Team storage t = repo.teams[seqOfTeam];

				require(t.membersList.contains(caller),
						"TR.applyHr: not listed");

				Member storage m = t.members[caller];

				require(m.state == 1,
						"TR.applyHr: wrong state");

				uint16 delta = uint16(hrs);

				require(m.estimated >= (m.applied + delta),
						"TR.applyHr: exceed budget");

				m.applied += delta;
				m.pendingAmt = m.rate * delta;

				m.state = 2;
		}

		function verifyMemberWork(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint userNo,
				uint ratio
		) public onlyListedTeam(repo, seqOfTeam) {
				require(ratio <= 10000,
						"TR.verifyHr: ratio overflow");

				Team storage t = repo.teams[seqOfTeam];
				Member storage teamInfo = t.members[0];

				require(teamInfo.userNo == uint40(caller),
						"TR.verifyHr: not leader");

				require(t.membersList.contains(userNo),
						"TR.applyHr: user not listed");

				Member storage m = t.members[userNo];

				require(m.state == 2,
						"TR.verifyHr: wrong member state");

				m.pendingAmt = uint32(m.pendingAmt * ratio / 10000);
				m.state = 3;

				teamInfo.pendingAmt += m.pendingAmt;
		}

		function verifyTeamWork(
				Repo storage repo,
				uint caller,
				uint seqOfTeam,
				uint ratio
		) public onlyManager(repo, caller) 
				onlyListedTeam(repo, seqOfTeam)
		{
				require(ratio <= 10000,
						"TR.verifyHr: ratio overflow");

				Team storage t = repo.teams[seqOfTeam];
				Member storage teamInfo = t.members[0];

				require(teamInfo.pendingAmt > 0,
						"TR.approveTeamWork: zero pendingAmt");

				uint32 deltaAmt = uint32(teamInfo.pendingAmt * ratio / 10000);
				teamInfo.receivableAmt += deltaAmt;

				Member storage proInfo = repo.teams[0].members[0];
				proInfo.receivableAmt += deltaAmt;

				_confirmTeamWork(t, ratio);

				teamInfo.pendingAmt = 0;
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
								m.receivableAmt += uint32(m.pendingAmt * ratio / 10000);
								m.pendingAmt = 0;
								m.state = 1;
						}
						len--;
				}
		}

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
								sum+= _distributePackage(repo, t, info, rate, centPriceInWei);
						}
						
						len--;
				}

				projInfo.paidAmt += sum;
				repo.piggyBox[0] += amtInWei;
		}

		function _distributePackage(
				Repo storage repo,
				Team storage t,
				Member storage info,
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
								uint amt = rate * outstandingAmt / 10000;

								repo.piggyBox[m.userNo] += amt;

								uint32 amtFiat = uint32((amt * 10 / centPriceInWei + 5)/10);

								m.paidAmt += amtFiat;
								sum += amtFiat;
						}

						len--;
				}

				info.paidAmt += sum;
		}

		function pickupDeposit(
				Repo storage repo,
				uint caller,
				uint amt
		) public {
				require (repo.payroll.contains(caller),
						"TR.pickupDeposit: not in payroll");

				uint balance = repo.piggyBox[caller];

				require (balance >= amt,
						"TR.pickupDeposit: insufficient balance");
				
				repo.piggyBox[caller] -= amt;
				repo.piggyBox[0] -= amt;
		}

		///////////////////
		//   Read I/O    //
		///////////////////

		function isManager(
				Repo storage repo,
				uint caller
		) public view returns(bool) {
				Member memory info = repo.teams[0].members[0];
				return caller > 0 && info.userNo == caller;
		}

		function getProjectInfo(
				Repo storage repo
		) public view returns(Member memory info) {
				info = repo.teams[0].members[0];
		}

		// ---- Teams ----

		function qtyOfTeams (
				Repo storage repo
		) public view returns(uint) {
				return repo.teams[0].members[0].seqOfTeam;
		}

		function getListOfTeams(
				Repo storage repo
		) public view returns(uint[] memory) {
				return repo.teamsList.values();
		}

		function teamIsListed(
				Repo storage repo,
				uint seqOfTeam
		) public view returns(bool) {
				return repo.teamsList.contains(seqOfTeam);
		}

		function teamIsEnrolled(
				Repo storage repo,
				uint seqOfTeam
		) public view returns(bool) {
				return repo.teamsList.contains(seqOfTeam) &&
						repo.teams[seqOfTeam].members[0].state == 1;
		}

		// ---- TeamInfo ----

		function isTeamLeader(
				Repo storage repo,
				uint caller,
				uint seqOfTeam
		) public view onlyListedTeam(repo, seqOfTeam) 
		returns(bool) {
				Member memory info = repo.teams[seqOfTeam].members[0];
				return info.userNo == caller;
		}

		function getTeamInfo(
				Repo storage repo,
				uint seqOfTeam
		) public view onlyListedTeam(repo, seqOfTeam)
		returns(Member memory info) {
				info = repo.teams[seqOfTeam].members[0];
		}

		// ---- Member ----

		function isMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam
		) public view onlyListedTeam(repo, seqOfTeam) 
		returns (bool) {
				Team storage t = repo.teams[seqOfTeam];
				return t.membersList.contains(caller);
		}

		function isEnrolledMember(
				Repo storage repo,
				uint caller,
				uint seqOfTeam
		) public view onlyListedTeam(repo, seqOfTeam) 
		returns (bool) {
				Member memory m = repo.teams[seqOfTeam].members[caller];
				return m.state > 0;
		}

		function getTeamMembersList(
				Repo storage repo,
				uint seqOfTeam
		) public view onlyListedTeam(repo, seqOfTeam) 
		returns (uint[] memory) {
				return repo.teams[seqOfTeam].membersList.values();
		}

		function getMemberInfo(
				Repo storage repo,
				uint caller,
				uint seqOfTeam
		) public view onlyListedTeam(repo, seqOfTeam)
		returns (Member memory m) {
				require(repo.teams[seqOfTeam].membersList.contains(caller),
						"TR.getMembersInfo: not listed");
				m = repo.teams[seqOfTeam].members[caller];
		}

		function getMembersOfTeam(
				Repo storage repo,
				uint seqOfTeam
		) public view onlyListedTeam(repo, seqOfTeam) 
		returns (Member[] memory) {
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

		function getPayroll(
				Repo storage repo
		) public view returns (uint[] memory list) {
				return repo.payroll.values();
		}

		function inPayroll(
				Repo storage repo,
				uint caller
		) public view returns(bool) {
				return repo.payroll.contains(caller);
		}

		function getBalanceOf(
				Repo storage repo,
				uint caller
		) public view returns(uint) {
				return repo.piggyBox[caller];
		}
}
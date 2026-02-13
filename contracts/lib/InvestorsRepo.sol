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

/// @title InvestorsRepo
/// @notice Repository for investor onboarding and approval status.
library InvestorsRepo {

    /// @notice Lifecycle state of an investor.
    enum StateOfInvestor {
        Pending,
        Approved,
        Revoked
    }

    /// @notice Investor record.
    struct Investor {
        uint40 userNo;
        uint40 groupRep;
        uint48 regDate;
        uint40 verifier;
        uint48 approveDate;
        uint32 data;
        uint8 state;
        bytes32 idHash;
    }

    /// @notice Storage repo keyed by user number.
    struct Repo {
        mapping(uint256 => Investor) investors;
        uint[] investorsList;
    }

    //################
    //##  Modifier  ##
    //################

    /// @notice Ensure the investor exists.
    /// @param repo Storage repo.
    /// @param acct Investor user number.
    modifier investorExist(
        Repo storage repo,
        uint acct
    ) {
        require(isInvestor(repo, acct),
            "OR.investorExist: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Investor ====

    /// @notice Register or update investor profile.
    /// @param repo Storage repo.
    /// @param userNo Investor user number.
    /// @param groupRep Group representative user number.
    /// @param idHash Hash of investor ID document.
    function regInvestor(
        Repo storage repo,
        uint userNo,
        uint groupRep,
        bytes32 idHash
    ) public {
        require(idHash != bytes32(0), 
            "OR.regInvestor: zero idHash");
        
        uint40 user = uint40(userNo);

        require(user > 0,
            "OR.regInvestor: zero userNo");

        Investor storage investor = repo.investors[user];
        
        investor.userNo = user;
        investor.groupRep = uint40(groupRep);
        investor.idHash = idHash;

        if (!isInvestor(repo, userNo)) {
            repo.investorsList.push(user);
            investor.regDate = uint48(block.timestamp);
        } else {
            if (investor.state == uint8(StateOfInvestor.Approved))
                _decreaseQtyOfInvestors(repo);
            investor.state = uint8(StateOfInvestor.Pending);
        }
    }

    /// @notice Approve a pending investor.
    /// @param repo Storage repo.
    /// @param acct Investor user number.
    /// @param verifier Approver user number.
    function approveInvestor(
        Repo storage repo,
        uint acct,
        uint verifier
    ) public investorExist(repo, acct) {

        Investor storage investor = repo.investors[acct];

        require(investor.state != uint8(StateOfInvestor.Approved),
            "OR,apprInv: wrong state");

        investor.verifier = uint40(verifier);
        investor.approveDate = uint48(block.timestamp);
        investor.state = uint8(StateOfInvestor.Approved);

        _increaseQtyOfInvestors(repo);
    }

    /// @notice Revoke an approved investor.
    /// @param repo Storage repo.
    /// @param acct Investor user number.
    /// @param verifier Revoker user number.
    function revokeInvestor(
        Repo storage repo,
        uint acct,
        uint verifier
    ) public {

        Investor storage investor = repo.investors[acct];

        require(investor.state == uint8(StateOfInvestor.Approved),
            "OR,revokeInvestor: wrong state");

        investor.verifier = uint40(verifier);
        investor.approveDate = uint48(block.timestamp);
        investor.state = uint8(StateOfInvestor.Revoked);

        _decreaseQtyOfInvestors(repo);
    }

    /// @notice Increment approved investor counter.
    /// @param repo Storage repo.
    function _increaseQtyOfInvestors(
        Repo storage repo
    ) private {
        repo.investors[0].verifier++;
    }

    /// @notice Decrement approved investor counter.
    /// @param repo Storage repo.
    function _decreaseQtyOfInvestors(
        Repo storage repo
    ) private {
        repo.investors[0].verifier--;
    }

    /// @notice Restore repo from snapshots.
    /// @param repo Storage repo.
    /// @param list Investor list to restore.
    /// @param qtyOfInvestors Approved investor count.
    function restoreRepo(
        Repo storage repo, Investor[] memory list, uint qtyOfInvestors
    ) public {            
        uint len = list.length;
        uint i = 0;
        while (i < len) {
            Investor memory investor = list[i];
            repo.investors[investor.userNo] = investor;
            repo.investorsList.push(investor.userNo);
            i++;
        }
        repo.investors[0].verifier = uint40(qtyOfInvestors);
    }

    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    /// @notice Check whether an investor exists.
    /// @param repo Storage repo.
    /// @param acct Investor user number.
    function isInvestor(
        Repo storage repo,
        uint acct
    ) public view returns(bool) {
        return repo.investors[acct].regDate > 0;
    }

    /// @notice Get investor record.
    /// @param repo Storage repo.
    /// @param acct Investor user number.
    function getInvestor(
        Repo storage repo,
        uint acct
    ) public view investorExist(repo, acct) returns(Investor memory) {
        return repo.investors[acct];
    }

    /// @notice Get approved investor count.
    /// @param repo Storage repo.
    function getQtyOfInvestors(
        Repo storage repo
    ) public view returns(uint) {
        return repo.investors[0].verifier;
    }

    /// @notice Get list of investor user numbers.
    /// @param repo Storage repo.
    function investorList(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.investorsList;
    }

    /// @notice Get full investor info list.
    /// @param repo Storage repo.
    function investorInfoList(
        Repo storage repo
    ) public view returns(Investor[] memory list) {
        uint[] memory seqList = repo.investorsList;
        uint len = seqList.length;

        list = new Investor[](len);

        while (len > 0) {
            list[len - 1] = repo.investors[seqList[len - 1]];
            len--;
        }

        return list;
    }

}
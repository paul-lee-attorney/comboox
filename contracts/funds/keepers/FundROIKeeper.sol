// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "../../comps/common/access/RoyaltyCharge.sol";

import "../../comps/keepers/IROIKeeper.sol";

contract FundROIKeeper is IROIKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    using BooksRepo for IBaseKeeper;

    //###############
    //##   Write   ##
    //###############

    // ==== Investor ====

    function regInvestor(
        address msgSender, address bKey, uint groupRep, bytes32 idHash
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 18000);

        require(msgSender != bKey, 
            "LOOK.regInvestor: same key");

        require(caller == _msgSender(bKey, 18000), 
            "LOOK.regInvestor: wrong backupKey");

        if (_isContract(msgSender)) {
            require(_rc.getHeadByBody(msgSender).typeOfDoc == 20,
                "LOOK.RegInvestor: COA applicant not GK");
        }

        if (_isContract(bKey)) {
            require(_rc.getHeadByBody(bKey).typeOfDoc == 20,
                "LOOK.RegInvestor: COA backupKey not GK");
        }

        _gk.getROI().regInvestor(caller, groupRep, idHash);
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    function approveInvestor(
        uint userNo,
        address msgSender,
        uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        IRegisterOfInvestors _roi = _gk.getROI();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfVerifier),
            "ROIK.apprInv: no rights");

        require(_gk.getROM().isClassMember(caller, 1),
            "ROIK.apprInv: not GP");

        require(lr.maxQtyOfInvestors == 0 ||
            _roi.getQtyOfInvestors() < lr.maxQtyOfInvestors,
            "ROIK.apprInv: no quota");

        _roi.approveInvestor(userNo, caller);
    }

    function revokeInvestor(
        uint userNo,
        address msgSender,
        uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfVerifier),
            "LOOK.revokeInv: wrong titl");

        require(_gk.getROM().isClassMember(caller, 1),
            "LOOK.apprInv: not GP");

        _gk.getROI().revokeInvestor(userNo, caller);
    }
}

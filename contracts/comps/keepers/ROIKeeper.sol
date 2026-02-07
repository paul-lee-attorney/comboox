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

import "../common/access/RoyaltyCharge.sol";

import "./IROIKeeper.sol";

contract ROIKeeper is IROIKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    using BooksRepo for IBaseKeeper;

    //###############
    //##   Write   ##
    //###############

    // ==== Pause LOO ====

    function _checkVerifierLicense(uint seqOfLR, uint caller) private {
        RulesParser.ListingRule memory lr = 
            gk.getSHA().getRule(seqOfLR).listingRuleParser();
        require(gk.getROD().hasTitle(caller, lr.titleOfVerifier),
            "ROIK.checkVerifierLicense: no rights");
    }

    function _checkEnforcerLicense(uint seqOfLR, uint caller) private {
        RulesParser.ListingRule memory lr = 
            gk.getSHA().getRule(seqOfLR).listingRuleParser();
        require(gk.getROD().hasTitle(caller, lr.para),
            "ROIK.checkEnforcerLicense: no rights");
    }

    function pause(uint seqOfLR, address msgSender) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);
        _checkEnforcerLicense(seqOfLR, caller);

        gk.getROI().pause(caller);
    }

    function unPause(uint seqOfLR, address msgSender) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);
        _checkEnforcerLicense(seqOfLR, caller);

        gk.getROI().unPause(caller);
    }

    // ==== Freeze Share ====

    function freezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address msgSender, bytes32 hashOrder
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);
        _checkEnforcerLicense(seqOfLR, caller);

        IRegisterOfShares _ros = gk.getROS();
        _ros.decreaseCleanPaid(seqOfShare, paid);
        uint shareholder = _ros.getShare(seqOfShare).head.shareholder;
        gk.getROI().freezeShare(shareholder, seqOfShare, paid, caller, hashOrder);
    }

    function unfreezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address msgSender, bytes32 hashOrder
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);
        _checkEnforcerLicense(seqOfLR, caller);

        IRegisterOfShares _ros = gk.getROS();
        _ros.increaseCleanPaid(seqOfShare, paid);
        uint shareholder = _ros.getShare(seqOfShare).head.shareholder;
        gk.getROI().unfreezeShare(shareholder, seqOfShare, paid, caller, hashOrder);
    }

    function forceTransfer(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address addrTo, address msgSender, bytes32 hashOrder
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);
        _checkEnforcerLicense(seqOfLR, caller);
        
        IRegisterOfInvestors _roi = gk.getROI();
        uint to = _msgSender(addrTo, 88000);
        require(_roi.isInvestor(to), 
            "ROIKeeper.forceTransfer: to is NOT a Verified Investor");

        IRegisterOfShares _ros = gk.getROS();
        SharesRepo.Share memory share = _ros.getShare(seqOfShare);
        _ros.increaseCleanPaid(seqOfShare, paid);

        _roi.forceTransfer(share.head.shareholder, seqOfShare, paid, caller, hashOrder);
        _ros.transferShare(seqOfShare, paid, paid, to, share.head.priceOfPaid, share.head.priceOfPar);   
    }
    // ==== Investor ====

    function regInvestor(
        address msgSender, address bKey, uint groupRep, bytes32 idHash
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 18000);

        require(msgSender != bKey, 
            "ROIK.regInvestor: same key");

        require(caller == _msgSender(bKey, 18000), 
            "ROIK.regInvestor: wrong backupKey");

        if (_isContract(msgSender)) {
            require(rc.getHeadByBody(msgSender).typeOfDoc == 20,
                "ROIK.RegInvestor: COA applicant not GK");
        }

        if (_isContract(bKey)) {
            require(rc.getHeadByBody(bKey).typeOfDoc == 20,
                "ROIK.RegInvestor: COA backupKey not GK");
        }

        gk.getROI().regInvestor(caller, groupRep, idHash);
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
        _checkVerifierLicense(seqOfLR, caller);

        IRegisterOfInvestors _roi = gk.getROI();

        RulesParser.ListingRule memory lr = 
            gk.getSHA().getRule(seqOfLR).listingRuleParser();

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
        _checkVerifierLicense(seqOfLR, caller);

        gk.getROI().revokeInvestor(userNo, caller);
    }
}

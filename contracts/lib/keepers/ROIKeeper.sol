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

import "../books/RulesParser.sol";
import "../InterfacesHub.sol";
import "../utils/RoyaltyCharge.sol";
import "../../openzeppelin/utils/Address.sol";

library ROIKeeper {
    using RulesParser for bytes32;
    using InterfacesHub for address;
    using RoyaltyCharge for address;
    using Address for address;

    // uint32(uint(keccak256("ROIKeeper")));
    uint public constant TYPE_OF_DOC = 0xd042852b;
    uint public constant VERSION = 1;

    // ######################
    // ##   Error & Event  ##
    // ######################

    error ROIK_WrongParty(bytes32 reason);
    
    error ROIK_WrongKey(bytes32 reason);

    error ROIK_NoQuota(bytes32 reason);

    // ==== Pause LOO ====

    function _checkVerifierLicense(address _gk, uint seqOfLR, uint caller) private view {
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();
        if(!_gk.getROD().hasTitle(caller, lr.titleOfVerifier)) {
            revert ROIK_WrongParty(bytes32("ROIK_NoRightOfVerify"));
        }
    }

    function _checkEnforcerLicense(address _gk, uint seqOfLR, uint caller) private view {
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();
        if(!_gk.getROD().hasTitle(caller, lr.para)) {
            revert ROIK_WrongParty(bytes32("ROIK_NoRightOfEnforce"));
        }
    }

    function pause(uint seqOfLR) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _checkEnforcerLicense(_gk, seqOfLR, caller);

        _gk.getROI().pause(caller);
    }

    function unPause(uint seqOfLR) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _checkEnforcerLicense(_gk, seqOfLR, caller);
        _gk.getROI().unPause(caller);
    }

    // ==== Freeze Share ====

    function freezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        bytes32 hashOrder
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        _checkEnforcerLicense(_gk, seqOfLR, caller);

        IRegisterOfShares _ros = _gk.getROS();
        _ros.decreaseCleanPaid(seqOfShare, paid);
        uint shareholder = _ros.getShare(seqOfShare).head.shareholder;
        _gk.getROI().freezeShare(shareholder, seqOfShare, paid, caller, hashOrder);
    }

    function unfreezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        bytes32 hashOrder
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        _checkEnforcerLicense(_gk, seqOfLR, caller);
    
        IRegisterOfShares _ros = _gk.getROS();
        _ros.increaseCleanPaid(seqOfShare, paid);
        uint shareholder = _ros.getShare(seqOfShare).head.shareholder;
        _gk.getROI().unfreezeShare(shareholder, seqOfShare, paid, caller, hashOrder);
    }

    function forceTransfer(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address addrTo, bytes32 hashOrder
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _checkEnforcerLicense(_gk, seqOfLR, caller);
        
        IRegisterOfInvestors _roi = _gk.getROI();
        uint to = addrTo.msgSender(TYPE_OF_DOC, VERSION, 88000);

        if(!_roi.isInvestor(to)) {
            revert ROIK_WrongParty(bytes32("ROIK_NotInvestor"));
        }

        IRegisterOfShares _ros = _gk.getROS();
        SharesRepo.Share memory share = _ros.getShare(seqOfShare);
        _ros.increaseCleanPaid(seqOfShare, paid);

        _roi.forceTransfer(share.head.shareholder, seqOfShare, paid, caller, hashOrder);
        _ros.transferShare(seqOfShare, paid, paid, to, share.head.priceOfPaid, share.head.priceOfPar);   
    }
    // ==== Investor ====

    function regInvestor(
        address bKey, uint groupRep, bytes32 idHash
    ) external {

        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        // address _rc = _gk.getRCByGK();

        if(msg.sender == bKey)
            revert ROIK_WrongKey(bytes32("ROIK_SameKey"));

        if(caller != bKey.msgSender(TYPE_OF_DOC, VERSION, 18000)) {
            revert ROIK_WrongKey(bytes32("ROIK_WrongBackupKey"));
        }

        if (msg.sender.isContract()) {
            // uint32(uint(keccak256("GeneralKeeper"))
            if(_gk.getRCByGK().getHeadByBody(msg.sender).typeOfDoc != 0x25586efd)  
                revert ROIK_WrongParty(bytes32("ROIK_COAApplicantNotGK"));
        }

        if (bKey.isContract()) {
            if(_gk.getRCByGK().getHeadByBody(bKey).typeOfDoc != 0x25586efd)
                revert ROIK_WrongParty(bytes32("ROIK_COABackupKeyNotGK"));
        }

        _gk.getROI().regInvestor(caller, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        uint seqOfLR
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _checkVerifierLicense(_gk, seqOfLR, caller);

        IRegisterOfInvestors _roi = _gk.getROI();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        if(lr.maxQtyOfInvestors != 0 &&
            _roi.getQtyOfInvestors() >= lr.maxQtyOfInvestors
        ) {
            revert ROIK_NoQuota(bytes32("ROIK_NoQuotaOfInvestors"));
        }

        _roi.approveInvestor(userNo, caller);
    }

    function revokeInvestor(
        uint userNo,
        uint seqOfLR
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _checkVerifierLicense(_gk, seqOfLR, caller);

        _gk.getROI().revokeInvestor(userNo, caller);
    }
}

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
import "../../openzeppelin/utils/Address.sol";
import "../InterfacesHub.sol";
import "../utils/RoyaltyCharge.sol";

library FundROIKeeper {
    using RulesParser for bytes32;
    using Address for address;
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // uint32(uint(keccak256("FundROIKeeper")))
    uint constant public TYPE_OF_DOC = 0x918b186a;
    uint constant public VERSION = 1;

    //##########################
    //##   Error & Modifier   ##
    //##########################

    error FundROIK_WrongParty(bytes32 reason);

    error FundROIK_Overflow(bytes32 reason);


    // ==== Pause LOO ====

    function _checkVerifierLicense(address _gk, uint seqOfLR, uint caller) private view{
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();
        if(!_gk.getROD().hasTitle(caller, lr.titleOfVerifier)) {
            revert FundROIK_WrongParty("FundROIK_NotVerifier");
        }
    }

    function _checkEnforcerLicense(address _gk, uint seqOfLR, uint caller) private view{
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();
        if(!_gk.getROD().hasTitle(caller, lr.para)) {
            revert FundROIK_WrongParty("FundROIK_NotEnforcer");
        }
    }

    function pause(uint seqOfLR) external  {
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
        uint seqOfLR, uint seqOfShare, uint paid, bytes32 hashOrder
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
        uint seqOfLR, uint seqOfShare, uint paid, bytes32 hashOrder
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
        if (!_roi.isInvestor(to)) {
            revert FundROIK_WrongParty("FundROIK_NotInvestor");
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

        if(msg.sender == bKey) {
            revert FundROIK_WrongParty("FundROIK_SameKey");
        }

        if(caller != bKey.msgSender(TYPE_OF_DOC, VERSION, 18000)) {
            revert FundROIK_WrongParty("FundROIK_WrongBackupKey");
        }

        if (msg.sender.isContract()) {
            // uint32(uint(keccak256("GeneralKeeper")))
            if(_gk.getRCByGK().getHeadByBody(msg.sender).typeOfDoc != 0x25586efd) { 
                revert FundROIK_WrongParty("FundROIK_NotGK");
            }
        }

        if (bKey.isContract()) {
            if (_gk.getRCByGK().getHeadByBody(bKey).typeOfDoc != 0x25586efd) {
                revert FundROIK_WrongParty("FundROIK_BKeyNotGK");
            }
        }

        _gk.getROI().regInvestor(caller, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        uint seqOfLR
    ) external  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _checkVerifierLicense(_gk, seqOfLR, caller);

        IRegisterOfInvestors _roi = _gk.getROI();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        if(!_gk.getROM().isClassMember(caller, 1)) {
            revert FundROIK_WrongParty("FundROIK_NotGP");
        }

        if(lr.maxQtyOfInvestors != 0 && _roi.getQtyOfInvestors() >= lr.maxQtyOfInvestors) {
            revert FundROIK_Overflow("FundROIK_NoQuota");
        }

        _roi.approveInvestor(userNo, caller);
    }

    function revokeInvestor(
        uint userNo,
        uint seqOfLR
    ) external  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _checkVerifierLicense(_gk, seqOfLR, caller);

        if(!_gk.getROM().isClassMember(caller, 1)) {
            revert FundROIK_WrongParty("FundROIK_NotGP");
        }

        _gk.getROI().revokeInvestor(userNo, caller);
    }
}

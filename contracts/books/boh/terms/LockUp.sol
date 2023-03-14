// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa/IInvestmentAgreement.sol";
// import "../../boa/IBookOfIA.sol";
// import "../../bog/IBookOfGM.sol";

import "../../../common/access/AccessControl.sol";
import "../../../common/lib/ArrayUtils.sol";
// import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumerableSet.sol";

import "../../../common/ruting/BOASetting.sol";
import "../../../common/ruting/BOGSetting.sol";

import "./ILockUp.sol";

contract LockUp is ILockUp, BOASetting, BOGSetting, AccessControl {
    using ArrayUtils for uint256[];
    using ArrayUtils for uint40[];
    // using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;


    // 基准日条件未成就时，按“2105-09-19”设定到期日
    uint48 constant _REMOTE_FUTURE = 4282732800;

    // lockers[0].keyHolders: ssnList;

    // seqOfShare => Locker
    mapping(uint256 => Locker) private _lockers;

    // ################
    // ##   写接口   ##
    // ################

    function setLocker(uint256 seqOfShare, uint48 dueDate) external onlyAttorney {
        _lockers[seqOfShare].dueDate = dueDate == 0 ? _REMOTE_FUTURE : dueDate;
        _lockers[0].keyHolders.add(seqOfShare);
    }

    function delLocker(uint256 seqOfShare) external onlyAttorney {
        if (_lockers[0].keyHolders.remove(seqOfShare)) {
            delete _lockers[seqOfShare];
        }
    }

    function addKeyholder(uint256 seqOfShare, uint256 keyholder) external onlyAttorney {
        require(seqOfShare != 0, "LU.addKeyholder: zero seqOfShare");
        _lockers[seqOfShare].keyHolders.add(keyholder);
    }

    function removeKeyholder(uint256 seqOfShare, uint256 keyholder)
        external
        onlyAttorney
    {
        require(seqOfShare != 0, "LU.removeKeyholder: zero seqOfShare");
        _lockers[seqOfShare].keyHolders.remove(keyholder);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isLocked(uint256 seqOfShare) public view returns (bool) {
        return _lockers[0].keyHolders.contains(seqOfShare);
    }

    function getLocker(uint256 seqOfShare)
        external
        view
        returns (uint48 dueDate, uint256[] memory keyHolders)
    {
        dueDate = _lockers[seqOfShare].dueDate;
        keyHolders = _lockers[seqOfShare].keyHolders.values();
    }

    function lockedShares() external view returns (uint256[] memory) {
        return _lockers[0].keyHolders.values();
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, uint256 seqOfDeal) external view returns (bool) {
 
        IInvestmentAgreement.Head memory head = IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);
 
        // uint48 closingDate = IInvestmentAgreement(ia).getDeal(
        //     sn.seqOfDeal()
        // ).closingDate;

        // uint8 typeOfDeal = sn.typeOfDeal();
        // uint256 seqOfShare = sn.ssnOfDeal();

        if (
            head.typeOfDeal > 1 &&
            isLocked(head.seqOfShare) &&
            _lockers[head.seqOfShare].dueDate >= head.closingDate
        ) return true;

        return false;
    }

    function _isExempted(uint256 seqOfShare, uint256[] memory agreedParties)
        private
        view
        returns (bool)
    {
        if (!isLocked(seqOfShare)) return true;

        Locker storage locker = _lockers[seqOfShare];

        uint256[] memory holders = locker.keyHolders.values();
        uint256 len = holders.length;

        if (len > agreedParties.length) {
            return false;
        } else {
            return holders.fullyCoveredBy(agreedParties);
        }
    }

    function isExempted(address ia, uint256 seqOfDeal) external view returns (bool) {
        
        uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();
        uint256 motionId = (typeOfIA << 160) + uint256(uint160(ia));
               
        uint40[] memory consentParties = _getBOG().
            getCaseOfAttitude(motionId,1).voters;

        uint256[] memory signers = ISigPage(ia).partiesOfDoc();

        uint256[] memory agreedParties = consentParties.mixCombine(signers);

        // uint256 seqOfShare = sn.ssnOfDeal();
        IInvestmentAgreement.Head memory head = IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);

        return _isExempted(head.seqOfShare, agreedParties);
    }


}

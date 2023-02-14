// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa//IInvestmentAgreement.sol";

import "../../../common/ruting/BOMSetting.sol";
import "../../../common/ruting/RODSetting.sol";

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumerableSet.sol";

import "../../../common/components/ISigPage.sol";

import "./ILockUp.sol";
import "./ITerm.sol";

contract LockUp is ILockUp, BOMSetting, RODSetting {
    using ArrayUtils for uint40[];
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    // 股票锁定柜
    struct Locker {
        uint48 dueDate;
        EnumerableSet.UintSet keyHolders;
    }

    // 基准日条件未成就时，按“2105-09-19”设定到期日
    uint48 constant REMOTE_FUTURE = 4282732800;

    // lockers[0].keyHolders: ssnList;

    // ssn => Locker
    mapping(uint256 => Locker) private _lockers;

    // ################
    // ##   写接口   ##
    // ################

    function setLocker(uint32 ssn, uint48 dueDate) external onlyAttorney {
        _lockers[ssn].dueDate = dueDate == 0 ? REMOTE_FUTURE : dueDate;
        _lockers[0].keyHolders.add(ssn);
    }

    function delLocker(uint32 ssn) external onlyAttorney {
        if (_lockers[0].keyHolders.remove(ssn)) {
            delete _lockers[ssn];
        }
    }

    function addKeyholder(uint32 ssn, uint40 keyholder) external onlyAttorney {
        require(ssn != 0, "LU.addKeyholder: zero ssn");
        _lockers[ssn].keyHolders.add(keyholder);
    }

    function removeKeyholder(uint32 ssn, uint40 keyholder)
        external
        onlyAttorney
    {
        require(ssn != 0, "LU.removeKeyholder: zero ssn");
        _lockers[ssn].keyHolders.remove(keyholder);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isLocked(uint32 ssn) public view returns (bool) {
        return _lockers[0].keyHolders.contains(ssn);
    }

    function getLocker(uint32 ssn)
        external
        view
        returns (uint48 dueDate, uint40[] memory keyHolders)
    {
        dueDate = _lockers[ssn].dueDate;
        keyHolders = _lockers[ssn].keyHolders.valuesToUint40();
    }

    function lockedShares() external view returns (uint32[] memory) {
        return _lockers[0].keyHolders.valuesToUint32();
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) external view returns (bool) {
        uint48 closingDate = IInvestmentAgreement(ia).closingDateOfDeal(
            sn.seqOfDeal()
        );

        uint8 typeOfDeal = sn.typeOfDeal();
        uint32 ssn = sn.ssnOfDeal();

        if (
            typeOfDeal > 1 &&
            isLocked(ssn) &&
            _lockers[ssn].dueDate >= closingDate
        ) return true;

        return false;
    }

    function _isExempted(uint32 ssn, uint40[] memory agreedParties)
        private
        view
        returns (bool)
    {
        if (!isLocked(ssn)) return true;

        Locker storage locker = _lockers[ssn];

        uint40[] memory holders = locker.keyHolders.valuesToUint40();
        uint256 len = holders.length;

        if (len > agreedParties.length) {
            return false;
        } else {
            return holders.fullyCoveredBy(agreedParties);
        }
    }

    function isExempted(address ia, bytes32 sn) external view returns (bool) {
        (uint40[] memory consentParties, ) = _bom.getCaseOf(
            uint256(uint160(ia)),
            1
        );

        uint40[] memory signers = _rod.partiesOfDoc(ia);

        uint40[] memory agreedParties = consentParties.combine(signers);

        uint32 ssn = sn.ssnOfDeal();

        return _isExempted(ssn, agreedParties);
    }
}

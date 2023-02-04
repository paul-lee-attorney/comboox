// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/OptionsRepo.sol";
import "../../../common/access/AccessControl.sol";

import "./IOptions.sol";

contract Options is IOptions, AccessControl {
    using OptionsRepo for OptionsRepo.Repo;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    OptionsRepo.Repo private _options;

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        bytes32 sn,
        uint40 rightholder,
        uint40[] memory obligors,
        uint64 paid,
        uint64 par
    ) external onlyAttorney returns (bytes32 _sn) {
        _sn = _options.createOption(sn, rightholder, obligors, paid, par);
    }

    function delOption(bytes32 sn) external onlyAttorney {
        _options.removeOption(sn);
    }

    // ################
    // ##  查询接口   ##
    // ################

    function counterOfOpts() external view returns (uint32) {
        return uint32(_options.options[0].rightholder);
    }

    function isOption(bytes32 sn) external view returns (bool) {
        return _options.snList.contains(sn);
    }

    function qtyOfOpts() external view returns (uint256) {
        return _options.snList.length();
    }

    function isObligor(bytes32 sn, uint40 acct) external view returns (bool) {
        return _options.options[sn].obligors.contains(acct);
    }

    function getOption(bytes32 sn)
        external
        view
        returns (
            uint40 rightholder,
            uint64 paid,
            uint64 par
        )
    {
        rightholder = _options.options[sn].rightholder;
        paid = _options.options[sn].paid[0];
        par = _options.options[sn].par[0];
    }

    function obligorsOfOption(bytes32 sn)
        external
        view
        returns (uint40[] memory)
    {
        return _options.options[sn].obligors.valuesToUint40();
    }

    function optsList() external view returns (bytes32[] memory) {
        return _options.snList.values();
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/access/AccessControl.sol";

import "./IOptions.sol";

contract Options is IOptions, AccessControl {
    using OptionsRepo for OptionsRepo.Repo;
    using OptionsRepo for OptionsRepo.Option;
    using OptionsRepo for OptionsRepo.Head;
    using OptionsRepo for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    OptionsRepo.Repo private _repo;

    // ################
    // ##   写接口    ##
    // ################

    function createOption(
        uint256 snOfOpt,
        uint256 snOfCond,
        uint40 rightholder,
        uint64 paid,
        uint64 par
    ) external onlyAttorney returns (OptionsRepo.Head memory head) {
        head = _repo.createOption(snOfOpt, snOfCond, rightholder, paid, par);
    }

    function delOption(uint256 seqOfOpt) external onlyAttorney returns(bool flag){
        OptionsRepo.Head memory head = _repo.options[seqOfOpt].head;

        if (_repo.snList.remove(head.codifyHead())) {
            delete _repo.options[seqOfOpt];
            delete _repo.records[seqOfOpt];
            flag = true;
        }
    }

    function addObligorIntoOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external onlyAttorney returns (bool flag) {
        if (isOption(seqOfOpt)) 
            flag = _repo.records[seqOfOpt].obligors.add(obligor);
    }

    function removeObligorFromOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external onlyAttorney returns (bool flag) {
        if (isOption(seqOfOpt)) 
            flag = _repo.records[seqOfOpt].obligors.remove(obligor);
    }

    // ################
    // ##  查询接口   ##
    // ################

    // ==== Option ====

    function counterOfOptions() external view returns (uint32) {
        return _repo.options[0].head.seqOfOpt;
    }

    function isOption(uint256 seqOfOpt) public view returns (bool) {
        return _repo.options[seqOfOpt].head.issueDate > 0;
    }

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory option)   
    {
        require (isOption(seqOfOpt), "OP.GO: opt not exist");
        option = _repo.options[seqOfOpt];
    }

    function getAllOptions() external view returns (OptionsRepo.Option[] memory) 
    {
        return _repo.getAllOptions();
    }

    // ==== Obligor ====

    function isObligor(uint256 seqOfOpt, uint256 acct) external 
        view returns (bool) 
    {
        return _repo.records[seqOfOpt].obligors.contains(acct);
    }

    function getObligorsOfOption(uint256 seqOfOpt) external view
        returns (uint256[] memory)
    {
        return _repo.records[seqOfOpt].obligors.values();
    }

    // ==== snOfOpt ====
    function getSNList() external view returns(uint256[] memory) {
        return _repo.snList.values();
    }

}

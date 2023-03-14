// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/OptionsRepo.sol";
import "../../../common/access/AccessControl.sol";

import "./IOptions.sol";

contract Options is IOptions, AccessControl {
    using OptionsRepo for OptionsRepo.Repo;
    using OptionsRepo for OptionsRepo.Option;
    using EnumerableSet for EnumerableSet.UintSet;

    OptionsRepo.Repo private _repo;

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        bytes32 sn,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    ) external onlyAttorney returns (uint32 seqOfOpt) {
        seqOfOpt = _repo.createOption(sn, rightholder, obligor, paid, par);
    }

    function delOption(uint256 seqOfOpt) external onlyAttorney {
        delete _repo.options[seqOfOpt];
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

    function optRegistered(uint256 seqOfOpt)
        external 
    {
        require (msg.sender == _gk.getBook(uint8(TitleOfBooks.BookOfOptions)), 
            "OP.USOO: msgSender is not BOO");

        require (isOption(seqOfOpt), "OP.USOO: opt not exist");

        _repo.options[seqOfOpt].head.state = uint8(OptionsRepo.OptStates.Issued);
    }

    // ################
    // ##  查询接口   ##
    // ################

    function counterOfOpts() external view returns (uint32) {
        return _repo.counterOfOptions();
    }

    function isOption(uint256 seqOfOpt) public view returns (bool) {
        return _repo.options[seqOfOpt].head.state > 0;
    }

    function isObligor(uint256 seqOfOpt, uint256 acct) external view returns (bool) {
        return _repo.records[seqOfOpt].obligors.contains(acct);
    }

    function getOption(uint256 seqOfOpt)
        external
        view
        returns (
        OptionsRepo.Head memory head, 
        OptionsRepo.Body memory body)   
    {
        require (isOption(seqOfOpt), "OP.GO: opt not exist");

        head = _repo.options[seqOfOpt].head;
        body = _repo.options[seqOfOpt].body;
    }

    function obligorsOfOption(uint256 seqOfOpt)
        external
        view
        returns (uint256[] memory)
    {
        require (isOption(seqOfOpt), "OP.GO: opt not exist");
    
        return _repo.records[seqOfOpt].obligors.values();
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfOptions.sol";

import "../boh/terms/IOptions.sol";

import "../../common/access/AccessControl.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROSSetting.sol";

contract BookOfOptions is IBookOfOptions, BOSSetting, ROSSetting, AccessControl {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.UintSet;
    using OptionsRepo for OptionsRepo.Repo;
    using OptionsRepo for OptionsRepo.Option;
    using OptionsRepo for OptionsRepo.Record;

    OptionsRepo.Repo private _repo;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier optionExist(uint256 seqOfOpt) {
        require(isOption(seqOfOpt), "BOO.mf.OE: Opt not exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        uint256 sn,
        uint256 snOfCond,
        uint40 rightholder,
        uint64 paid,
        uint64 par
    ) external onlyKeeper returns(OptionsRepo.Head memory head) {
        head = _repo.createOption(sn, snOfCond, rightholder, paid, par);
        emit CreateOpt(head.seqOfOpt, OptionsRepo.codifyHead(head));
    }

    function issueOption(OptionsRepo.Option memory opt) external onlyKeeper
        returns(OptionsRepo.Head memory head) 
    {
        head = _repo.issueOption(opt);
        emit CreateOpt(head.seqOfOpt, OptionsRepo.codifyHead(head));
    }

    function regOptionTerms(address opts) external onlyKeeper {
        uint32 len = IOptions(opts).counterOfOptions();

        while (len > 0) {
            OptionsRepo.Option memory opt = IOptions(opts).getOption(len); 

            opt.head = _repo.issueOption(opt);

            emit CreateOpt(opt.head.seqOfOpt, OptionsRepo.codifyHead(opt.head));

            uint256[] memory obligors = IOptions(opts).getObligorsOfOption(len);
            _repo.records[opt.head.seqOfOpt].addObligorsIntoOption(obligors);

            len--;
        }
    }

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external onlyDirectKeeper {
        if (_repo.records[seqOfOpt].obligors.add(obligor))
            emit AddObligorIntoOpt(seqOfOpt, obligor);
    }

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external onlyDirectKeeper {
        if (_repo.records[seqOfOpt].obligors.remove(obligor))
            emit RemoveObligorFromOpt(seqOfOpt, obligor);
    }

    // ==== Exec Option ====

    function updateOracle(
        uint256 seqOfOpt,
        uint64 d1,
        uint64 d2,
        uint64 d3
    ) external onlyDirectKeeper {
        emit UpdateOracle(seqOfOpt, d1, d2, d3);
        _repo.records[seqOfOpt].oracles.push(d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external onlyKeeper {
        emit ExecOpt(seqOfOpt);
        _repo.execOption(seqOfOpt);
    }

    function createSwapOrder(
        uint256 seqOfOpt,
        uint32 seqOfConsider,
        uint64 paidOfConsider,
        uint32 seqOfTarget
    ) external onlyKeeper view returns (SwapsRepo.Swap memory swap) {
        swap = _repo.createSwapOrder(seqOfOpt, seqOfConsider, paidOfConsider, seqOfTarget, _bos);
    }

    function regSwapOrder(
        uint256 seqOfOpt,
        SwapsRepo.Swap memory swap
    ) external onlyKeeper {
        OptionsRepo.Brief memory brf = _repo.regSwapOrder(seqOfOpt, swap);
        emit RegSwapOrder(seqOfOpt, OptionsRepo.codifyBrief(brf));
    }

    function updateStateOfBrief(
        uint256 seqOfOpt,
        uint256 seqOfBrf,
        uint8 state
    ) external onlyKeeper {
        _repo.records[seqOfOpt].briefs[seqOfBrf].state = state;

        emit UpdateStateOfBrief(seqOfOpt, seqOfBrf, state);
    }

    // ################
    // ##  查询接口   ##
    // ################

    // ==== Option ====

    function counterOfOptions() external view returns (uint32) {
        return _repo.counterOfOptions();
    }

    function isOption(uint256 seqOfOpt) public view returns (bool) {
        return _repo.options[seqOfOpt].head.issueDate > 0;
    }

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory opt)
    {
        opt = _repo.options[seqOfOpt];
    }

    function getAllOptions() external view returns (OptionsRepo.Option[] memory) {
        return _repo.getAllOptions();
    }

    function isRightholder(uint256 seqOfOpt, uint256 acct) external view returns (bool){
        return _repo.options[seqOfOpt].body.rightholder == acct;
    }

    function isObligor(uint256 seqOfOpt, uint256 acct) external view
        optionExist(seqOfOpt) returns (bool) 
    { 
        return _repo.records[seqOfOpt].obligors.contains(acct);
    }

    function getObligorsOfOption(uint256 seqOfOpt)
        external view returns (uint256[] memory)
    {
        return _repo.records[seqOfOpt].obligors.values();
    }

    // ==== Brief ====
    function counterOfBriefs(uint256 seqOfOpt)
        external view returns (uint256) 
    {
        return _repo.records[seqOfOpt].briefs[0].seqOfBrf;
    }

    function getBrief(uint256 seqOfOpt, uint256 seqOfBrf)
        external view returns (OptionsRepo.Brief memory brf)
    {
        brf = _repo.records[seqOfOpt].briefs[seqOfBrf];
    }

    function getAllBriefsOfOption(uint256 seqOfOpt)
        external
        view
        returns (OptionsRepo.Brief[] memory)
    {
        return _repo.getAllBriefsOfOption(seqOfOpt);
    }

    // ==== Oracles ====

    function getOracleAtDate(uint256 seqOfOpt, uint48 date)
        external
        view
        optionExist(seqOfOpt)
        returns (Checkpoints.Checkpoint memory)
    {
        return _repo.records[seqOfOpt].oracles.getAtDate(date);
    }

    function getALLOraclesOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (Checkpoints.Checkpoint[] memory) 
    {
        return _repo.records[seqOfOpt].oracles.pointsOfHistory();
    }

    // ==== 

}

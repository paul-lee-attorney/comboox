// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfOptions.sol";

import "../../common/access/AccessControl.sol";

contract RegisterOfOptions is IRegisterOfOptions, AccessControl {
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
        require(isOption(seqOfOpt), "ROO.mf.OE: Opt not exist");
        _;
    }

    // ################
    // ## Write I/O ##
    // ################

    function createOption(
        bytes32 sn,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) external onlyKeeper returns(OptionsRepo.Head memory head) {
        head = _repo.createOption(sn, snOfCond, rightholder, paid, par);
        emit CreateOpt(head.seqOfOpt, OptionsRepo.codifyHead(head));
    }

    function issueOption(OptionsRepo.Option memory opt) external onlyKeeper 
    {
        uint issueDate = _repo.issueOption(opt);

        emit IssueOpt(opt.head.seqOfOpt, issueDate);
    }

    function regOptionTerms(address opts) external onlyKeeper {

        OptionsRepo.Option[] memory optsList = IOptions(opts).getAllOptions();

        uint len = optsList.length;

        while (len > 0) {
            OptionsRepo.Option memory opt = optsList[len - 1]; 

            uint256[] memory obligors = 
                IOptions(opts).getObligorsOfOption(opt.head.seqOfOpt);

            opt.head = _repo.regOption(opt);
            _repo.issueOption(opt);

            emit CreateOpt(opt.head.seqOfOpt, OptionsRepo.codifyHead(opt.head));
            _repo.records[opt.head.seqOfOpt].addObligorsIntoOption(obligors);

            len--;
        }
    }

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external onlyDK {
        if (_repo.records[seqOfOpt].obligors.add(obligor))
            emit AddObligorIntoOpt(seqOfOpt, obligor);
    }

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external onlyDK {
        if (_repo.records[seqOfOpt].obligors.remove(obligor))
            emit RemoveObligorFromOpt(seqOfOpt, obligor);
    }

    // ==== Exec Option ====

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK {
        emit UpdateOracle(seqOfOpt, d1, d2, d3);
        _repo.records[seqOfOpt].oracles.push(d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external onlyKeeper {
        emit ExecOpt(seqOfOpt);
        _repo.execOption(seqOfOpt);
    }

    function createSwapOrder(
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget
    ) external onlyKeeper view returns (SwapsRepo.Swap memory swap) {
        swap = _repo.createSwapOrder(seqOfOpt, seqOfConsider, paidOfConsider, seqOfTarget, _getGK());
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
        uint state
    ) external onlyKeeper {
        _repo.records[seqOfOpt].briefs[seqOfBrf].state = uint8(state);

        emit UpdateStateOfBrief(seqOfOpt, seqOfBrf, state);
    }

    // ################
    // ##  查询接口   ##
    // ################

    // ==== Option ====

    function counterOfOptions() external view returns (uint32) {
        return _repo.counterOfOptions();
    }

    function qtyOfOptions() external view returns (uint) {
        return _repo.qtyOfOptions();
    }

    function isOption(uint256 seqOfOpt) public view returns (bool) {
        return _repo.isOption(seqOfOpt);
    }

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory opt)
    {
        opt = _repo.getOption(seqOfOpt);
    }

    function getAllOptions() external view returns (OptionsRepo.Option[] memory) {
        return _repo.getAllOptions();
    }

    function isRightholder(uint256 seqOfOpt, uint256 acct) external view returns (bool){
        return _repo.isRightholder(seqOfOpt, acct);
    }

    function isObligor(uint256 seqOfOpt, uint256 acct) external view
        returns (bool) 
    { 
        return _repo.isObligor(seqOfOpt, acct);
    }

    function getObligorsOfOption(uint256 seqOfOpt)
        external view returns (uint256[] memory)
    {
        return _repo.getObligorsOfOption(seqOfOpt);
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

    function getOracleAtDate(uint256 seqOfOpt, uint date)
        external
        view
        optionExist(seqOfOpt)
        returns (Checkpoints.Checkpoint memory)
    {
        return _repo.records[seqOfOpt].oracles.getAtDate(date);
    }

    function getLatestOracle(uint256 seqOfOpt) external 
        view optionExist(seqOfOpt) returns(Checkpoints.Checkpoint memory)
    {
        return _repo.records[seqOfOpt].oracles.latest();
    }

    function getAllOraclesOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (Checkpoints.Checkpoint[] memory) 
    {
        return _repo.records[seqOfOpt].oracles.pointsOfHistory();
    }

}
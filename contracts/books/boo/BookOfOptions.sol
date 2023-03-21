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

contract BookOfOptions is IBookOfOptions, AccessControl {
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
        require(isOption(seqOfOpt), 
            "BOO.mf.OE: Opt not exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        uint256 sn,
        uint256 snOfCond,
        uint40 rightholder,
        uint40 obligor,
        uint64 paid,
        uint64 par
    ) external onlyKeeper returns (uint32 seqOfOpt) {
        seqOfOpt = _repo.createOption(sn, snOfCond, rightholder, obligor, paid, par);
        emit CreateOpt(seqOfOpt, rightholder, obligor, paid, par);
    }

    function issueOption(OptionsRepo.Option memory opt) 
        external onlyKeeper returns (uint32 seqOfOpt) 
    {
        seqOfOpt = _repo.issueOption(opt);
        emit CreateOpt(seqOfOpt, opt.body.rightholder, opt.body.obligor, opt.body.paid, opt.body.par);
    }

    function registerOption(address opts)
        external
        onlyKeeper
    {
        uint32 len = IOptions(opts).counterOfOpts();

        while (len > 0) {

            OptionsRepo.Option memory opt = IOptions(opts).getOption(len-1); 

            len--;

            if (opt.head.state > 0) continue;
            else {
                uint32 seqOfOpt = _repo.issueOption(opt);

                emit RegisterOpt(seqOfOpt, opt.body.rightholder, opt.body.obligor, opt.body.paid, opt.body.par);

                uint256[] memory obligors = IOptions(opts).obligorsOfOption(len);
                _repo.records[seqOfOpt].addObligorsIntoOption(obligors);
            }
        }
    }

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external onlyDirectKeeper {
        if (_repo.records[seqOfOpt].obligors.add(obligor))
            emit AddObligorIntoOpt(seqOfOpt, obligor);
    }

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor)
        external
        onlyDirectKeeper
    {
        if (_repo.records[seqOfOpt].obligors.remove(obligor))
            emit RemoveObligorFromOpt(seqOfOpt, obligor);
    }

    function updateOracle(
        uint256 seqOfOpt,
        uint64 d1,
        uint64 d2,
        uint64 d3
    ) external onlyDirectKeeper {
        _repo.records[seqOfOpt].oracles.push(d1, d2, d3);
        emit UpdateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external onlyKeeper {
        emit ExecOpt(seqOfOpt);
        _repo.execOption(seqOfOpt);
    }

    function addOrder(
        uint256 seqOfOpt,
        OptionsRepo.Order memory order 
    ) external onlyKeeper {
        if (_repo.addOrder(seqOfOpt, order)) {
            emit AddOrder(seqOfOpt, order.seqOfShare, order.paid, order.par);
        }
    }

    function requestPledge(
        uint256 seqOfOpt,
        uint256 seqOfOdr,
        PledgesRepo.Pledge memory pledge
    ) external onlyDirectKeeper {
        if (_repo.requestPledge(seqOfOpt, seqOfOdr, pledge))
            emit AddPledge(seqOfOpt, pledge.head.seqOfShare, pledge.body.paid, pledge.body.par);
    }

    function releasePledge(
        OptionsRepo.Order memory order,
        PledgesRepo.Head memory head
    ) external onlyDirectKeeper {

        PledgesRepo.Pledge storage pld = _repo.records[order.seqOfOpt].pledges[order.seqOfOdr][head.seqOfPldOnOdr];

        pld.head.state = uint8(PledgesRepo.StateOfPld.Released);

        OptionsRepo.Order storage order = _repo.records[order.seqOfOpt].orders[order.seqOfOdr];

        OptionsRepo.Option storage opt = _repo.options[order.seqOfOpt];

        uint64 paid = pld.body.paid * 100 / opt.head.rate;
        uint64 par = pld.body.par * 100 / opt.head.rate;

    }

    function lockOption(uint256 seqOfOpt, bytes32 hashLock) external onlyDirectKeeper {
        _repo.options[seqOfOpt].lockOption(hashLock);
        emit LockOpt(seqOfOpt, hashLock);
    }

    function closeOption(uint256 seqOfOpt, string memory hashKey) external onlyDirectKeeper {
        _repo.options[seqOfOpt].closeOption(hashKey);
        emit CloseOpt(seqOfOpt, hashKey);
    }

    function revokeOption(uint256 seqOfOpt, string memory hashKey) external onlyDirectKeeper {
        _repo.options[seqOfOpt].revokeOption(hashKey);
        emit RevokeOpt(seqOfOpt);
    }

    // ################
    // ##  查询接口   ##
    // ################

    function counterOfOptions() external view returns (uint32) {
        return _repo.counterOfOptions();
    }

    function isOption(uint256 seqOfOpt) public view returns (bool) {
        return _repo.options[seqOfOpt].head.issueDate > 0;
    }

    function getOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (OptionsRepo.Option memory opt)
    {
        opt = _repo.options[seqOfOpt];
    }

    function optsList() external view returns (OptionsRepo.Option[] memory) {
        return _repo.optionsOfRepo();
    }

    function isObligor(uint256 seqOfOpt, uint256 acct)
        external
        view
        optionExist(seqOfOpt)
        returns (bool)
    {
        return _repo.records[seqOfOpt].obligors.contains(acct);
    }

    function obligorsOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (uint256[] memory)
    {
        return _repo.records[seqOfOpt].obligors.values();
    }

    function stateOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (uint8)
    {
        return _repo.options[seqOfOpt].head.state;
    }

    // ==== Order ====

    function getOrder(uint256 seqOfOpt, uint256 seqOfOdr)
        external view
        optionExist(seqOfOpt)
        returns (OptionsRepo.Order memory)
    {
        return _repo.records[seqOfOpt].orders[seqOfOdr];
    }

    function ordersOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (OptionsRepo.Order[] memory)
    {
        return _repo.records[seqOfOpt].ordersOfOption();
    }

    function balanceOfOrder(uint256 seqOfOpt) public view 
        optionExist(seqOfOpt) returns (uint64 paid, uint64 par)
    {
        paid = _repo.options[seqOfOpt].body.paid - 
            _repo.records[seqOfOpt].orders[0].paid;
        par = _repo.options[seqOfOpt].body.par - 
            _repo.records[seqOfOpt].orders[0].par;
    }

    // ==== Pledge ====

    function getPledge(uint256 seqOfOpt, uint256 seqOfOdr, uint256 seqOfPldOnOdr)
        external view 
        optionExist(seqOfOpt)
        returns (PledgesRepo.Pledge memory)
    {
        return _repo.records[seqOfOpt].pledges[seqOfOdr][seqOfPldOnOdr];
    } 

    function pledgesOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (PledgesRepo.Pledge[] memory)
    {
        return _repo.records[seqOfOpt].pledgesOfOption();
    }

    function balanceOfPledge(uint256 seqOfOpt) public view 
        optionExist(seqOfOpt) returns (uint64 paid, uint64 par)
    {
        paid = _repo.records[seqOfOpt].orders[0].paid -
            _repo.records[seqOfOpt].pledges[0].body.paid;
        par = _repo.records[seqOfOpt].orders[0].par -
            _repo.records[seqOfOpt].pledges[0].body.par;
    }

    function oracleAtDate(uint256 seqOfOpt, uint48 date)
        external
        view
        optionExist(seqOfOpt)
        returns (Checkpoints.Checkpoint memory)
    {
        return _repo.records[seqOfOpt].oracles.getAtDate(date);
    }

    function oraclesOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (Checkpoints.Checkpoint[] memory) 
    {
        return _repo.records[seqOfOpt].oracles.pointsOfHistory();
    }
}

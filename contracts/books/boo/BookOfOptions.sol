// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfOptions.sol";

import "../boh/terms/IOptions.sol";
import "../bos/IBookOfShares.sol";

import "../../common/access/AccessControl.sol";

import "../../common/lib/Checkpoints.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/RulesParser.sol";
// import "../../common/lib/SNParser.sol";
import "../../common/lib/OptionsRepo.sol";
import "../../common/lib/PledgesRepo.sol";

import "../../common/ruting/BOSSetting.sol";

contract BookOfOptions is IBookOfOptions, BOSSetting, AccessControl {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using OptionsRepo for OptionsRepo.Repo;
    using OptionsRepo for OptionsRepo.Option;
    using OptionsRepo for OptionsRepo.Record;

    using RulesParser for bytes32;

    OptionsRepo.Repo private _repo;

    modifier optionExist(uint256 seqOfOpt) {
        require(isOption(seqOfOpt), 
            "BOO.mf.OE: Opt not exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function issueOption(
        bytes32 sn,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    ) external onlyKeeper returns (uint32 seqOfOpt) {
        seqOfOpt = _repo.issueOption(sn, rightholder, obligor, paid, par);
        _repo.options[seqOfOpt].head.state = uint8(OptionsRepo.OptStates.Issued);
        emit CreateOpt(seqOfOpt, rightholder, obligor, paid, par);
    }

    function createOption(
        OptionsRepo.Head memory head,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    ) external onlyKeeper returns (uint32 seqOfOpt) {
        seqOfOpt = _repo.createOption(head, rightholder, obligor, paid, par);
        _repo.options[seqOfOpt].head.state = uint8(OptionsRepo.OptStates.Issued);
        emit CreateOpt(seqOfOpt, rightholder, obligor, paid, par);
    }

    


    function registerOption(address opts)
        external
        onlyKeeper
    {
        uint32 len = IOptions(opts).counterOfOpts();

        while (len > 0) {

            (OptionsRepo.Head memory head, OptionsRepo.Body memory body) =
                IOptions(opts).getOption(len-1); 

            len--;

            if (head.state > 0) continue;
            else {


                _repo.increaseCounterOfOptions();
                uint32 seq = _repo.counterOfOptions();
                head.seqOfOpt = seq;

                emit RegisterOpt(seq, body.rightholder, body.obligor, body.paid, body.par);

                _repo.options[seq].head = head;
                _repo.options[seq].body = body;

                uint256[] memory obligors = IOptions(opts).obligorsOfOption(len);

                uint256 obLen = obligors.length;
                while (obLen > 0) {
                    _repo.records[seq].obligors.add(obligors[obLen - 1]);
                    obLen--;
                }

                IOptions(opts).optRegistered(len);
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
        uint32 d1,
        uint32 d2
    ) external onlyDirectKeeper {
        _repo.records[seqOfOpt].oracles.push(d1, d2, 0);
        emit UpdateOracle(seqOfOpt, d1, d2);
    }

    function execOption(uint256 seqOfOpt) external onlyKeeper {
        emit ExecOpt(seqOfOpt);
        _repo.execOption(seqOfOpt);
    }

    function addFuture(
        uint256 seqOfOpt,
        IBookOfShares.Share memory share,
        OptionsRepo.Future memory future 
    ) external onlyKeeper {
        if (_repo.addFuture(seqOfOpt, share, future)) {
            emit AddFuture(seqOfOpt, share.head.seq, future.paid, future.par);
        }
    }

    function removeFuture(uint256 seqOfOpt, uint256 seqOfFt) external onlyDirectKeeper {
        if (_repo.removeFuture(seqOfOpt, seqOfFt)) {
            emit RemoveFuture(seqOfOpt, seqOfFt);
        }
    }

    function requestPledge(
        uint256 seqOfOpt,
        IBookOfShares.Share memory share,
        uint64 paid,
        uint64 par
    ) external onlyDirectKeeper {
        if (_repo.requestPledge(seqOfOpt, share, paid, par))
            emit AddPledge(seqOfOpt, share.head.seq, paid, par);
    }

    function lockOption(uint256 seqOfOpt, bytes32 hashLock) external onlyDirectKeeper {
        _repo.options[seqOfOpt].lockOption(hashLock);
        emit LockOpt(seqOfOpt, hashLock);
    }

    function closeOption(uint256 seqOfOpt, string memory hashKey) external onlyDirectKeeper {
        _repo.options[seqOfOpt].closeOption(hashKey);
        emit CloseOpt(seqOfOpt, hashKey);
    }

    function revokeOption(uint256 seqOfOpt) external onlyDirectKeeper {
        _repo.options[seqOfOpt].revokeOption();
        emit RevokeOpt(seqOfOpt);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint32) {
        return _repo.counterOfOptions();
    }

    function isOption(uint256 seqOfOpt) public view returns (bool) {
        return _repo.options[seqOfOpt].head.state > 0;
    }

    function getOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (
            OptionsRepo.Option memory opt
        )
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

    function getFutureOfOption(uint256 seqOfOpt, uint256 seqOfFt)
        external view
        optionExist(seqOfOpt)
        returns (OptionsRepo.Future memory)
    {
        return _repo.records[seqOfOpt].futures[seqOfFt];
    }

    function futuresOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (OptionsRepo.Future[] memory)
    {
        return _repo.records[seqOfOpt].futuresOfOption();
    }

    function getPledgeOfOption(uint256 seqOfOpt, uint256 seqOfPld)
        external view 
        optionExist(seqOfOpt)
        returns (PledgesRepo.Pledge memory)
    {
        return _repo.records[seqOfOpt].pledges[seqOfPld];
    } 

    function pledgesOfOption(uint256 seqOfOpt)
        external
        view
        optionExist(seqOfOpt)
        returns (PledgesRepo.Pledge[] memory)
    {
        return _repo.records[seqOfOpt].pledgesOfOption();
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

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import "../../common/lib/OptionsRepo.sol";
import "../../common/lib/Checkpoints.sol";
import "../../common/lib/PledgesRepo.sol";

pragma solidity ^0.8.8;

interface IBookOfOptions {

    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(
        uint256 indexed seqOfOpt,
        uint40 rightholder,
        uint40 obligor,
        uint64 paid,
        uint64 par
    );

    event RegisterOpt(
        uint256 indexed seqOfOpt, 
        uint40 rightholder, 
        uint40 obligor, 
        uint64 paid, 
        uint64 par
    );

    event AddObligorIntoOpt(uint256 indexed seqOfOpt, uint256 obligor);

    event RemoveObligorFromOpt(uint256 indexed seqOfOpt, uint256 obligor);

    event UpdateOracle(uint256 indexed seqOfOpt, uint64 data1, uint64 data2, uint64 data3);

    event ExecOpt(uint256 indexed seqOfOpt);

    event AddOrder(
        uint256 indexed seqOfOpt,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par
    );

    event AddPledge(uint256 indexed seqOfOpt, uint256 seqOfShare, uint64 paid, uint64 par);

    event LockOpt(uint256 indexed seqOfOpt, bytes32 hashLock);

    event CloseOpt(uint256 indexed seqOfOpt, string hashKey);

    event RevokeOpt(uint256 indexed seqOfOpt);

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
    ) external returns (uint32 seqOfOpt);

    function issueOption(OptionsRepo.Option memory opt) 
        external returns (uint32 seqOfOpt);

    function registerOption(address opts) external;

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external;

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external;

    function updateOracle(
        uint256 seqOfOpt,
        uint64 d1,
        uint64 d2,
        uint64 d3
    ) external;

    function execOption(uint256 seqOfOpt) external;

    function addOrder(
        uint256 seqOfOpt,
        OptionsRepo.Order memory order
    ) external;

    function requestPledge(
        uint256 seqOfOpt,
        uint256 seqOfOdr,
        PledgesRepo.Pledge memory pledge
    ) external;

    function releasePledge(
        uint256 seqOfOpt,
        uint256 seqOfOdr,
        PledgesRepo.Head memory head
    ) external;

    function lockOption(uint256 seqOfOpt, bytes32 hashLock) external;

    function closeOption(uint256 seqOfOpt, string memory hashKey) external;

    function revokeOption(uint256 seqOfOpt, string memory hashKey) external;

    // ################
    // ##  查询接口   ##
    // ################

    function counterOfOptions() external view returns (uint32);

    function isOption(uint256 seqOfOpt) external view returns (bool);

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory opt);

    function optsList() external view returns (OptionsRepo.Option[] memory);

    function isObligor(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    function obligorsOfOption(uint256 seqOfOpt)
        external view returns (uint256[] memory);

    function stateOfOption(uint256 seqOfOpt) external view returns (uint8);

    function getOrder(uint256 seqOfOpt, uint256 seqOfFt)
        external view returns (OptionsRepo.Order memory);

    function ordersOfOption(uint256 seqOfOpt) external view returns (OptionsRepo.Order[] memory);

    function balanceOfOrder(uint256 seqOfOpt) external view 
        returns (uint64 paid, uint64 par);

    function getPledgeOfOption(uint256 seqOfOpt, uint256 seqOfPld)
        external view returns (PledgesRepo.Pledge memory);

    function pledgesOfOption(uint256 seqOfOpt) external view returns (PledgesRepo.Pledge[] memory);

    function balanceOfPledge(uint256 seqOfOpt) external view 
        returns (uint64 paid, uint64 par);

    function oracleAtDate(uint256 seqOfOpt, uint48 timestamp)
        external
        view
        returns (Checkpoints.Checkpoint memory);

    function oraclesOfOption(uint256 seqOfOpt)
        external
        view
        returns (Checkpoints.Checkpoint[] memory);    
}

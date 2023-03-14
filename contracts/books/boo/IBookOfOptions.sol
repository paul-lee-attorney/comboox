// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import "../bos/IBookOfShares.sol";

import "../bop/IBookOfPledges.sol";
import "../../common/lib/OptionsRepo.sol";
import "../../common/lib/Checkpoints.sol";
import "../../common/lib/PledgesRepo.sol";

pragma solidity ^0.8.8;

interface IBookOfOptions {

    enum TypeOfOption {
        Call_Price,
        Put_Price,
        Call_ROE,
        Put_ROE,
        Call_PriceAndConditions,
        Put_PriceAndConditions,
        Call_ROEAndConditions,
        Put_ROEAndConditions
    }

    enum StateOfOption {
        Pending,
        Issued,
        Executed,
        Futured,
        Pledged,
        Closed,
        Revoked,
        Expired
    }

    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(
        uint256 indexed seqOfOpt,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    );

    event RegisterOpt(
        uint256 indexed seqOfOpt, 
        uint256 rightholder, 
        uint256 obligor, 
        uint64 paid, 
        uint64 par
    );

    event AddObligorIntoOpt(uint256 indexed seqOfOpt, uint256 obligor);

    event RemoveObligorFromOpt(uint256 indexed seqOfOpt, uint256 obligor);

    event UpdateOracle(uint256 indexed seqOfOpt, uint256 data_1, uint256 data_2);

    event ExecOpt(uint256 indexed seqOfOpt);

    event AddFuture(
        uint256 indexed seqOfOpt,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par
    );

    event RemoveFuture(uint256 indexed seqOfOpt, uint256 seqOfFt);

    event AddPledge(uint256 indexed seqOfOpt, uint256 seqOfShare, uint64 paid, uint64 par);

    event LockOpt(uint256 indexed seqOfOpt, bytes32 hashLock);

    event CloseOpt(uint256 indexed seqOfOpt, string hashKey);

    event RevokeOpt(uint256 indexed seqOfOpt);

    // ################
    // ##   写接口   ##
    // ################

    function issueOption(
        bytes32 sn,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    ) external returns (uint32 seqOfOpt);

    function createOption(
        OptionsRepo.Head memory head,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    ) external returns (uint32 seqOfOpt);

    function registerOption(address opts) external;

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external;

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external;

    function updateOracle(
        uint256 seqOfOpt,
        uint32 d1,
        uint32 d2
    ) external;

    function execOption(uint256 seqOfOpt) external;

    function addFuture(
        uint256 seqOfOpt,
        IBookOfShares.Share memory share,
        OptionsRepo.Future memory future
    ) external;

    function removeFuture(uint256 seqOfOpt, uint256 seqOfFt) external;

    function requestPledge(
        uint256 seqOfOpt,
        IBookOfShares.Share memory share,
        uint64 paid,
        uint64 par
    ) external;

    function lockOption(uint256 seqOfOpt, bytes32 hashLock) external;

    function closeOption(uint256 seqOfOpt, string memory hashKey) external;

    function revokeOption(uint256 seqOfOpt) external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint32);

    function isOption(uint256 seqOfOpt) external view returns (bool);

    function getOption(uint256 seqOfOpt)
        external
        view
        returns (
            OptionsRepo.Option memory opt
        );

    function optsList() external view returns (OptionsRepo.Option[] memory);

    function isObligor(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    function obligorsOfOption(uint256 seqOfOpt)
        external view returns (uint256[] memory);

    function stateOfOption(uint256 seqOfOpt) external view returns (uint8);

    function getFutureOfOption(uint256 seqOfOpt, uint256 seqOfFt)
        external view returns (OptionsRepo.Future memory);

    function futuresOfOption(uint256 seqOfOpt) external view returns (OptionsRepo.Future[] memory);

    function getPledgeOfOption(uint256 seqOfOpt, uint256 seqOfPld)
        external view returns (PledgesRepo.Pledge memory);

    function pledgesOfOption(uint256 seqOfOpt) external view returns (PledgesRepo.Pledge[] memory);

    function oracleAtDate(uint256 seqOfOpt, uint48 timestamp)
        external
        view
        returns (Checkpoints.Checkpoint memory);

    function oraclesOfOption(uint256 seqOfOpt)
        external
        view
        returns (Checkpoints.Checkpoint[] memory);
    
}

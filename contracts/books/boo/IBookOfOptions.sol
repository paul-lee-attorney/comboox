// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBookOfOptions {
    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(
        bytes32 indexed sn,
        uint40 rightholder,
        uint64 paid,
        uint64 par
    );

    event AddObligorIntoOpt(bytes32 indexed sn, uint40 obligor);

    event RemoveObligorFromOpt(bytes32 indexed sn, uint40 obligor);

    event RegisterOpt(bytes32 indexed sn, uint64 paid, uint64 par);

    event CloseOpt(bytes32 indexed sn, string hashKey);

    event ExecOpt(bytes32 indexed sn);

    event RevokeOpt(bytes32 indexed sn);

    event UpdateOracle(bytes32 indexed sn, uint32 data_1, uint32 data_2);

    event AddFuture(
        bytes32 indexed sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par
    );

    event RemoveFuture(bytes32 indexed sn, bytes32 ft);

    event DelFuture(bytes32 indexed sn);

    event AddPledge(bytes32 indexed sn, bytes32 shareNumber, uint64 paid);

    event LockOpt(bytes32 indexed sn, bytes32 hashLock);

    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        bytes32 sn,
        uint40 rightholder,
        uint40[] memory obligors,
        uint64 paid,
        uint64 par
    ) external returns (bytes32 _sn);

    function registerOption(address opts) external;

    function addObligorIntoOption(bytes32 sn, uint40 obligor) external;

    function removeObligorFromOption(bytes32 sn, uint40 obligor) external;

    function updateOracle(
        bytes32 sn,
        uint32 d1,
        uint32 d2
    ) external;

    function execOption(bytes32 sn) external;

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par
    ) external;

    function removeFuture(bytes32 sn, bytes32 ft) external;

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid
    ) external;

    function lockOption(bytes32 sn, bytes32 hashLock) external;

    function closeOption(bytes32 sn, string memory hashKey) external;

    function revokeOption(bytes32 sn) external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOptions() external view returns (uint40);

    function isOption(bytes32 sn) external view returns (bool);

    function getOption(bytes32 sn)
        external
        view
        returns (
            uint40 rightholder,
            uint64 closingBN,
            uint64 paid,
            uint64 par,
            bytes32 hashLock
        );

    function isObligor(bytes32 sn, uint40 acct) external view returns (bool);

    function obligorsOfOption(bytes32 sn)
        external
        view
        returns (uint40[] memory);

    function stateOfOption(bytes32 sn) external view returns (uint8);

    function futures(bytes32 sn) external view returns (bytes32[] memory);

    function pledges(bytes32 sn) external view returns (bytes32[] memory);

    function oracle(bytes32 sn, uint64 blocknumber)
        external
        view
        returns (uint32 d1, uint32 d2);

    function optsList() external view returns (bytes32[] memory);
}

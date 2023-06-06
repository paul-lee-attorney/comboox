// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library LockersRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Locker {
        uint40 from;
        uint40 to;
        uint48 expireDate;
        uint128 hashLock;
    }

    struct Repo {
        // locker => value
        mapping (bytes32 => uint256) lockers;
        EnumerableSet.Bytes32Set snList;
    }

    //#################
    //##    Write    ##
    //#################

    function snParser(bytes32 sn) public pure returns (Locker memory locker) {
        uint _sn = uint(sn);
        
        locker = Locker({
            from: uint40(_sn >> 216),
            to: uint40(_sn >> 176),
            expireDate: uint48(_sn >> 128),
            hashLock: uint128(_sn)
        });
    }

    function lockValue(
        Repo storage repo,
        bytes32 sn,
        uint256 value,
        uint256 caller
    ) public returns(bool flag) {
        Locker memory locker = snParser(sn);

        require(block.timestamp < locker.expireDate, 
            "LR.LV: expireDate not in future");

        require(locker.from > 0, "LR.LV: zero from");
        require(locker.to > 0, "LR.LV: zero to");
        require(locker.hashLock > 0, "LR.LV: zero hashLock");

        require(locker.from == caller, "LR.LV: not from");

        if (repo.snList.add(sn)) {
            repo.lockers[sn] = value;
            flag = true;
        }
    }

    function releaseValue(
        Repo storage repo,
        bytes32 snOfLocker,
        string memory hashKey,
        uint256 caller
    ) public returns(uint256 value) {
        Locker memory locker = snParser(snOfLocker);

        require(block.timestamp < locker.expireDate, 
            "LR.RV: locker expired");
        require(locker.to == caller, 
            "LR.RV: not to");
        require(locker.hashLock == uint128(uint256(keccak256(bytes(hashKey)))),
            "LR.RV: wrong key");

        if (repo.snList.remove(snOfLocker)) {
            value = repo.lockers[snOfLocker];
            delete repo.lockers[snOfLocker];
        }
    }

    function withdrawValue(
        Repo storage repo,
        bytes32 snOfLocker,
        string memory hashKey,
        uint256 caller
    ) public returns(uint256 value) {
        Locker memory locker = snParser(snOfLocker);

        require(block.timestamp >= locker.expireDate, 
            "LR.RL: locker not expired");

        require(locker.from == caller, 
            "LR.RL: not from");

        require(locker.hashLock == uint128(uint256(keccak256(bytes(hashKey)))), 
            "LR.RL: wrong key");
        
        if (repo.snList.remove(snOfLocker)){
            value = repo.lockers[snOfLocker];
            delete repo.lockers[snOfLocker];
        }
    }

    function burnLocker(
        Repo storage repo,
        bytes32 snOfLocker,
        uint256 caller
    ) public returns(bool flag) {
        Locker memory locker = snParser(snOfLocker);

        require(block.timestamp >= locker.expireDate, 
            "LR.RL: locker not expired");

        require(locker.from == caller, 
            "LR.RL: not from");

        if (repo.snList.remove(snOfLocker)) {
            delete repo.lockers[snOfLocker];
            flag = true;
        }
    }

    //#################
    //##    Read     ##
    //#################

    function checkLocker(
        Repo storage repo,
        bytes32 snOfLocker,
        uint256 caller
    ) public view returns (uint256 value) {
        Locker memory locker = snParser(snOfLocker);

        require(locker.from == caller || locker.to == caller, 
            "LR.CL: not interestedParty");

        if (repo.snList.contains(snOfLocker)) {
            value = repo.lockers[snOfLocker];            
        }        
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library LockersRepo {

    struct Head {
        uint40 from;
        uint40 to;
        uint48 expireDate;
        uint128 value;
    }
    struct Body {
        address counterLocker;
        bytes4 selector;
        uint64 data;
    }
    struct Locker {
        Head head;
        Body body;
    }

    struct Repo {
        // hashLock => locker
        mapping (bytes32 => Locker) lockers;
    }

    //#################
    //##    Write    ##
    //#################

    function headSnParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        
        head = Head({
            from: uint40(_sn >> 216),
            to: uint40(_sn >> 176),
            expireDate: uint48(_sn >> 128),
            value: uint128(_sn)
        });
    }

    function bodySnParser(bytes32 sn) public pure returns (Body memory body) {
        uint _sn = uint(sn);
        
        body = Body({
            counterLocker: address(uint160(_sn >> 96)),
            selector: bytes4(uint32(_sn >> 64)),
            data: uint64(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 headSn) {
        bytes memory _sn = abi.encode(
                            head.from,
                            head.to,
                            head.expireDate,
                            head.value);
        assembly {
            headSn := mload(add(_sn, 0x20))
        }
    }

    function lockAsset(
        Repo storage repo,
        bytes32 headSn,
        bytes32 hashLock
    ) public {
        Locker storage locker = repo.lockers[hashLock]; 
        
        if (locker.head.value == 0) {            
            locker.head = headSnParser(headSn);
        } else revert ("LR.lockAsset: occupied");
    }

    function lockMoney(
        Repo storage repo,
        bytes32 headSn,
        bytes32 bodySn,
        bytes32 hashLock
    ) public {
        Locker storage locker = repo.lockers[hashLock]; 
        
        if (locker.head.value == 0) {            
            locker.head = headSnParser(headSn);
            locker.body = bodySnParser(bodySn);
        } else revert ("LR.lockMoney: occupied");
    }

    function fetchMoney(
        Repo storage repo,
        bytes32 hashLock,
        bytes memory hashKey,
        uint caller
    ) public returns(Head memory head) {
        require(hashLock == keccak256(hashKey),
            "LR.fetchMoney: wrong key");

        Locker storage locker = repo.lockers[hashLock];

        require(block.timestamp < locker.head.expireDate, 
            "LR.fetchMoney: locker expired");

        require(locker.head.to == caller, 
            "LR.fetchMoney: wrong caller");

        bytes memory payload = abi.encodeWithSelector(locker.body.selector, hashKey);
        (bool flag, ) = locker.body.counterLocker.call(payload);

        if (flag) {
            head = locker.head;
            delete repo.lockers[hashLock];
        }
    }

    function releaseAsset (
        Repo storage repo,
        bytes32 hashLock,
        bytes memory hashKey
    ) public returns(Head memory head) {
        require(hashLock == keccak256(hashKey),
            "LR.releaseAsset: wrong key");

        Locker storage locker = repo.lockers[hashLock];

        require(block.timestamp < locker.head.expireDate, 
            "LR.releaseAsset: locker expired");

        // require(locker.body.counterLocker == msgSender, 
        //     "LR.releaseAsset: wrong msgSender");

        // require(locker.body.selector == selector, 
        //     "LR.releaseAsset: wrong functionSelector");

        head = locker.head;
        delete repo.lockers[hashLock];
    }

    function burnLocker(
        Repo storage repo,
        bytes32 hashLock,
        uint256 caller
    ) public returns(Head memory head) {

        Locker memory locker = repo.lockers[hashLock];

        require(block.timestamp >= locker.head.expireDate, 
            "LR.burnLocker: locker not expired");

        require(locker.head.from == caller, 
            "LR.burnLocker: wrong caller");
        
        head = locker.head;
        delete repo.lockers[hashLock];
    }

    //#################
    //##    Read     ##
    //#################

    function checkLocker(
        Repo storage repo,
        bytes32 hashLock,
        uint256 caller
    ) public view returns (Locker memory) {

        Locker memory locker = repo.lockers[hashLock];

        require(locker.head.from == caller || locker.head.to == caller, 
            "LR.CL: not interested party"); 

        return locker;
    }

}

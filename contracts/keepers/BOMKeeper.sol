// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

// import "../common/ruting/BOSSetting.sol";

import "./IBOMKeeper.sol";

contract BOMKeeper is IBOMKeeper, AccessControl {

    // ###################
    // ##   BOMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDirectKeeper {
        _gk.getBOM().setMaxQtyOfMembers(max);
    }

    function setPayInAmt(bytes32 headSn, bytes32 hashLock) 
    external onlyDirectKeeper {
        _gk.getBOS().setPayInAmt(headSn, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey)
    external onlyDirectKeeper {
        _gk.getBOS().requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDirectKeeper {
        _gk.getBOS().withdrawPayInAmt(hashLock, seqOfShare);
    }

    function decreaseCapital(uint256 seqOfShare, uint paid, uint par) 
    external onlyDirectKeeper {
        _gk.getBOS().decreaseCapital(seqOfShare, paid, par);
    }

    // function updatePaidInDeadline(uint256 seqOfShare, uint line) 
    // external onlyDirectKeeper {
    //     _gk.getBOS().updatePaidInDeadline(seqOfShare, line);
    // }
}

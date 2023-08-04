// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

// import "../common/ruting/BOSSetting.sol";

import "./IROMKeeper.sol";

contract ROMKeeper is IROMKeeper, AccessControl {

    

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        _getGK().getROM().setMaxQtyOfMembers(max);
    }

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) 
    external onlyDK {
        _getGK().getBOS().setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey)
    external onlyDK {
        _getGK().getBOS().requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        _getGK().getBOS().withdrawPayInAmt(hashLock, seqOfShare);
    }

    function decreaseCapital(uint256 seqOfShare, uint paid, uint par) 
    external onlyDK {
        _getGK().getBOS().decreaseCapital(seqOfShare, paid, par);
    }

    // function updatePaidInDeadline(uint256 seqOfShare, uint line) 
    // external onlyDK {
    //     _gk.getBOS().updatePaidInDeadline(seqOfShare, line);
    // }
}

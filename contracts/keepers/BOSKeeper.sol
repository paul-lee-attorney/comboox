// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

// import "../common/ruting/BOSSetting.sol";

import "./IBOSKeeper.sol";

contract BOSKeeper is IBOSKeeper, AccessControl {

    // #############
    // ##   BOS   ##
    // #############

    function setPayInAmt(uint256 sn, uint64 amount) 
    external onlyDirectKeeper {
        _gk.getBOS().setPayInAmt(sn, amount);
    }

    function requestPaidInCapital(uint256 snOfLocker, string memory hashKey, uint8 salt, uint256 caller)
    external onlyDirectKeeper {
        _gk.getBOS().requestPaidInCapital(snOfLocker, hashKey, salt, caller);
    }

    function withdrawPayInAmt(uint256 snOfLocker) external onlyDirectKeeper {
        _gk.getBOS().withdrawPayInAmt(snOfLocker);
    }

    function decreaseCapital(uint256 seqOfShare, uint64 paid, uint64 par) 
    external onlyDirectKeeper {
        _gk.getBOS().decreaseCapital(seqOfShare, paid, par);
    }

    function updatePaidInDeadline(uint256 seqOfShare, uint48 line) 
    external onlyDirectKeeper {
        _gk.getBOS().updatePaidInDeadline(seqOfShare, line);
    }
}

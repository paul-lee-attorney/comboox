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

    function setPayInAmt(bytes32 snOfLocker, uint amount) 
    external onlyDirectKeeper {
        _gk.getBOS().setPayInAmt(snOfLocker, amount);
    }

    function requestPaidInCapital(bytes32 snOfLocker, string memory hashKey, uint salt, uint256 caller)
    external onlyDirectKeeper {
        _gk.getBOS().requestPaidInCapital(snOfLocker, hashKey, salt, caller);
    }

    function withdrawPayInAmt(bytes32 snOfLocker) external onlyDirectKeeper {
        _gk.getBOS().withdrawPayInAmt(snOfLocker);
    }

    function decreaseCapital(uint256 seqOfShare, uint paid, uint par) 
    external onlyDirectKeeper {
        _gk.getBOS().decreaseCapital(seqOfShare, paid, par);
    }

    function updatePaidInDeadline(uint256 seqOfShare, uint line) 
    external onlyDirectKeeper {
        _gk.getBOS().updatePaidInDeadline(seqOfShare, line);
    }
}

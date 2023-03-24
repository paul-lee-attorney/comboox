// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "../common/ruting/BOSSetting.sol";

// import "../common/lib/SNParser.sol";
import "./IBOSKeeper.sol";

contract BOSKeeper is IBOSKeeper, BOSSetting, AccessControl {
    // using SNParser for bytes32;

    // #############
    // ##   BOS   ##
    // #############

    function setPayInAmount(bytes32 sn, uint64 amount) 
    external onlyDirectKeeper {
        _getBOS().setPayInAmt(sn, amount);
    }

    function requestPaidInCapital(bytes32 sn, string memory hashKey, uint256 caller)
    external onlyDirectKeeper {
        _getBOS().requestPaidInCapital(sn, hashKey, caller);
    }

    function withdrawPayInAmount(bytes32 sn) external onlyDirectKeeper {
        _getBOS().withdrawPayInAmt(sn);
    }

    function decreaseCapital(uint256 seqOfShare, uint64 paid, uint64 par) 
    external onlyDirectKeeper {
        _getBOS().decreaseCapital(seqOfShare, paid, par);
    }

    function updatePaidInDeadline(uint256 seqOfShare, uint48 line) 
    external onlyDirectKeeper {
        _getBOS().updatePaidInDeadline(seqOfShare, line);
    }
}

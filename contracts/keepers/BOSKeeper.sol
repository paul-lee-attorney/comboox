// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "../common/ruting/BOSSetting.sol";

import "../common/lib/SNParser.sol";
import "./IBOSKeeper.sol";

contract BOSKeeper is IBOSKeeper, BOSSetting, AccessControl {
    using SNParser for bytes32;

    // #############
    // ##   BOS   ##
    // #############

    function setPayInAmount(bytes32 sn, uint64 amount) external onlyDirectKeeper {
        _getBOS().setPayInAmount(sn, amount);
    }

    function requestPaidInCapital(bytes32 sn, string memory hashKey)
        external
        onlyDirectKeeper
    {
        _getBOS().requestPaidInCapital(sn, hashKey);
    }

    function withdrawPayInAmount(bytes32 sn) external onlyDirectKeeper {
        _getBOS().withdrawPayInAmount(sn);
    }

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external onlyDirectKeeper {
        _getBOS().decreaseCapital(ssn, paid, par);
    }

    function updatePaidInDeadline(uint32 ssn, uint32 line) external onlyDirectKeeper {
        _getBOS().updatePaidInDeadline(ssn, line);
    }
}

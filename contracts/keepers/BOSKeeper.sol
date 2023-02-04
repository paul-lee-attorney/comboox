// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/ruting/BOSSetting.sol";
import "../common/lib/SNParser.sol";
import "./IBOSKeeper.sol";

contract BOSKeeper is IBOSKeeper, BOSSetting {
    using SNParser for bytes32;

    // #############
    // ##   BOS   ##
    // #############

    function setPayInAmount(bytes32 sn, uint64 amount) external onlyDK {
        _bos.setPayInAmount(sn, amount);
    }

    function requestPaidInCapital(bytes32 sn, string memory hashKey)
        external
        onlyDK
    {
        _bos.requestPaidInCapital(sn, hashKey);
    }

    function withdrawPayInAmount(bytes32 sn) external onlyDK {
        _bos.withdrawPayInAmount(sn);
    }

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external onlyDK {
        _bos.decreaseCapital(ssn, paid, par);
    }

    function updatePaidInDeadline(uint32 ssn, uint32 line) external onlyDK {
        _bos.updatePaidInDeadline(ssn, line);
    }
}

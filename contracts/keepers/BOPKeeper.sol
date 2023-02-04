// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOPSetting.sol";

import "../common/lib/SNParser.sol";

import "./IBOPKeeper.sol";

contract BOPKeeper is IBOPKeeper, BOPSetting, BOSSetting {
    using SNParser for bytes32;

    // ################
    // ##   Pledge   ##
    // ################

    function createPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint40 caller
    ) external onlyDK {
        require(
            sn.ssnOfPld() == shareNumber.ssn(),
            "BOPKeeper.createPledge: wrong shareNumber"
        );
        require(shareNumber.shareholder() == caller, "NOT shareholder");

        _bos.decreaseCleanPar(shareNumber.ssn(), pledgedPar);

        _bop.createPledge(
            sn,
            creditor,
            monOfGuarantee,
            pledgedPar,
            guaranteedAmt
        );
    }

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint64 expireBN,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint40 caller
    ) external onlyDK {
        require(pledgedPar != 0, "BOPKeeper.updatePledge: ZERO pledgedPar");

        uint32 shortShareNumber = sn.ssnOfPld();

        (uint40 orgCreditor, uint64 orgExpireBN, uint64 orgPledgedPar, ) = _bop
            .getPledge(sn);

        if (pledgedPar < orgPledgedPar || expireBN < orgExpireBN) {
            require(
                caller == orgCreditor,
                "BOPKeeper.updatePledge: NOT creditor"
            );
            _bos.increaseCleanPar(shortShareNumber, orgPledgedPar - pledgedPar);
        } else if (pledgedPar > orgPledgedPar || expireBN > orgExpireBN) {
            require(
                caller == sn.pledgorOfPld(),
                "BOPKeeper.updatePledge: NOT pledgor"
            );
            _bos.decreaseCleanPar(shortShareNumber, pledgedPar - orgPledgedPar);
        }

        if (creditor != orgCreditor) {
            require(
                caller == orgCreditor,
                "BOPKeeper.updatePledge: NOT creditor"
            );
        }

        _bop.updatePledge(sn, creditor, expireBN, pledgedPar, guaranteedAmt);
    }

    function delPledge(bytes32 sn, uint40 caller) external onlyDK {
        (uint40 creditor, uint64 expireBN, uint64 pledgedPar, ) = _bop
            .getPledge(sn);

        if (block.number < expireBN)
            require(caller == creditor, "NOT creditor");

        _bos.increaseCleanPar(sn.ssnOfPld(), pledgedPar);

        _bop.updatePledge(sn, creditor, 0, 0, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOPSetting.sol";

import "../common/lib/SNParser.sol";

import "./IBOPKeeper.sol";

contract BOPKeeper is IBOPKeeper, BOPSetting, BOSSetting, AccessControl {
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
    ) external onlyDirectKeeper {
        require(
            sn.ssnOfPld() == shareNumber.ssn(),
            "BOPKeeper.createPledge: wrong shareNumber"
        );
        require(shareNumber.shareholder() == caller, "NOT shareholder");

        _getBOS().decreaseCleanPar(shareNumber.ssn(), pledgedPar);

        _getBOP().createPledge(
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
        uint48 expireDate,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint40 caller
    ) external onlyDirectKeeper {
        require(pledgedPar != 0, "BOPKeeper.updatePledge: ZERO pledgedPar");

        uint32 shortShareNumber = sn.ssnOfPld();

        IBookOfPledges.Pledge memory pld = _getBOP().getPledge(sn);

        if (pledgedPar < pld.pledgedPar || expireDate < pld.expireDate) {
            require(
                caller == pld.creditor,
                "BOPKeeper.updatePledge: NOT creditor"
            );
            _getBOS().increaseCleanPar(shortShareNumber, pld.pledgedPar - pledgedPar);
        } else if (pledgedPar > pld.pledgedPar || expireDate > pld.expireDate) {
            require(
                caller == sn.pledgorOfPld(),
                "BOPKeeper.updatePledge: NOT pledgor"
            );
            _getBOS().decreaseCleanPar(shortShareNumber, pledgedPar - pld.pledgedPar);
        }

        if (creditor != pld.creditor) {
            require(
                caller == pld.creditor,
                "BOPKeeper.updatePledge: NOT creditor"
            );
        }

        _getBOP().updatePledge(sn, creditor, expireDate, pledgedPar, guaranteedAmt);
    }

    function delPledge(bytes32 sn, uint40 caller) external onlyDirectKeeper {
        
        IBookOfPledges.Pledge memory pld = _getBOP().getPledge(sn);

        if (block.timestamp < pld.expireDate)
            require(caller == pld.creditor, "NOT creditor");

        _getBOS().increaseCleanPar(sn.ssnOfPld(), pld.pledgedPar);

        _getBOP().updatePledge(sn, pld.creditor, 0, 0, 0);
    }
}

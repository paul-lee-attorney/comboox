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
    ) external onlyDirectKeeper {
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
        uint48 expireDate,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint40 caller
    ) external onlyDirectKeeper {
        require(pledgedPar != 0, "BOPKeeper.updatePledge: ZERO pledgedPar");

        uint32 shortShareNumber = sn.ssnOfPld();

        IBookOfPledges.Pledge memory pld = _bop.getPledge(sn);

        if (pledgedPar < pld.pledgedPar || expireDate < pld.expireDate) {
            require(
                caller == pld.creditor,
                "BOPKeeper.updatePledge: NOT creditor"
            );
            _bos.increaseCleanPar(shortShareNumber, pld.pledgedPar - pledgedPar);
        } else if (pledgedPar > pld.pledgedPar || expireDate > pld.expireDate) {
            require(
                caller == sn.pledgorOfPld(),
                "BOPKeeper.updatePledge: NOT pledgor"
            );
            _bos.decreaseCleanPar(shortShareNumber, pledgedPar - pld.pledgedPar);
        }

        if (creditor != pld.creditor) {
            require(
                caller == pld.creditor,
                "BOPKeeper.updatePledge: NOT creditor"
            );
        }

        _bop.updatePledge(sn, creditor, expireDate, pledgedPar, guaranteedAmt);
    }

    function delPledge(bytes32 sn, uint40 caller) external onlyDirectKeeper {
        
        IBookOfPledges.Pledge memory pld = _bop.getPledge(sn);

        if (block.timestamp < pld.expireDate)
            require(caller == pld.creditor, "NOT creditor");

        _bos.increaseCleanPar(sn.ssnOfPld(), pld.pledgedPar);

        _bop.updatePledge(sn, pld.creditor, 0, 0, 0);
    }
}

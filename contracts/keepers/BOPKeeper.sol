// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOPSetting.sol";

import "../common/lib/PledgesRepo.sol";
import "../common/lib/SharesRepo.sol";

import "./IBOPKeeper.sol";

contract BOPKeeper is IBOPKeeper, BOPSetting, BOSSetting, AccessControl {
    using PledgesRepo for uint256;

    // ################
    // ##   Pledge   ##
    // ################

    function createPledge(
        uint256 sn,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint256 caller
    ) external onlyDirectKeeper {

        PledgesRepo.Head memory head = sn.snParser();

        IBookOfShares _bos = _getBOS();

        SharesRepo.Share memory share = _bos.getShare(head.seqOfShare);

        require(share.head.shareholder == caller, "BOPK.CP: NOT shareholder");
        require(head.pledgor == caller, "BOPK.CP: NOT pledgor");

        // _bos.decreaseCleanAmt(head.seqOfShare, pledgedPaid, pledgedPar);

        _getBOP().createPledge(
            sn,
            creditor,
            monOfGuarantee,
            pledgedPaid,
            pledgedPar,
            guaranteedAmt
        );
    }

    function updatePledge(
        uint256 seqOfShare,
        uint256 seqOfPledge,
        uint40 creditor,
        uint48 expireDate,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint256 caller
    ) external onlyDirectKeeper {

        require(pledgedPaid != 0, "BOPK.UP: ZERO pledgedPaid");

        PledgesRepo.Pledge memory pld = _getBOP().getPledge(seqOfShare, seqOfPledge);

        if (pledgedPaid < pld.body.paid ||
            pledgedPar < pld.body.par || 
            expireDate < pld.head.expireDate ||
            creditor != pld.body.creditor) 
        {   require(caller == pld.body.creditor, "BOPK.UP: NOT creditor");

            // _getBOS().increaseCleanAmt(
            //     seqOfShare,
            //     pld.body.pledgedPaid - pledgedPaid > 0 ? pld.body.pledgedPaid - pledgedPaid : 0,
            //     pld.body.pledgedPar - pledgedPar > 0 ? pld.body.pledgedPar - pledgedPar : 0
            // );

        } else if (pledgedPaid > pld.body.paid || 
            pledgedPar > pld.body.par ||
            expireDate > pld.head.expireDate) 
        {
            require(caller == pld.head.pledgor,"BOPK.UP: NOT pledgor");

            // _getBOS().decreaseCleanAmt(
            //     seqOfShare, 
            //     pledgedPaid - pld.body.pledgedPaid > 0 ? pledgedPaid - pld.body.pledgedPaid : 0,
            //     pledgedPar - pld.body.pledgedPar > 0 ? pledgedPar - pld.body.pledgedPar : 0
            // );
        }

        _getBOP().updatePledge(seqOfShare, seqOfPledge, creditor, expireDate, pledgedPaid, pledgedPar, guaranteedAmt);
    }

    function delPledge(uint256 seqOfShare, uint256 seqOfPledge, uint256 caller) external onlyDirectKeeper {
        
        PledgesRepo.Pledge memory pld = _getBOP().getPledge(seqOfShare, seqOfPledge);

        if (block.timestamp < pld.head.expireDate)
            require(caller == pld.body.creditor, "NOT creditor");
        else require(caller == pld.head.pledgor, "NOT Pledgor");

        _getBOS().increaseCleanAmt(seqOfShare, pld.body.paid, pld.body.par);

        _getBOP().updatePledge(seqOfShare, seqOfPledge, pld.body.creditor, 0, 0, 0, 0);
    }
}

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

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        uint256 sn,
        uint40 creditor,
        uint16 guaranteeDays,
        uint64 paid,
        uint64 par,
        uint64 guaranteedAmt,
        uint256 caller
    ) external onlyDirectKeeper {

        PledgesRepo.Head memory head = sn.snParser();

        IBookOfShares _bos = _getBOS();

        require(_bos.getShare(head.seqOfShare).head.shareholder == caller, 
            "BOPK.CP: NOT shareholder");
        require(head.pledgor == caller, "BOPK.CP: NOT pledgor");

        head = _getBOP().createPledge(
            sn,
            creditor,
            guaranteeDays,
            paid,
            par,
            guaranteedAmt
        );

        _bos.decreaseCleanAmt(head.seqOfShare, paid, par);
    }

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint40 buyer,
        uint64 amt,
        uint256 caller        
    ) external onlyDirectKeeper {
        IBookOfPledges _bop = _getBOP();
        require(_bop.getPledge(seqOfShare, seqOfPld).body.creditor == caller,
            "BOPK.TP: not creditor");
        _bop.transferPledge(seqOfShare, seqOfPld, buyer, amt);
    }

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint64 amt,
        uint256 caller
    ) external onlyDirectKeeper {
        IBookOfPledges _bop = _getBOP();
        PledgesRepo.Pledge memory pld = _bop.getPledge(seqOfShare, seqOfPld);

        require(pld.body.creditor == caller, "BOPK.RD: not creditor");

        pld = _bop.refundDebt(seqOfShare, seqOfPld, amt);
        _getBOS().increaseCleanAmt(seqOfShare, pld.body.paid, pld.body.par);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint16 extDays,
        uint256 caller
    ) external onlyDirectKeeper {
        IBookOfPledges _bop = _getBOP();
        require(_bop.getPledge(seqOfShare, seqOfPld).head.pledgor == caller,
            "BOPK.EP: not pledgor");
        _bop.extendPledge(seqOfShare, seqOfPld, extDays);    
    }

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint256 caller
    ) external onlyDirectKeeper {
        IBookOfPledges _bop = _getBOP();
        require(_bop.getPledge(seqOfShare, seqOfPld).body.creditor == caller,
            "BOPK.LP: not creditor");
        
        _bop.lockPledge(seqOfShare, seqOfPld, hashLock);    
    }

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey,
        uint256 caller
    ) external onlyDirectKeeper {
        IBookOfPledges _bop = _getBOP();
        PledgesRepo.Pledge memory pld = _bop.getPledge(seqOfShare, seqOfPld);

        require(pld.head.pledgor == caller, "BOPK.RP: not pledgor");
        
        _bop.releasePledge(seqOfShare, seqOfPld, hashKey);
        _getBOS().increaseCleanAmt(seqOfShare, pld.body.paid, pld.body.par);       
    }

    function execPledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external onlyDirectKeeper {
        IBookOfPledges _bop = _getBOP();
        PledgesRepo.Pledge memory pld = _bop.getPledge(seqOfShare, seqOfPld);

        require(pld.body.creditor == caller,
            "BOPK.EP: not creditor");

        if (_bop.execPledge(seqOfShare, seqOfPld)) {
            
            IBookOfShares _bos = _getBOS();

            _bos.increaseCleanAmt(seqOfShare, pld.body.paid, pld.body.par);
            _bos.transferShare(seqOfShare, pld.body.paid, pld.body.par, pld.body.creditor, uint32(pld.body.guaranteedAmt/pld.body.paid));
        }
    }

    function revokePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external onlyDirectKeeper {
        IBookOfPledges _bop = _getBOP();
        PledgesRepo.Pledge memory pld = _bop.getPledge(seqOfShare, seqOfPld);

        require(pld.head.pledgor == caller, "BOPK.RP: not pledgor");
        if (_bop.revokePledge(seqOfShare, seqOfPld)) {
            _getBOS().increaseCleanAmt(seqOfShare, pld.body.paid, pld.body.par);   
        }
    }
}

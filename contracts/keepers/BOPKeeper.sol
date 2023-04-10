// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";
// import "../common/ruting/BOSSetting.sol";
// import "../common/ruting/BOPSetting.sol";

import "./IBOPKeeper.sol";

contract BOPKeeper is IBOPKeeper, AccessControl {
    using PledgesRepo for uint256;

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        uint256 sn,
        uint creditor,
        uint guaranteeDays,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint256 caller
    ) external onlyDirectKeeper {

        PledgesRepo.Head memory head = sn.snParser();

        require(_gk.getBOS().getShare(head.seqOfShare).head.shareholder == caller, 
            "BOPK.CP: NOT shareholder");
        require(head.pledgor == caller, "BOPK.CP: NOT pledgor");

        head = _gk.getBOP().createPledge(
            sn,
            creditor,
            guaranteeDays,
            paid,
            par,
            guaranteedAmt
        );

        _gk.getBOS().decreaseCleanPaid(head.seqOfShare, paid);
    }

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint256 caller        
    ) external onlyDirectKeeper {
        require(_gk.getBOP().getPledge(seqOfShare, seqOfPld).body.creditor == caller,
            "BOPK.TP: not creditor");
        _gk.getBOP().transferPledge(seqOfShare, seqOfPld, buyer, amt);
    }

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        uint256 caller
    ) external onlyDirectKeeper {
        PledgesRepo.Pledge memory pld = _gk.getBOP().getPledge(seqOfShare, seqOfPld);

        require(pld.body.creditor == caller, "BOPK.RD: not creditor");

        pld = _gk.getBOP().refundDebt(seqOfShare, seqOfPld, amt);
        _gk.getBOS().increaseCleanPaid(seqOfShare, pld.body.paid);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        uint256 caller
    ) external onlyDirectKeeper {
        require(_gk.getBOP().getPledge(seqOfShare, seqOfPld).head.pledgor == caller,
            "BOPK.EP: not pledgor");
        _gk.getBOP().extendPledge(seqOfShare, seqOfPld, extDays);    
    }

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint256 caller
    ) external onlyDirectKeeper {
        require(_gk.getBOP().getPledge(seqOfShare, seqOfPld).body.creditor == caller,
            "BOPK.LP: not creditor");
        
        _gk.getBOP().lockPledge(seqOfShare, seqOfPld, hashLock);    
    }

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey,
        uint256 caller
    ) external onlyDirectKeeper {
        PledgesRepo.Pledge memory pld = _gk.getBOP().getPledge(seqOfShare, seqOfPld);

        require(pld.head.pledgor == caller, "BOPK.RP: not pledgor");
        
        _gk.getBOP().releasePledge(seqOfShare, seqOfPld, hashKey);
        _gk.getBOS().increaseCleanPaid(seqOfShare, pld.body.paid);       
    }

    function execPledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external onlyDirectKeeper {
        PledgesRepo.Pledge memory pld = _gk.getBOP().getPledge(seqOfShare, seqOfPld);

        require(pld.body.creditor == caller,
            "BOPK.EP: not creditor");

        if (_gk.getBOP().execPledge(seqOfShare, seqOfPld)) {
            _gk.getBOS().increaseCleanPaid(seqOfShare, pld.body.paid);
            _gk.getBOS().transferShare(seqOfShare, pld.body.paid, pld.body.par, pld.body.creditor, uint32(pld.body.guaranteedAmt/pld.body.paid), 0);
        }
    }

    function revokePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external onlyDirectKeeper {
        PledgesRepo.Pledge memory pld = _gk.getBOP().getPledge(seqOfShare, seqOfPld);

        require(pld.head.pledgor == caller, "BOPK.RP: not pledgor");
        if (_gk.getBOP().revokePledge(seqOfShare, seqOfPld)) {
            _gk.getBOS().increaseCleanPaid(seqOfShare, pld.body.paid);   
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfPledges.sol";

import "../../common/access/AccessControl.sol";
// import "../../common/ruting/BOSSetting.sol";

contract BookOfPledges is IBookOfPledges, AccessControl {
    using PledgesRepo for PledgesRepo.Repo;
    using PledgesRepo for PledgesRepo.Pledge;

    PledgesRepo.Repo private _repo;

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        uint256 sn,
        uint40 creditor,
        uint16 guaranteeDays,
        uint64 paid,
        uint64 par,
        uint64 guaranteedAmt
    ) external onlyDirectKeeper returns(PledgesRepo.Head memory head){
        head = _repo.createPledge(
            sn,
            creditor,
            guaranteeDays,  
            paid,
            par,
            guaranteedAmt
        );

        emit CreatePledge(
            head.seqOfShare,
            head.seqOfPld,
            creditor,
            paid,
            par
        );
    }

    function issuePledge(
        PledgesRepo.Head memory head,
        uint40 creditor,
        uint16 guaranteeDays,
        uint64 paid,
        uint64 par,
        uint64 guaranteedAmt
    ) external onlyKeeper returns(PledgesRepo.Head memory regHead)
    {
        regHead = _repo.issuePledge(
            head, 
            creditor,
            guaranteeDays,
            paid,
            par,
            guaranteedAmt
        );

        emit CreatePledge(
            head.seqOfShare,
            head.seqOfPld,
            creditor,
            paid,
            par
        );
    }

    function regPledge(
        PledgesRepo.Pledge memory pld
    ) external onlyKeeper returns(PledgesRepo.Head memory head){
        head = _repo.regPledge(pld);

        emit CreatePledge(
            head.seqOfShare, 
            head.seqOfPld, 
            pld.body.creditor,
            pld.body.paid, 
            pld.body.par 
        );
    }

    // ==== Transfer Pledge ====

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint40 buyer,
        uint64 amt
    ) external onlyKeeper returns (PledgesRepo.Pledge memory newPld)
    {
        require(buyer > 0, "BOP.TP: zero buyer");

        newPld = _repo.splitPledge(seqOfShare, seqOfPld, buyer, amt);

        emit TransferPledge(
            newPld.head.seqOfShare, 
            seqOfPld,
            newPld.head.seqOfPld, 
            newPld.body.creditor,
            newPld.body.paid, 
            newPld.body.par 
        );
    }

    // ==== Update Pledge ====

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint64 amt
    ) external onlyKeeper returns (PledgesRepo.Pledge memory newPld)
    {
        newPld = _repo.splitPledge(seqOfShare, seqOfPld, 0, amt);

        emit RefundDebt(seqOfShare, seqOfPld, amt);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint16 extDays
    ) external onlyKeeper {
        _repo.pledges[seqOfShare][seqOfPld].extendPledge(extDays);
        emit ExtendPledge(seqOfShare, seqOfPld, extDays);
    }

    // ==== Lock/Release/Exec/Revoke ====

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock
    ) external onlyKeeper returns (bool flag) {
        if (_repo.pledges[seqOfShare][seqOfPld].lockPledge(hashLock))
        {
            emit LockPledge(seqOfShare, seqOfPld, hashLock);
            flag = true;
        }
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey)
        external onlyKeeper returns (bool flag)
    {
        if (_repo.pledges[seqOfShare][seqOfPld].releasePledge(hashKey)){   
            emit ReleasePledge(seqOfShare, seqOfPld, hashKey);
            flag = true;
        }
    }

    function execPledge(uint256 seqOfShare, uint256 seqOfPld)
        external onlyKeeper returns (bool flag) 
    {
        if (_repo.pledges[seqOfShare][seqOfPld].execPledge()) {
            emit ExecPledge(seqOfShare, seqOfPld);
            flag = true;
        }
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld)
        external onlyKeeper returns (bool flag) 
    {
        if (_repo.pledges[seqOfShare][seqOfPld].revokePledge()) {
            emit RevokePledge(seqOfShare, seqOfPld);
            flag = true;
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function counterOfPledges(uint256 seqOfShare) 
        external view returns (uint16) 
    {
        return _repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    function isPledge(uint256 seqOfShare, uint256 seqOfPledge) 
        external view returns (bool) 
    {
        return _repo.pledges[seqOfShare][seqOfPledge].head.createDate > 0;
    }

    function getPledge(uint256 seqOfShare, uint256 seqOfPld)
        external view returns (PledgesRepo.Pledge memory pld)
    {
        pld = _repo.pledges[seqOfShare][seqOfPld];
    }

    function getPledgesOfShare(uint256 seqOfShare) 
        external view returns (PledgesRepo.Pledge[] memory) 
    {
        return _repo.getPledgesOfShare(seqOfShare);
    }

    function getSNList() external view returns(uint256[] memory list)
    {
        list = _repo.getSNList();
    }
}

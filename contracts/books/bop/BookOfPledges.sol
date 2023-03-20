// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfPledges.sol";

import "../../common/access/AccessControl.sol";
import "../../common/ruting/BOSSetting.sol";

contract BookOfPledges is IBookOfPledges, BOSSetting, AccessControl {
    using PledgesRepo for PledgesRepo.Repo;
    using PledgesRepo for PledgesRepo.Pledge;

    PledgesRepo.Repo private _repo;

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        uint256 sn,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDirectKeeper returns(PledgesRepo.Head memory head){
        head = _repo.createPledge(
            sn, 
            creditor, 
            monOfGuarantee, 
            pledgedPaid, 
            pledgedPar, 
            guaranteedAmt
        );

        emit CreatePledge(
            head.seqOfShare,
            head.seqOfPld,
            creditor,
            pledgedPaid,
            pledgedPar,
            guaranteedAmt
        );

        _getBOS().decreaseCleanAmt(head.seqOfShare, pledgedPaid, pledgedPar);

    }

    function issuePledge(
        PledgesRepo.Head memory head,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDirectKeeper returns(PledgesRepo.Head memory regHead)
    {
        regHead = _repo.issuePledge(
            head, 
            creditor, 
            monOfGuarantee,
            pledgedPaid,
            pledgedPar, 
            guaranteedAmt
        );

        emit CreatePledge(
            head.seqOfShare,
            head.seqOfPld,
            creditor,
            pledgedPaid,
            pledgedPar,
            guaranteedAmt
        );
    
        _getBOS().decreaseCleanAmt(regHead.seqOfShare, pledgedPaid, pledgedPar);

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
            pld.body.par, 
            pld.body.guaranteedAmt
        );
    
        _getBOS().decreaseCleanAmt(head.seqOfShare, pld.body.paid, pld.body.par);
    }

    function updatePledge(
        uint256 seqOfShare,
        uint256 seqOfPledge,
        uint40 creditor,
        uint48 expireDate,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDirectKeeper {

        require(
            expireDate > block.timestamp || expireDate == 0,
            "PR.UP: expireDate is passed"
        );

        PledgesRepo.Pledge storage pld = _repo.pledges[seqOfShare][seqOfPledge];

        if (pledgedPaid < pld.body.paid ||
            pledgedPar < pld.body.par)
        {
            _getBOS().increaseCleanAmt(
                seqOfShare,
                pld.body.paid - pledgedPaid,
                pld.body.par - pledgedPar
            );
        } else if (pledgedPaid > pld.body.paid ||
                   pledgedPar > pld.body.par)
        {
            _getBOS().decreaseCleanAmt(
                seqOfShare,
                pledgedPaid - pld.body.paid,
                pledgedPar - pld.body.par 
            );
        }

        emit UpdatePledge(
            seqOfShare, 
            seqOfPledge, 
            creditor, 
            expireDate,
            pledgedPaid, 
            pledgedPar,
            guaranteedAmt
        );

        pld.updatePledge(creditor, expireDate, pledgedPaid, pledgedPar, guaranteedAmt);
    }

    //##################
    //##    读接口    ##
    //##################

    function counterOfPledges(uint256 seqOfShare) 
        public view 
        returns (uint32) 
    {
        return _repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    function isPledge(uint256 seqOfShare, uint256 seqOfPledge) 
        external view returns (bool) {
        return _repo.pledges[seqOfShare][seqOfPledge].head.createDate > 0;
    }

    function getPledge(uint256 seqOfShare, uint256 seqOfPledge)
        public
        view
        returns (PledgesRepo.Pledge memory pld)
    {
        pld = _repo.pledges[seqOfShare][seqOfPledge];
    }

    function getPledgesOfShare(uint256 seqOfShare) 
        external view 
        returns (PledgesRepo.Pledge[] memory) 
    {
        return _repo.getPledgesOfShare(seqOfShare);
    }

    function getSnList() external view
        returns(uint256[] memory records)
    {
        records = _repo.getSnList();
    }
}

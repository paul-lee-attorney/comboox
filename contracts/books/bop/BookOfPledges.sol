// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfPledges.sol";

import "../../common/access/AccessControl.sol";
import "../../common/lib/PledgesRepo.sol";

contract BookOfPledges is IBookOfPledges, AccessControl {
    using PledgesRepo for PledgesRepo.Repo;
    using PledgesRepo for PledgesRepo.Pledge;

    PledgesRepo.Repo private _repo;

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        PledgesRepo.Head memory head,
        uint256 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDirectKeeper {

        head = _repo.createPledge(
                head, 
                creditor, 
                monOfGuarantee,
                pledgedPaid,
                pledgedPar, 
                guaranteedAmt
            );

        emit CreatePledge(
            head.seqOfShare,
            head.seqOfPledge,
            creditor,
            pledgedPaid,
            pledgedPar,
            guaranteedAmt
        );
    }

    function regPledge(
        PledgesRepo.Pledge memory pld
    ) external onlyKeeper {
        PledgesRepo.Head memory head = _repo.regPledge(pld);

        emit CreatePledge(
            head.seqOfShare, 
            head.seqOfPledge, 
            pld.body.creditor,
            pld.body.pledgedPaid, 
            pld.body.pledgedPar, 
            pld.body.guaranteedAmt
        );

    }

    function updatePledge(
        uint256 seqOfShare,
        uint256 seqOfPledge,
        uint256 creditor,
        uint48 expireDate,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDirectKeeper {

        require(
            expireDate > block.timestamp || expireDate == 0,
            "PR.UP: expireDate is passed"
        );

        _repo.pledges[seqOfShare][seqOfPledge].
            updatePledge(creditor, expireDate, pledgedPaid, pledgedPar, guaranteedAmt);

        emit UpdatePledge(
            seqOfShare, 
            seqOfPledge, 
            creditor, 
            expireDate,
            pledgedPaid, 
            pledgedPar,
            guaranteedAmt
        );

    }

    //##################
    //##    读接口    ##
    //##################

    function counterOfPledges(uint256 seqOfShare) 
        public view 
        returns (uint32) 
    {
        return _repo.pledges[seqOfShare][0].head.seqOfPledge;
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

    function pledgesOfShare(uint256 seqOfShare) 
        external view 
        returns (PledgesRepo.Pledge[] memory) 
    {
        return _repo.pledgesOfShare(seqOfShare);
    }
}

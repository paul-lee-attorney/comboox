// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/PledgesRepo.sol";

interface IBookOfPledges {

    //##################
    //##    Event     ##
    //##################

    event CreatePledge(
        uint256 indexed seqOfShare,
        uint256 seqOfPledge,
        uint256 creditor,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    );

    event UpdatePledge(
        uint256 indexed seqOfShare,
        uint256 seqOfPledge,
        uint256 creditor,
        uint48 expireDate,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    );

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
    ) external returns(PledgesRepo.Head memory head);

    function issuePledge(
        PledgesRepo.Head memory head,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external returns(PledgesRepo.Head memory issuedHead);

    function regPledge(
        PledgesRepo.Pledge memory pld
    ) external returns(PledgesRepo.Head memory head);

    function updatePledge(
        uint256 seqOfShare,
        uint256 seqOfPledge,
        uint40 creditor,
        uint48 expireDate,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function counterOfPledges(uint256 seqOfShare) external view returns (uint32);

    function isPledge(uint256 seqOfShare, uint256 seqOfPledge) external view returns (bool);

    function getPledge(uint256 seqOfShare, uint256 seqOfPledge)
        external
        view
        returns (
            PledgesRepo.Pledge memory pld
        );

    function getPledgesOfShare(uint256 seqOfShare) external view returns (PledgesRepo.Pledge[] memory);

    function getSnList() external view
        returns(uint256[] memory records);

}

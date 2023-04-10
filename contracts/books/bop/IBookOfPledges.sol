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
        uint256 seqOfPld,
        uint256 creditor,
        uint256 paid,
        uint256 par
    );

    event TransferPledge(
        uint256 indexed seqOfShare,
        uint256 seqOfPld,
        uint256 newSeqOfPld,
        uint256 buyer,
        uint256 paid,
        uint256 par
    );

    event RefundDebt(
        uint256 indexed seqOfShare,
        uint256 seqOfPld,
        uint256 refundAmt
    );

    event ExtendPledge(
        uint256 indexed seqOfShare,
        uint256 seqOfPld,
        uint256 extDays
    );

    event LockPledge(uint256 indexed seqOfShare, uint256 seqOfPld, bytes32 hashLock);

    event ReleasePledge(uint256 indexed seqOfShare, uint256 seqOfPld, string hashKey);

    event ExecPledge(uint256 indexed seqOfShare, uint256 seqOfPld);

    event RevokePledge(uint256 indexed seqOfShare, uint256 seqOfPld);

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        uint256 sn,
        uint creditor,
        uint guaranteeDays,
        uint paid,
        uint par,
        uint guaranteedAmt
    ) external returns(PledgesRepo.Head memory head);

    function issuePledge(
        PledgesRepo.Head memory head,
        uint creditor,
        uint guaranteeDays,
        uint paid,
        uint par,
        uint guaranteedAmt
    ) external returns(PledgesRepo.Head memory regHead);

    function regPledge(
        PledgesRepo.Pledge memory pld
    ) external returns(PledgesRepo.Head memory head);

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt
    ) external returns (PledgesRepo.Pledge memory newPld);

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt
    ) external returns (PledgesRepo.Pledge memory newPld);

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays
    ) external;

    // ==== Lock/Release/Exec/Revoke ====

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock
    ) external returns (bool flag);

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey)
        external returns (bool flag);

    function execPledge(uint256 seqOfShare, uint256 seqOfPld)
        external returns (bool flag);

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld)
        external returns (bool flag); 

    //##################
    //##    读接口    ##
    //##################

    function counterOfPledges(uint256 seqOfShare) 
        external view returns (uint16);

    function isPledge(uint256 seqOfShare, uint256 seqOfPld) 
        external view returns (bool);

    function getPledge(uint256 seqOfShare, uint256 seqOfPld)
        external view returns (PledgesRepo.Pledge memory pld);

    function getPledgesOfShare(uint256 seqOfShare) 
        external view returns (PledgesRepo.Pledge[] memory);

    function getSNList() external view
        returns(uint256[] memory list);

}

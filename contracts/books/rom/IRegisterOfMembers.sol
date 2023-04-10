// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/Checkpoints.sol";
import "../../common/lib/EnumerableSet.sol"; 
import "../../common/lib/MembersRepo.sol";
import "../../common/lib/SharesRepo.sol";
import "../../common/lib/TopChain.sol";

interface IRegisterOfMembers {
    //##################
    //##    Event     ##
    //##################

    event SetVoteBase(bool basedOnPar);

    event CapIncrease(uint paid, uint par);

    event CapDecrease(uint paid, uint par);

    event SetMaxQtyOfMembers(uint max);

    event SetAmtBase(bool basedOnPar);

    event AddMember(uint256 indexed acct, uint32 qtyOfMembers);

    event AddShareToMember(uint32 indexed seqOfShare, uint40 indexed acct);

    event RemoveShareFromMember(uint32 indexed seqOfShare, uint40 indexed acct);

    event ChangeAmtOfMember(
        uint indexed acct,
        uint paid,
        uint par,
        bool increase
    );

    // event DecreaseAmountFromMember(
    //     uint40 indexed acct,
    //     uint64 paid,
    //     uint64 par,
    //     uint64 blocknumber
    // );

    event AddMemberToGroup(uint indexed acct, uint indexed root);

    event RemoveMemberFromGroup(uint256 indexed acct, uint256 indexed root);

    event ChangeGroupRep(uint256 indexed orgRep, uint256 indexed newRep);

    //##################
    //##    写接口    ##
    //##################

    function setVoteBase(bool onPar) external;

    function capIncrease(uint paid, uint par) external;

    function capDecrease(uint paid, uint par) external;

    function setMaxQtyOfMembers(uint max) external;

    function setAmtBase(bool basedOnPar) external;

    function addMember(uint256 acct) external;

    function addShareToMember(SharesRepo.Share memory share) external;

    function removeShareFromMember(SharesRepo.Share memory share) external;

    function changeAmtOfMember(
        uint acct,
        uint deltaPaid,
        uint deltaPar,
        bool decrease
    ) external;

    function addMemberToGroup(uint acct, uint root) external;

    function removeMemberFromGroup(uint256 acct, uint256 root) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function basedOnPar() external view returns (bool);

    function maxQtyOfMembers() external view returns (uint32);

    function ownersEquity() external view returns(Checkpoints.Checkpoint memory cap);

    function capAtDate(uint date) external view
        returns (Checkpoints.Checkpoint memory cap);

    function totalVotes() external view returns (uint64);

    function sharesList() external view returns (uint256[] memory);

    function isSeqOfShare(uint256 seqOfShare) external view returns (bool);

    // ==== Member ====

    function isMember(uint256 acct) external view returns (bool);

    function sharesClipOfMember(uint256 acct) external view 
        returns (Checkpoints.Checkpoint memory clip);

    function votesInHand(uint256 acct) external view returns (uint64);

    function votesAtDate(uint256 acct, uint date) external view
        returns (uint64);

    function sharesInHand(uint256 acct) external view returns (uint256[] memory);

    function groupRep(uint256 acct) external view returns (uint40);

    function getNumOfMembers() external view returns (uint32);

    function membersList() external view returns (uint256[] memory);

    function affiliated(uint256 acct1, uint256 acct2) external view
        returns (bool);
    
    function isClassMember(uint256 acct, uint class)
        external view returns(bool flag);

    function getMembersOfClass(uint class)
        external view returns(uint256[] memory members);

    // ==== group ====

    function isGroupRep(uint256 acct) external view returns (bool);

    function qtyOfGroups() external view returns (uint256);

    function controllor() external view returns (uint40);

    function votesOfController() external view returns (uint64);

    function votesOfGroup(uint256 acct) external view returns (uint64);

    function membersOfGroup(uint256 acct) external view
        returns (uint256[] memory);

    function deepOfGroup(uint256 acct) external view returns (uint256);

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory);
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../lib/Checkpoints.sol";
import "../../../lib/EnumerableSet.sol"; 
import "../../../lib/MembersRepo.sol";
import "../../../lib/SharesRepo.sol";
import "../../../lib/TopChain.sol";

interface IRegisterOfMembers {
    //##################
    //##    Event     ##
    //##################

    event SetVoteBase(bool indexed basedOnPar);

    event CapIncrease(uint indexed paid, uint indexed par);

    event CapDecrease(uint indexed paid, uint indexed par);

    event SetMaxQtyOfMembers(uint indexed max);

    event SetAmtBase(bool indexed basedOnPar);

    event AddMember(uint256 indexed acct, uint indexed qtyOfMembers);

    event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

    event RemoveShareFromMember(uint indexed seqOfShare, uint indexed acct);

    event ChangeAmtOfMember(
        uint indexed acct,
        uint indexed paid,
        uint indexed par,
        uint clean,
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
    //##  Write I/O  ##
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
        uint deltaClean,
        bool decrease
    ) external;

    function addMemberToGroup(uint acct, uint root) external;

    function removeMemberFromGroup(uint256 acct, uint256 root) external;

    // ##############
    // ##   Read   ##
    // ##############

    function basedOnPar() external view returns (bool);

    function maxQtyOfMembers() external view returns (uint32);

    function ownersEquity() external view returns(Checkpoints.Checkpoint memory cap);

    function capAtDate(uint date) external view
        returns (Checkpoints.Checkpoint memory cap);

    function totalVotes() external view returns (uint64);

    function sharesList() external view returns (bytes32[] memory);

    function isSNOfShare(bytes32 sharenumber) external view returns (bool);

    // ==== Member ====

    function isMember(uint256 acct) external view returns (bool);

    function sharesClipOfMember(uint256 acct) external view 
        returns (Checkpoints.Checkpoint memory clip);

    function votesInHand(uint256 acct) external view returns (uint64);

    function votesAtDate(uint256 acct, uint date) external view
        returns (uint64);

    function sharesInHand(uint256 acct) external view returns (bytes32[] memory);

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

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/TopChain.sol";
import "../../common/lib/Checkpoints.sol";

interface IRegisterOfMembers {
    //##################
    //##    Event     ##
    //##################

    event SetVoteBase(bool basedOnPar);

    event CapIncrease(uint64 paid, uint64 par);

    event CapDecrease(uint64 paid, uint64 par);

    event SetMaxQtyOfMembers(uint32 max);

    event SetAmtBase(bool basedOnPar);

    event AddMember(uint256 indexed acct, uint32 qtyOfMembers);

    // event RemoveMember(uint40 indexed acct, uint32 qtyOfMembers);

    event AddShareToMember(uint32 indexed seqOfShare, uint40 indexed acct);

    event RemoveShareFromMember(uint32 indexed seqOfShare, uint40 indexed acct);

    event ChangeAmtOfMember(
        uint40 indexed acct,
        uint64 paid,
        uint64 par,
        bool increase
    );

    event DecreaseAmountFromMember(
        uint40 indexed acct,
        uint64 paid,
        uint64 par,
        uint64 blocknumber
    );

    event AddMemberToGroup(uint40 indexed acct, uint40 indexed root);

    event RemoveMemberFromGroup(uint256 indexed acct, uint256 indexed root);

    event ChangeGroupRep(uint256 indexed orgRep, uint256 indexed newRep);

    //##################
    //##    写接口    ##
    //##################

    function setVoteBase(bool onPar) external;

    function capIncrease(uint64 paid, uint64 par) external;

    function capDecrease(uint64 paid, uint64 par) external;

    function setMaxQtyOfMembers(uint32 max) external;

    function setAmtBase(bool basedOnPar) external;

    function addMember(uint256 acct) external;

    function addShareToMember(uint32 ssn, uint40 acct) external;

    function removeShareFromMember(uint32 ssn, uint40 acct) external;

    function changeAmtOfMember(
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool decrease
    ) external;

    function addMemberToGroup(uint40 acct, uint40 root) external;

    function removeMemberFromGroup(uint256 acct, uint256 root) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function basedOnPar() external view returns (bool);

    function maxQtyOfMembers() external view returns (uint32);

    function ownersEquity() external view returns(Checkpoints.Checkpoint memory cap);

    // function paidCap() external view returns (uint64);

    // function parCap() external view returns (uint64);

    function capAtDate(uint48 date)
        external
        view
        returns (Checkpoints.Checkpoint memory cap);

    function totalVotes() external view returns (uint64);

    function sharesList() external view returns (uint256[] memory);

    function isSeqOfShare(uint256 seqOfShare) external view returns (bool);

    function isMember(uint256 acct) external view returns (bool);

    function sharesClipOfMember(uint256 acct) external view returns (Checkpoints.Checkpoint memory clip);

    // function parOfMember(uint40 acct) external view returns (uint64 par);

    function votesInHand(uint256 acct) external view returns (uint64);

    function votesAtDate(uint256 acct, uint48 date)
        external
        view
        returns (uint64);

    function sharesInHand(uint256 acct) external view returns (uint256[] memory);

    function groupRep(uint256 acct) external view returns (uint256);

    function qtyOfMembers() external view returns (uint32);

    function membersList() external view returns (uint256[] memory);

    function affiliated(uint256 acct1, uint256 acct2)
        external
        view
        returns (bool);

    // ==== group ====

    function isGroupRep(uint256 acct) external view returns (bool);

    function qtyOfGroups() external view returns (uint32);

    function controllor() external view returns (uint40);

    function votesOfController() external view returns (uint64);

    function votesOfGroup(uint256 acct) external view returns (uint64);

    function membersOfGroup(uint256 acct)
        external
        view
        returns (uint256[] memory);

    function deepOfGroup(uint256 acct) external view returns (uint32);

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory);
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/TopChain.sol";

interface IRegisterOfMembers {
    //##################
    //##    Event     ##
    //##################

    event SetVoteBase(bool basedOnPar);

    event CapIncrease(uint64 paid, uint64 par, uint64 blocknumber);

    event CapDecrease(uint64 paid, uint64 par, uint64 blocknumber);

    event SetMaxQtyOfMembers(uint8 max);

    event SetAmtBase(bool basedOnPar);

    event AddMember(uint40 indexed acct, uint32 qtyOfMembers);

    event RemoveMember(uint40 indexed acct, uint32 qtyOfMembers);

    event AddShareToMember(bytes32 indexed sharenumber, uint40 indexed acct);

    event RemoveShareFromMember(bytes32 indexed sn, uint40 indexed acct);

    event ChangeAmtOfMember(
        uint40 indexed acct,
        uint64 paid,
        uint64 par,
        bool increase,
        uint64 blocknumber
    );

    event DecreaseAmountFromMember(
        uint40 indexed acct,
        uint64 paid,
        uint64 par,
        uint64 blocknumber
    );

    event AddMemberToGroup(uint40 indexed acct, uint40 indexed root);

    event RemoveMemberFromGroup(uint40 indexed acct, uint40 indexed root);

    event ChangeGroupRep(uint40 indexed orgRep, uint40 indexed newRep);

    //##################
    //##    写接口    ##
    //##################

    function setVoteBase(bool onPar) external;

    function capIncrease(uint64 paid, uint64 par) external;

    function capDecrease(uint64 paid, uint64 par) external;

    function setMaxQtyOfMembers(uint8 max) external;

    function setAmtBase(bool basedOnPar) external;

    function addMember(uint40 acct) external;

    function addShareToMember(uint32 ssn, uint40 acct) external;

    function removeShareFromMember(uint32 ssn, uint40 acct) external;

    function changeAmtOfMember(
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool decrease
    ) external;

    function addMemberToGroup(uint40 acct, uint40 root) external;

    function removeMemberFromGroup(uint40 acct, uint40 root) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    function basedOnPar() external view returns (bool);

    function maxQtyOfMembers() external view returns (uint32);

    function paidCap() external view returns (uint64);

    function parCap() external view returns (uint64);

    function capAtDate(uint48 date)
        external
        view
        returns (uint64, uint64);

    function totalVotes() external view returns (uint64);

    function sharesList() external view returns (bytes32[] memory);

    function isShareNumber(bytes32 sharenumbre) external view returns (bool);

    function isMember(uint40 acct) external view returns (bool);

    function paidOfMember(uint40 acct) external view returns (uint64 paid);

    function parOfMember(uint40 acct) external view returns (uint64 par);

    function votesInHand(uint40 acct) external view returns (uint64);

    function votesAtDate(uint256 acct, uint48 date)
        external
        view
        returns (uint64);

    function sharesInHand(uint40 acct) external view returns (bytes32[] memory);

    function groupRep(uint40 acct) external view returns (uint40);

    function qtyOfMembers() external view returns (uint32);

    function membersList() external view returns (uint40[] memory);

    function affiliated(uint40 acct1, uint40 acct2)
        external
        view
        returns (bool);

    // ==== group ====

    function isGroupRep(uint40 acct) external view returns (bool);

    function qtyOfGroups() external view returns (uint32);

    function controllor() external view returns (uint40);

    function votesOfController() external view returns (uint64);

    function votesOfGroup(uint40 acct) external view returns (uint64);

    function membersOfGroup(uint40 acct)
        external
        view
        returns (uint40[] memory);

    function deepOfGroup(uint40 acct) external view returns (uint32);

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory);
}

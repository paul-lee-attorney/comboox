// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "../../../lib/Checkpoints.sol";
import "../../../lib/MembersRepo.sol";
import "../../../lib/SharesRepo.sol";
import "../../../lib/TopChain.sol";
import "../../../lib/InterfacesHub.sol";

/// @title IRegisterOfMembers
/// @notice Interface for member registry, votes, and grouping.
interface IRegisterOfMembers {
    //##################
    //##    Event     ##
    //##################

    /// @notice Emitted when vote base is updated.
    /// @param basedOnPar True if vote base is par amount.
    event SetVoteBase(bool indexed basedOnPar);

    /// @notice Emitted when capital base is increased.
    /// @param votingWeight Voting weight delta.
    /// @param paid Paid amount delta.
    /// @param par Par amount delta.
    /// @param distrWeight Distribution weight delta.
    event CapIncrease(uint indexed votingWeight, uint indexed paid, uint indexed par, uint distrWeight);

    /// @notice Emitted when capital base is decreased.
    /// @param votingWeight Voting weight delta.
    /// @param paid Paid amount delta.
    /// @param par Par amount delta.
    /// @param distrWeight Distribution weight delta.
    event CapDecrease(uint indexed votingWeight, uint indexed paid, uint indexed par, uint distrWeight);

    /// @notice Emitted when maximum member count is updated.
    /// @param max Maximum count.
    event SetMaxQtyOfMembers(uint indexed max);

    /// @notice Emitted when minimum on-chain vote ratio is updated.
    /// @param min Minimum ratio.
    event SetMinVoteRatioOnChain(uint indexed min);

    /// @notice Emitted when amount base is updated.
    /// @param basedOnPar True if amount base is par amount.
    event SetAmtBase(bool indexed basedOnPar);

    /// @notice Emitted when a member is added.
    /// @param acct Member account.
    /// @param qtyOfMembers New member count.
    event AddMember(uint256 indexed acct, uint indexed qtyOfMembers);

    /// @notice Emitted when a share is linked to a member.
    /// @param seqOfShare Share sequence.
    /// @param acct Member account.
    event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

    /// @notice Emitted when a share is removed from a member.
    /// @param seqOfShare Share sequence.
    /// @param acct Member account.
    event RemoveShareFromMember(uint indexed seqOfShare, uint indexed acct);

    /// @notice Emitted when member amounts are changed.
    /// @param acct Member account.
    /// @param paid Paid amount delta.
    /// @param par Par amount delta.
    /// @param increase True if increased, false if decreased.
    event ChangeAmtOfMember(
        uint indexed acct,
        uint indexed paid,
        uint indexed par,
        bool increase
    );

    /// @notice Emitted when a member is added to a group.
    /// @param acct Member account.
    /// @param root Group root account.
    event AddMemberToGroup(uint indexed acct, uint indexed root);

    /// @notice Emitted when a member is removed from a group.
    /// @param acct Member account.
    /// @param root Group root account.
    event RemoveMemberFromGroup(uint256 indexed acct, uint256 indexed root);

    /// @notice Emitted when group representative changes.
    /// @param orgRep Original representative account.
    /// @param newRep New representative account.
    event ChangeGroupRep(uint256 indexed orgRep, uint256 indexed newRep);

    //#################
    //##  Write I/O  ##
    //#################

    /// @notice Set maximum number of members.
    /// @param max Max member count.
    function setMaxQtyOfMembers(uint max) external;

    /// @notice Set minimum vote ratio required on chain.
    /// @param min Ratio (0-4999).
    function setMinVoteRatioOnChain(uint min) external;

    /// @notice Set vote base to par or paid.
    /// @param _basedOnPar True for par-based votes.
    function setVoteBase(bool _basedOnPar) external;

    /// @notice Increase/decrease capital base.
    /// @param votingWeight Voting weight (%).
    /// @param distrWeight Distribution weight (%).
    /// @param paid Paid amount.
    /// @param par Par amount.
    /// @param isIncrease True to increase, false to decrease.
    function capIncrease(
        uint votingWeight, 
        uint distrWeight,
        uint paid, 
        uint par, 
        bool isIncrease
    ) external;

    /// @notice Add a member.
    /// @param acct Member user number.
    function addMember(uint256 acct) external;

    /// @notice Link a share to its member owner.
    /// @param share Share record.
    function addShareToMember(
        SharesRepo.Share memory share
    ) external;

    /// @notice Unlink a share from its member owner.
    /// @param share Share record.
    function removeShareFromMember(
        SharesRepo.Share memory share
    ) external;

    /// @notice Update member votes and points.
    /// @param acct Member user number.
    /// @param votingWeight Voting weight (%).
    /// @param distrWeight Distribution weight (%).
    /// @param deltaPaid Paid delta.
    /// @param deltaPar Par delta.
    /// @param isIncrease True to increase, false to decrease.
    function increaseAmtOfMember(
        uint acct,
        uint votingWeight,
        uint distrWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) external ;

    /// @notice Group a member under a root.
    /// @param acct Member user number.
    /// @param root Root member user number.
    function addMemberToGroup(uint acct, uint root) external;

    /// @notice Remove a member from group.
    /// @param acct Member user number.
    function removeMemberFromGroup(uint256 acct) external;

    /// @notice Restore shares in ROM.
    /// @param shares Share list.
    function restoreSharesInRom(SharesRepo.Share[] memory shares) external;

    /// @notice Restore top chain state.
    /// @param list Node list.
    /// @param para Chain parameters.
    function restoreTopChainInRom(TopChain.Node[] memory list, TopChain.Para memory para) external;

    /// @notice Restore vote history for a member.
    /// @param acct Member user number.
    /// @param list Checkpoint list.
    /// @param distrPts Distribution points checkpoint.
    function restoreVotesHistoryInRom(
        uint acct, Checkpoints.Checkpoint[] memory list,
        Checkpoints.Checkpoint memory distrPts
    ) external;

    // ##############
    // ##   Read   ##
    // ##############

    /// @notice Check whether a user is member.
    /// @param acct User number.
    /// @return True if member.
    function isMember(uint256 acct) external view returns (bool);

    /// @notice Get total member count.
    /// @return Member count.
    function qtyOfMembers() external view returns (uint);

    /// @notice Get member list.
    /// @return Member user numbers.
    function membersList() external view returns (uint256[] memory);

    /// @notice Get sorted member list.
    /// @return Sorted member user numbers.
    function sortedMembersList() external view returns (uint256[] memory);

    /// @notice Get top-level member count.
    /// @return Count.
    function qtyOfTopMembers() external view returns (uint);

    /// @notice Get top-level member list.
    /// @return Member user numbers.
    function topMembersList() external view returns (uint[] memory);

    // ---- Cap & Equity ----

    /// @notice Get owners' equity checkpoint.
    /// @return Equity checkpoint.
    function ownersEquity() external view 
        returns(Checkpoints.Checkpoint memory);

    /// @notice Get owners' distribution points.
    /// @return Points checkpoint.
    function ownersPoints() external view 
        returns(Checkpoints.Checkpoint memory);

    /// @notice Get capital at date.
    /// @param date Timestamp.
    /// @return Checkpoint at date.
    function capAtDate(uint date) external view
        returns (Checkpoints.Checkpoint memory);

    /// @notice Get owners' equity history.
    /// @return Checkpoint history.
    function ownersEquityHistory() external view 
        returns (Checkpoints.Checkpoint[] memory);

   /// @notice Get member equity.
   /// @param acct Member user number.
   /// @return Equity checkpoint.
   function equityOfMember(uint256 acct) external view
       returns (Checkpoints.Checkpoint memory);

   /// @notice Get member distribution points.
   /// @param acct Member user number.
   /// @return Points checkpoint.
   function pointsOfMember(uint256 acct) external view
       returns (Checkpoints.Checkpoint memory);

    /// @notice Get member equity at date.
    /// @param acct Member user number.
    /// @param date Timestamp.
    /// @return Equity checkpoint.
    function equityAtDate(uint acct, uint date) 
        external view returns(Checkpoints.Checkpoint memory);

    /// @notice Get member current votes.
    /// @param acct Member user number.
    /// @return Votes.
    function votesInHand(uint256 acct)
        external view returns (uint64);

    /// @notice Get member votes at date.
    /// @param acct Member user number.
    /// @param date Timestamp.
    /// @return Votes.
    function votesAtDate(uint256 acct, uint date)
        external view
        returns (uint64);

    /// @notice Get vote history of member.
    /// @param acct Member user number.
    /// @return Checkpoint history.
    function votesHistory(uint acct)
        external view 
        returns (Checkpoints.Checkpoint[] memory);

    // ---- ShareNum ----

    /// @notice Get number of shares held by member.
    /// @param acct Member user number.
    /// @return Share count.
    function qtyOfSharesInHand(uint acct)
        external view returns(uint);
    
    /// @notice Get shares held by member.
    /// @param acct Member user number.
    /// @return Share list.
    function sharesInHand(uint256 acct)
        external view
        returns (uint[] memory);

    // ---- Class ---- 

    /// @notice Get number of shares in class held by member.
    /// @param acct Member user number.
    /// @param class Share class id.
    /// @return Share count.
    function qtyOfSharesInClass(uint acct, uint class)
        external view returns(uint);

    /// @notice Get shares in class held by member.
    /// @param acct Member user number.
    /// @param class Share class id.
    /// @return Share list.
    function sharesInClass(uint256 acct, uint class)
        external view returns (uint[] memory);

    /// @notice Check if member belongs to class.
    /// @param acct Member user number.
    /// @param class Share class id.
    /// @return True if belongs.
    function isClassMember(uint256 acct, uint class)
        external view returns(bool);

    /// @notice Get classes a member belongs to.
    /// @param acct Member user number.
    /// @return Class ids.
    function classesBelonged(uint acct)
        external view returns(uint[] memory);

    /// @notice Get member count in a class.
    /// @param class Share class id.
    /// @return Member count.
    function qtyOfClassMember(uint class)
        external view returns(uint);

    /// @notice Get members of a class.
    /// @param class Share class id.
    /// @return Member list.
    function getMembersOfClass(uint class)
        external view returns(uint256[] memory);
 
    // ---- TopChain ----

    /// @notice Check whether votes are based on par.
    /// @return True if based on par.
    function basedOnPar() external view returns (bool);

    /// @notice Get max member count.
    /// @return Max count.
    function maxQtyOfMembers() external view returns (uint32);

    /// @notice Get min vote ratio on chain.
    /// @return Ratio value.
    function minVoteRatioOnChain() external view returns (uint32);

    /// @notice Get total votes.
    /// @return Vote sum.
    function totalVotes() external view returns (uint64);

    /// @notice Get controller user number.
    /// @return Controller user number.
    function controllor() external view returns (uint40);

    /// @notice Get tail of chain.
    /// @return Tail node id.
    function tailOfChain() external view returns (uint40);

    /// @notice Get head of queue.
    /// @return Head node id.
    function headOfQueue() external view returns (uint40);

    /// @notice Get tail of queue.
    /// @return Tail node id.
    function tailOfQueue() external view returns (uint40);

    // ==== group ====

    /// @notice Get group representative for member.
    /// @param acct Member user number.
    /// @return Representative user number.
    function groupRep(uint256 acct) external view returns (uint40);

    /// @notice Get total votes of a group.
    /// @param acct Group root user number.
    /// @return Vote sum.
    function votesOfGroup(uint256 acct) external view returns (uint64);

    /// @notice Get group depth.
    /// @param acct Group root user number.
    /// @return Depth value.
    function deepOfGroup(uint256 acct) external view returns (uint256);

    /// @notice Get members of a group.
    /// @param acct Group root user number.
    /// @return Member list.
    function membersOfGroup(uint256 acct)
        external view
        returns (uint256[] memory);

    /// @notice Get number of groups on chain.
    /// @return Group count.
    function qtyOfGroupsOnChain() external view returns (uint32);

    /// @notice Get total number of groups.
    /// @return Group count.
    function qtyOfGroups() external view returns (uint256);

    /// @notice Check if two accounts are affiliated.
    /// @param acct1 First user number.
    /// @param acct2 Second user number.
    /// @return True if affiliated.
    function affiliated(uint256 acct1, uint256 acct2)
        external view
        returns (bool);

    // ==== snapshot ====

    /// @notice Get top chain snapshot.
    /// @return Node list.
    /// @return Chain parameters.
    function getSnapshot() external view returns (TopChain.Node[] memory, TopChain.Para memory);
}

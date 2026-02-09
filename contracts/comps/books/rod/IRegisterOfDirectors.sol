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

pragma solidity ^0.8.8;

import "../../common/components/IMeetingMinutes.sol";

import "../../../lib/OfficersRepo.sol";
import "../../../lib/InterfacesHub.sol";


/// @title IRegisterOfDirectors
/// @notice Interface for managing director/officer positions and appointments.
/// @dev Provides write functions for position lifecycle and read queries for roles.
interface IRegisterOfDirectors {

    //###################
    //##    Events     ##
    //###################

    /// @notice Emitted when a position is created or updated.
    /// @param snOfPos Encoded position head (title/seq/nomination/term fields).
    event AddPosition(bytes32 indexed snOfPos);

    /// @notice Emitted when a position is removed.
    /// @param seqOfPos Position sequence number.
    event RemovePosition(uint256 indexed seqOfPos);

    /// @notice Emitted when a position is taken by an officer.
    /// @param seqOfPos Position sequence number.
    /// @param caller Officer account id.
    event TakePosition(uint256 indexed seqOfPos, uint256 indexed caller);

    /// @notice Emitted when an officer quits a position.
    /// @param seqOfPos Position sequence number.
    /// @param caller Officer account id.
    event QuitPosition(uint256 indexed seqOfPos, uint256 indexed caller);

    /// @notice Emitted when a position is vacated by removal.
    /// @param seqOfPos Position sequence number.
    event RemoveOfficer(uint256 indexed seqOfPos);

    //#################
    //##  Write I/O  ##
    //#################

    /// @notice Create a position using an encoded serial number.
    /// @param snOfPos Encoded position head (non-zero, valid fields).
    function createPosition(bytes32 snOfPos) external;

    /// @notice Update a position with explicit fields.
    /// @param pos Position struct (seqOfPos > 0, title > Shareholder, endDate > startDate).
    function updatePosition(OfficersRepo.Position memory pos) external;

    /// @notice Remove a vacant position.
    /// @param seqOfPos Position sequence number (> 0).
    function removePosition(uint256 seqOfPos) external;

    /// @notice Take an available position.
    /// @param seqOfPos Position sequence number (> 0).
    /// @param caller Officer account id (> 0).
    function takePosition (uint256 seqOfPos, uint caller) external;

    /// @notice Quit a position held by the caller.
    /// @param seqOfPos Position sequence number (> 0).
    /// @param caller Officer account id (> 0).
    function quitPosition (uint256 seqOfPos, uint caller) external; 

    /// @notice Vacate a position by removal.
    /// @param seqOfPos Position sequence number (> 0).
    function removeOfficer (uint256 seqOfPos) external;

    //################
    //##    Read    ##
    //################

    // ==== Positions ====

    /// @notice Check whether a position exists and is active.
    /// @param seqOfPos Position sequence number (> 0).
    /// @return True if exists.
    function posExist(uint256 seqOfPos) external view returns (bool);

    /// @notice Check whether a position is occupied.
    /// @param seqOfPos Position sequence number (> 0).
    /// @return True if occupied.
    function isOccupied(uint256 seqOfPos) external view returns (bool);

    /// @notice Get position details.
    /// @param seqOfPos Position sequence number (> 0).
    /// @return Position record.
    function getPosition(uint256 seqOfPos) external view 
        returns (OfficersRepo.Position memory);

    // ==== Managers ====

    /// @notice Check whether an account is a manager.
    /// @param acct Account id (> 0).
    /// @return True if manager.
    function isManager(uint256 acct) external view returns (bool);

    /// @notice Get number of managers.
    /// @return Count of managers.
    function getNumOfManagers() external view returns (uint256);    

    /// @notice Get manager account list.
    /// @return Manager user list.
    function getManagersList() external view returns (uint256[] memory);

    /// @notice Get manager position list.
    /// @return Position id list.
    function getManagersPosList() external view returns(uint[] memory);

    // ==== Directors ====

    /// @notice Check whether an account is a director.
    /// @param acct Account id (> 0).
    /// @return True if director.
    function isDirector(uint256 acct) external view returns (bool);

    /// @notice Get number of directors.
    /// @return Count of directors.
    function getNumOfDirectors() external view returns (uint256);

    /// @notice Get director account list.
    /// @return Director user list.
    function getDirectorsList() external view 
        returns (uint256[] memory);

    /// @notice Get director position list.
    /// @return Position id list.
    function getDirectorsPosList() external view 
        returns (uint256[] memory);

    // ==== Executives ====

    /// @notice Check whether an account holds a position.
    /// @param acct Account id (> 0).
    /// @param seqOfPos Position sequence number (> 0).
    /// @return True if holds.
    function hasPosition(uint256 acct, uint256 seqOfPos)
        external view returns(bool);

    /// @notice Get positions held by an account.
    /// @param acct Account id (> 0).
    /// @return Position id list.
    function getPosInHand(uint256 acct) 
        external view returns (uint256[] memory);

    /// @notice Get full position info held by an account.
    /// @param acct Account id (> 0).
    /// @return Position list.
    function getFullPosInfoInHand(uint acct) 
        external view returns (OfficersRepo.Position[] memory);

    /// @notice Check whether an account holds a title.
    /// @param acct Account id (> 0).
    /// @param title Title id (see OfficersRepo.TitleOfOfficers).
    /// @return flag True if holds.
    function hasTitle(uint acct, uint title) 
        external view returns (bool flag);

    /// @notice Check whether an account has nomination rights for a position.
    /// @param seqOfPos Position sequence number (> 0).
    /// @param acct Account id (> 0).
    /// @return True if has rights.
    function hasNominationRight(uint seqOfPos, uint acct) 
        external view returns (bool);

    // ==== seatsCalculator ====

    /// @notice Get number of board seats occupied under an account's nomination.
    /// @param acct Account id (> 0).
    /// @return Number of occupied seats.
    function getBoardSeatsOccupied(uint acct) external view 
        returns (uint256);
}

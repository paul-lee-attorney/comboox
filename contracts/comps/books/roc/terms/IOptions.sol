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

import "../../../../lib/books/OptionsRepo.sol";
import "../../../../openzeppelin/utils/structs/EnumerableSet.sol";

/// @title IOptions
/// @notice Interface for option term management and queries.
interface IOptions {
    
    // ################
    // ## Write I/O ##
    // ################

    /// @notice Create an option from encoded inputs.
    /// @param snOfOpt Option serial number.
    /// @param snOfCond Condition serial number.
    /// @param rightholder Rightholder account.
    /// @param paid Paid amount.
    /// @param par Par amount.
    /// @return head Option head.
    function createOption(
        bytes32 snOfOpt,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) external returns (OptionsRepo.Head memory head); 

    /// @notice Remove a pending option.
    /// @param seqOfOpt Option sequence number.
    /// @return flag True if removed.
    function delOption(uint256 seqOfOpt) external returns(bool flag);

    /// @notice Add an obligor to an option.
    /// @param seqOfOpt Option sequence number.
    /// @param obligor Account id.
    /// @return flag True if added.
    function addObligorIntoOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external returns (bool flag);

    /// @notice Remove an obligor from an option.
    /// @param seqOfOpt Option sequence number.
    /// @param obligor Account id.
    /// @return flag True if removed.
    function removeObligorFromOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external returns (bool flag);


    // ################
    // ##  Read I/O  ##
    // ################

    // ==== Option ====

    /// @notice Get the option counter.
    /// @return Counter value.
    function counterOfOptions() external view returns (uint32);

    /// @notice Get number of options.
    /// @return Count.
    function qtyOfOptions() external view returns (uint);

    /// @notice Check whether an option exists.
    /// @param seqOfOpt Option sequence number.
    /// @return True if exists.
    function isOption(uint256 seqOfOpt) external view returns (bool);

    /// @notice Get an option by sequence number.
    /// @param seqOfOpt Option sequence number.
    /// @return option Option record.
    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory option); 

    /// @notice Get all options.
    /// @return Option list.
    function getAllOptions() external view returns (OptionsRepo.Option[] memory);

    // ==== Obligor ====

    /// @notice Check whether an account is an obligor.
    /// @param seqOfOpt Option sequence number.
    /// @param acct Account id.
    /// @return True if obligor.
    function isObligor(uint256 seqOfOpt, uint256 acct) external 
        view returns (bool); 

    /// @notice Get obligors of an option.
    /// @param seqOfOpt Option sequence number.
    /// @return Obligor accounts.
    function getObligorsOfOption(uint256 seqOfOpt) external view
        returns (uint256[] memory);

    // ==== snOfOpt ====
    /// @notice Get list of option sequence numbers.
    /// @return Option ids.
    function getSeqList() external view returns(uint[] memory);

}

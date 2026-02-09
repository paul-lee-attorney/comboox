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

import "../roc/terms/IOptions.sol";
import "../../../lib/OptionsRepo.sol";
import "../../../lib/SwapsRepo.sol";
import "../../../lib/InterfacesHub.sol";

pragma solidity ^0.8.8;

/// @title IRegisterOfOptions
/// @notice Interface for options registry, execution, and swaps.
interface IRegisterOfOptions {

    // ################
    // ##   Event    ##
    // ################

    /// @notice Emitted when an option is created.
    /// @param seqOfOpt Option sequence.
    /// @param codeOfOpt Option code.
    event CreateOpt(uint256 indexed seqOfOpt, bytes32 indexed codeOfOpt);

    /// @notice Emitted when an option is issued.
    /// @param seqOfOpt Option sequence.
    /// @param issueDate Issue date (timestamp).
    event IssueOpt(uint256 indexed seqOfOpt, uint indexed issueDate);

    /// @notice Emitted when an obligor is added to an option.
    /// @param seqOfOpt Option sequence.
    /// @param obligor Obligor account.
    event AddObligorIntoOpt(uint256 indexed seqOfOpt, uint256 indexed obligor);

    /// @notice Emitted when an obligor is removed from an option.
    /// @param seqOfOpt Option sequence.
    /// @param obligor Obligor account.
    event RemoveObligorFromOpt(uint256 indexed seqOfOpt, uint256 indexed obligor);

    /// @notice Emitted when oracle data is updated for an option.
    /// @param seqOfOpt Option sequence.
    /// @param data1 Data slot 1.
    /// @param data2 Data slot 2.
    /// @param data3 Data slot 3.
    event UpdateOracle(uint256 indexed seqOfOpt, uint indexed data1, uint indexed data2, uint data3);

    /// @notice Emitted when an option is executed.
    /// @param seqOfOpt Option sequence.
    event ExecOpt(uint256 indexed seqOfOpt);

    /// @notice Emitted when a swap is registered for an option.
    /// @param seqOfOpt Option sequence.
    /// @param snOfSwap Swap serial number.
    event RegSwap(uint256 indexed seqOfOpt, bytes32 indexed snOfSwap);

    /// @notice Emitted when a swap is paid off.
    /// @param seqOfOpt Option sequence.
    /// @param snOfSwap Swap serial number.
    event PayOffSwap(uint256 indexed seqOfOpt, bytes32 indexed snOfSwap);

    /// @notice Emitted when a swap is terminated.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfSwap Swap sequence.
    event TerminateSwap(uint256 indexed seqOfOpt, uint indexed seqOfSwap);

    // ################
    // ##   Write    ##
    // ################

    /// @notice Create an option from encoded inputs.
    /// @param sn Packed option head.
    /// @param snOfCond Packed condition head.
    /// @param rightholder Rightholder user number.
    /// @param paid Paid amount.
    /// @param par Par amount.
    /// @return head Option head.
    function createOption(
        bytes32 sn,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) external returns(OptionsRepo.Head memory head);

    /// @notice Issue a prepared option.
    /// @param opt Option record.
    function issueOption(OptionsRepo.Option memory opt) external;

    /// @notice Register option terms contract.
    /// @param opts Options terms address.
    function regOptionTerms(address opts) external;

    /// @notice Add obligor to option.
    /// @param seqOfOpt Option sequence.
    /// @param obligor Obligor user number.
    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external;

    /// @notice Remove obligor from option.
    /// @param seqOfOpt Option sequence.
    /// @param obligor Obligor user number.
    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external;

    /// @notice Update oracle data for option.
    /// @param seqOfOpt Option sequence.
    /// @param d1 Data slot 1.
    /// @param d2 Data slot 2.
    /// @param d3 Data slot 3.
    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    /// @notice Execute an option.
    /// @param seqOfOpt Option sequence.
    /// @param caller Caller user number.
    function execOption(uint256 seqOfOpt, uint caller) external;

    /// @notice Create a swap for an option.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfTarget Target share sequence.
    /// @param paidOfTarget Paid target amount.
    /// @param seqOfPledge Pledge share sequence.
    /// @param caller Caller user number.
    /// @return swap Swap record.
    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller
    ) external returns (SwapsRepo.Swap memory swap);

    /// @notice Pay off a swap.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfSwap Swap sequence.
    /// @return swap Swap record.
    function payOffSwap(
        uint seqOfOpt,
        uint seqOfSwap
    ) external returns (SwapsRepo.Swap memory swap);

    /// @notice Terminate a swap.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfSwap Swap sequence.
    /// @return swap Swap record.
    function terminateSwap(
        uint seqOfOpt,
        uint seqOfSwap
    ) external returns (SwapsRepo.Swap memory swap);
    
    // ################
    // ##  Read I/O  ##
    // ################

    /// @notice Get option counter.
    /// @return Counter value.
    function counterOfOptions() external view returns (uint32);

    /// @notice Get number of options.
    /// @return Count.
    function qtyOfOptions() external view returns (uint);

    /// @notice Check whether an option exists.
    /// @param seqOfOpt Option sequence.
    /// @return True if exists.
    function isOption(uint256 seqOfOpt) external view returns (bool);

    /// @notice Get option by sequence.
    /// @param seqOfOpt Option sequence.
    /// @return opt Option record.
    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory opt);

    /// @notice Get all options.
    /// @return Option list.
    function getAllOptions() external view returns (OptionsRepo.Option[] memory);

    /// @notice Check if account is rightholder.
    /// @param seqOfOpt Option sequence.
    /// @param acct User number.
    /// @return True if rightholder.
    function isRightholder(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    /// @notice Check if account is obligor.
    /// @param seqOfOpt Option sequence.
    /// @param acct User number.
    /// @return True if obligor.
    function isObligor(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    /// @notice Get obligors of an option.
    /// @param seqOfOpt Option sequence.
    /// @return Obligor list.
    function getObligorsOfOption(uint256 seqOfOpt)
        external view returns (uint256[] memory);

    /// @notice Get option sequence list.
    /// @return Option ids.
    function getSeqListOfOptions() external view returns(uint[] memory);

    // ==== Swap ====
    /// @notice Get swap counter for option.
    /// @param seqOfOpt Option sequence.
    /// @return Counter value.
    function counterOfSwaps(uint256 seqOfOpt)
        external view returns (uint16);

    /// @notice Get total paid target amount.
    /// @param seqOfOpt Option sequence.
    /// @return Paid sum.
    function sumPaidOfTarget(uint256 seqOfOpt)
        external view returns (uint64);

    /// @notice Check if swap exists.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfSwap Swap sequence.
    /// @return True if exists.
    function isSwap(uint256 seqOfOpt, uint256 seqOfSwap)
        external view returns (bool); 

    /// @notice Get swap by sequence.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfSwap Swap sequence.
    /// @return swap Swap record.
    function getSwap(uint256 seqOfOpt, uint256 seqOfSwap)
        external view returns (SwapsRepo.Swap memory swap);

    /// @notice Get all swaps of an option.
    /// @param seqOfOpt Option sequence.
    /// @return Swap list.
    function getAllSwapsOfOption(uint256 seqOfOpt)
        external view returns (SwapsRepo.Swap[] memory);

    /// @notice Check whether all swaps are closed.
    /// @param seqOfOpt Option sequence.
    /// @return True if all closed.
    function allSwapsClosed(uint256 seqOfOpt)
        external view returns (bool);

    // ==== oracles ====

    /// @notice Get oracle value at date.
    /// @param seqOfOpt Option sequence.
    /// @param date Timestamp.
    /// @return Oracle checkpoint.
    function getOracleAtDate(uint256 seqOfOpt, uint date)
        external view returns (Checkpoints.Checkpoint memory);

    /// @notice Get latest oracle value.
    /// @param seqOfOpt Option sequence.
    /// @return Oracle checkpoint.
    function getLatestOracle(uint256 seqOfOpt) external 
        view returns(Checkpoints.Checkpoint memory);

    /// @notice Get all oracle checkpoints of an option.
    /// @param seqOfOpt Option sequence.
    /// @return Checkpoint list.
    function getAllOraclesOfOption(uint256 seqOfOpt)
        external view returns (Checkpoints.Checkpoint[] memory);
    
}

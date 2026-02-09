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

import "../../../../lib/SharesRepo.sol";
import "../../../../lib/DealsRepo.sol";
import "../../../../lib/InterfacesHub.sol";
import "../../roa/IInvestmentAgreement.sol";
import "../../../../openzeppelin/utils/structs/EnumerableSet.sol";

/// @title IAntiDilution
/// @notice Interface for anti-dilution term management and checks.
interface IAntiDilution {

    /// @notice Floor price benchmark and obligors for a share class.
    struct Benchmark{
        uint16 classOfShare;
        uint32 floorPrice;
        EnumerableSet.UintSet obligors; 
    }

    /// @notice Repository of benchmarks keyed by share class.
    struct Ruler {
        // classOfShare => Benchmark
        mapping(uint256 => Benchmark) marks;
        // Set of benchmarked classes
        EnumerableSet.UintSet classes;        
    }

    // ################
    // ##   Write    ##
    // ################

    /// @notice Add or update a floor price benchmark for a class.
    /// @param class Share class id.
    /// @param price Floor price.
    function addBenchmark(uint256 class, uint price) external;

    /// @notice Remove a benchmark for a class.
    /// @param class Share class id.
    function removeBenchmark(uint256 class) external;

    /// @notice Add an obligor to a class.
    /// @param class Share class id.
    /// @param obligor Account id.
    function addObligor(uint256 class, uint256 obligor) external;

    /// @notice Remove an obligor from a class.
    /// @param class Share class id.
    /// @param obligor Account id.
    function removeObligor(uint256 class, uint256 obligor) external;

    // ############
    // ##  read  ##
    // ############

    /// @notice Check whether a class has a benchmark.
    /// @param class Share class id.
    /// @return flag True if marked.
    function isMarked(uint256 class) external view returns (bool flag);

    /// @notice Get all benchmarked classes.
    /// @return Class ids.
    function getClasses() external view returns (uint256[] memory);

    /// @notice Get floor price for a class.
    /// @param class Share class id.
    /// @return price Floor price.
    function getFloorPriceOfClass(uint256 class) external view
        returns (uint32 price);

    /// @notice Get obligors for a class.
    /// @param class Share class id.
    /// @return Obligor accounts.
    function getObligorsOfAD(uint256 class)
        external view returns (uint256[] memory);

    /// @notice Check whether an account is an obligor of a class.
    /// @param class Share class id.
    /// @param acct Account id.
    /// @return flag True if obligor.
    function isObligor(uint256 class, uint256 acct) 
        external view returns (bool flag);

    /// @notice Calculate anti-dilution gift paid for a deal and share.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence number.
    /// @param seqOfShare Share sequence number.
    /// @return gift Gift paid amount.
    function getGiftPaid(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external view returns (uint64 gift);

    /// @notice Check whether a deal triggers anti-dilution for a class.
    /// @param deal Deal data.
    /// @param seqOfShare Share class id.
    /// @return True if triggered.
    function isTriggered(DealsRepo.Deal memory deal, uint seqOfShare) external view returns (bool);
}

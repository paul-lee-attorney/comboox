// SPDX-License-Identifier: UNLICENSED

/* *
 *
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

import "../lib/books/UsersRepo.sol";
import "../openzeppelin/utils/Address.sol";

/// @title IGeneralKeeper
/// @notice General keeper interface for corporate registry configuration and role management.
/// @dev Exposes company info, keeper/book registration, and basic queries.
interface IGeneralKeeper {

    /// @notice Company information record.
    /// @dev `regNum` is userNo; `regDate` is unix timestamp; `symbol` is fixed-length bytes.
    struct CompInfo {
        uint40 regNum;
        uint48 regDate;
        uint8 typeOfEntity;
        uint8 currency;
        uint8 state;
        bytes18 symbol;
        string name;
    }

    /// @notice Company type enumeration.
    enum TypeOfEntity {
        ZeroPoint,
        PrivateCompany,
        GrowingCompany,
        ListedCompany,
        GeneralCompany,
        CloseFund,
        ListedCloseFund,
        OpenFund,
        ListedOpenFund,
        GeneralFund
    }

    // error GK_FallbackFuncNotReg(bytes4 sig);

    // ###############
    // ##   Event   ##
    // ###############

    /// @notice Emitted when a keeper is registered.
    /// @param title Keeper title.
    /// @param keeper Keeper address.
    /// @param dk Direct keeper address.
    event RegKeeper(uint indexed title, address indexed keeper, address indexed dk);

    /// @notice Emitted when a keeper's function selector is registered.
    /// @param sig Function selector (bytes4).
    /// @param title Keeper title.
    /// @param dk Direct keeper address.
    event RegSigToTitle(bytes4 indexed sig, uint indexed title, address indexed dk);

    /// @notice Emitted when a book is registered.
    /// @param title Book title.
    /// @param book Book address.
    /// @param dk Direct keeper address.
    event RegBook(uint indexed title, address indexed book, address indexed dk);

    /// @notice Emitted when an action batch is executed.
    /// @param actionHash Hash of the action batch.
    event ExecAction(bytes32 indexed actionHash);


    /// @notice Emitted when a call is forwarded to a keeper or book.
    /// @param target Target contract address.
    /// @param msgSender Original caller address.
    /// @param sig Function signature of the forwarded call.
    event ForwardedCall(address indexed target, address indexed msgSender, bytes4 indexed sig);

    /// @notice Emitted when ETH is received.
    /// @param sender ETH sender.
    /// @param amount ETH amount.
    event ReceivedEth(address indexed sender, uint amount);

    // ######################
    // ##   Configuration  ##
    // ######################

    // ---- Config ----

    /// @notice Create the corporate seal and register the entity in RegCenter.
    /// @param _typeOfEntity Entity type code (see {TypeOfEntity}).
    function createCorpSeal(uint _typeOfEntity) external;

    /// @notice Set company information.
    /// @param _currency Currency code (uint8, implementation-defined range).
    /// @param _symbol Fixed-length symbol (bytes18).
    /// @param _name Company name (non-empty string expected).
    function setCompInfo (
        uint8 _currency,
        bytes18 _symbol,
        string memory _name
    ) external;

    // function createCorpSeal() external;

    /// @notice Get company information.
    /// @return Company info record; fields are zeroed if unset.
    function getCompInfo() external view returns(CompInfo memory);

    /// @notice Get company user record from registry.
    /// @return User record (zeroed if not registered).
    function getCompUser() external view returns (UsersRepo.User memory);

    // ---- Keepers ----

    /// @notice Register a keeper address by title.
    /// @param title Keeper title (uint, expected > 0).
    /// @param keeper Keeper address (non-zero).
    function regKeeper(uint256 title, address keeper) external;

    /// @notice Register a function selector to a keeper title.
    /// @param sig Function selector (bytes4).
    /// @param title Keeper title (uint, expected > 0).
    function regSigToTitle(bytes4 sig,uint256 title) external;

    /// @notice Check if an address is a registered keeper.
    /// @param caller Address to check.
    /// @return flag True if registered; false otherwise.
    function isKeeper(address caller) external view returns (bool flag);

    /// @notice Get keeper address by title.
    /// @param title Keeper title (uint, expected > 0).
    /// @return keeper Keeper address (zero if not set).
    function getKeeper(uint256 title) external view returns(address keeper);

    /// @notice Get keeper title by address.
    /// @param keeper Keeper address.
    /// @return title Keeper title (0 if not registered).
    function getTitleOfKeeper(address keeper) external view returns (uint);

    // ---- Books ----

    /// @notice Register a book address by title.
    /// @param title Book title (uint, expected > 0).
    /// @param keeper Book address (non-zero).
    function regBook(uint256 title, address keeper) external;

    /// @notice Get book address by title.
    /// @param title Book title (uint, expected > 0).
    /// @return Book address (zero if not set).
    function getBook(uint256 title) external view returns (address);

}

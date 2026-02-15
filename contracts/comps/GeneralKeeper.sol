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

import "./IGeneralKeeper.sol";
import "./common/access/AccessControl.sol";
import "../openzeppelin/utils/Address.sol";
import "../lib/books/UsersRepo.sol";
import "../lib/InterfacesHub.sol";
import "../lib/keepers/KeepersRouter.sol";

contract GeneralKeeper is IGeneralKeeper, AccessControl {
    using Address for address;
    using InterfacesHub for address;
    using KeepersRouter for KeepersRouter.Repo;

    /// @notice Company registry info stored in this keeper.
    CompInfo internal _info;

    /// @notice Book registry (title => book address).
    mapping(uint256 => address) private _books;
    /// @notice Keeper registry.
    KeepersRouter.Repo private _keepers;

    // ==== UUPSUpgradable ====

    /// @dev Storage gap for upgrade safety.
    uint[50] private __gap;

    /// @notice Register this company in RegCenter and store registry metadata.
    function createCorpSeal(
        uint _typeOfEntity
    ) external reinitializer(3) onlyOwner{
        _rc.getRC().regUser();
        _info.regNum = _rc.getRC().getMyUserNo();
        _info.regDate = uint48(block.timestamp);
        _info.typeOfEntity = uint8(_typeOfEntity);
    }
    
    // ---- Entity ----

    function setCompInfo (
        uint8 _currency,
        bytes18 _symbol,
        string memory _name
    ) external onlyDK {
        _info.currency = _currency;
        _info.symbol = _symbol;
        _info.name = _name;
    }

    function getCompInfo() external view returns(CompInfo memory) {
        return _info;
    }

    function getCompUser() external view onlyOwner returns (UsersRepo.User memory) {
        return _rc.getRC().getMyUser();
    }

    // ---- Keepers ----

    function regKeeper(uint256 title, address keeper) external onlyDK {
        _keepers.regKeeper(title, keeper);
        emit RegKeeper(title, keeper, msg.sender);
    }

    function regSigToTitle(bytes4 sig, uint256 title) external onlyDK {
        _keepers.regSigToTitle(sig, title);
        emit RegSigToTitle(sig, title, msg.sender);
    }

    function isKeeper(address target) external view returns (bool) {   
        return _keepers.isKeeper(target);
    }

    function getKeeper(uint256 title) external view returns (address) {
        return _keepers.getKeeper(title);
    }

    function getTitleOfKeeper(address keeper) external view returns (uint) {
        return _keepers.getTitleOfKeeper(keeper);
    }

    // ---- Books ----

    function regBook(uint256 title, address book) external onlyDK {
        _books[title] = book;
        emit RegBook(title, book, msg.sender);
    } 

    function getBook(uint256 title) external view returns (address) {
        return _books[title];
    }

    /// @notice Fallback router for keeper calls.
    /// @dev Looks up `msg.sig` in keeper registry and delegates the call to the
    ///      corresponding keeper. Uses `delegatecall`, so storage writes affect
    ///      this contract and `msg.sender` remains the original caller.
    ///      Reverts if the selector is not registered, and bubbles up revert data.
    fallback() external payable {
        address keeper = _keepers.getKeeperBySig(msg.sig);
        
        (bool success, ) = keeper.delegatecall(msg.data);

        if (success) {
            emit ForwardedCall(keeper, msg.sender, msg.sig);
        } else {
            // Bubble up revert reason from delegatecall
            assembly {
                let returndata_size := returndatasize()
                returndatacopy(0, 0, returndata_size)
                revert(0, returndata_size)
            }
        }
    }

    /// @notice Accept ETH transfers.
    receive () external payable{
        emit ReceivedEth(msg.sender, msg.value);
    }
}

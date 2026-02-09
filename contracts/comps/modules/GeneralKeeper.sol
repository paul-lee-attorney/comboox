// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
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

pragma solidity ^0.8.8;

import "./IGeneralKeeper.sol";
import "../common/access/AccessControl.sol";
import "../../openzeppelin/utils/Address.sol";
import "../../lib/UsersRepo.sol";
import "../../lib/InterfacesHub.sol";

contract GeneralKeeper is IGeneralKeeper, AccessControl {
    using Address for address;
    using InterfacesHub for address;

    /// @notice Company registry info stored in this keeper.
    CompInfo internal _info;

    /// @notice Book registry (title => book address).
    mapping(uint256 => address) private _books;
    /// @notice Keeper registry (title => keeper address).
    mapping(uint256 => address) internal _keepers;
    /// @notice Reverse keeper registry (keeper address => title).
    mapping(address => uint256) private _titleOfKeeper;

    // ==== UUPSUpgradable ====

    /// @dev Storage gap for upgrade safety.
    uint[50] private __gap;

    // ---- Initialize ----
    function initialize(
        address owner,
        address regCenter
    ) external override initializer {
        _init(owner, regCenter);
        _createCorpSeal();
    }

    /// @notice Register this company in RegCenter and store registry metadata.
    function _createCorpSeal() private {
        rc.getRC().regUser();
        _info.regNum = rc.getRC().getMyUserNo();
        _info.regDate = uint48(block.timestamp);
    }
    
    // ---- Entity ----

    function setCompInfo (
        uint8 _typeOfEntity,
        uint8 _currency,
        bytes18 _symbol,
        string memory _name
    ) external onlyDK {
        _info.typeOfEntity = _typeOfEntity;
        _info.currency = _currency;
        _info.symbol = _symbol;
        _info.name = _name;
    }

    function getCompInfo() external view returns(CompInfo memory) {
        return _info;
    }

    function getCompUser() external view onlyOwner returns (UsersRepo.User memory) {
        return rc.getRC().getUser();
    }

    // ---- Keepers ----

    function regKeeper(
        uint256 title, 
        address keeper
    ) external onlyDK {
        _titleOfKeeper[_keepers[title]] = 0;
        _keepers[title] = keeper;
        _titleOfKeeper[keeper] = title;
        emit RegKeeper(title, keeper, msg.sender);
    }

    function isKeeper(address caller) external view returns (bool) {   
        return _titleOfKeeper[caller] > 0;
    }

    function getKeeper(uint256 title) external view returns (address) {
        return _keepers[title];
    }

    function getTitleOfKeeper(address keeper) external view returns (uint) {
        return _titleOfKeeper[keeper];
    }

    // ---- Books ----

    function regBook(uint256 title, address book) external onlyDK {
        _books[title] = book;
        emit RegBook(title, book, msg.sender);
    } 

    function getBook(uint256 title) external view returns (address) {
        return _books[title];
    }

    // ---- Actions ----
    
    /// @notice Execute a batch of calls with value.
    /// @param targets Target addresses.
    /// @param values ETH values to send.
    /// @param params Calldata payloads.
    function _execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params
    ) internal {
        require(
            targets.length == values.length && targets.length == params.length,
            "GK._execute: length mismatch"
        );
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i].functionCallWithValue(params[i], values[i]);
        }
        emit ExecAction(keccak256(
            abi.encode(targets, values, params)
        ));
    }

    /// @notice Accept ETH transfers.
    receive () external payable{
        emit ReceivedEth(msg.sender, msg.value);
    }
}

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

import "./IRegisterOfConstitution.sol";

import "../../common/components/FilesFolder.sol";

contract RegisterOfConstitution is IRegisterOfConstitution, FilesFolder {

    /// @notice Current active constitution document address.
    address private _pointer;

    // ==== UUPSUpgradeable ====

    /// @dev Storage gap for upgrade safety.
    uint[50] private __gap;
    
    //##################
    //##  Write I/O  ##
    //##################

    function changePointer(address body) external onlyDK {
        if (_pointer != address(0)) 
            setStateOfFile(_pointer, uint8(FilesRepo.StateOfFile.Revoked));
        _pointer = body;
        emit ChangePointer(body);
    }

    //################
    //##    Read    ##
    //################

    function pointer() external view returns (address) {
        return _pointer;
    }
}

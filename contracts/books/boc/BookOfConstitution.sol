// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfConstitution.sol";

import "../../common/components/FilesFolder.sol";

contract BookOfConstitution is IBookOfConstitution, FilesFolder {

    address private _pointer;

    //##################
    //##    写接口    ##
    //##################

    function changePointer(address body) external onlyDirectKeeper {
        if (_pointer != address(0)) setStateOfFile(_pointer, uint8(FilesRepo.StateOfFile.Revoked));
        // setStateOfFile(body, uint8(StateOfFile.Closed));
        _pointer = body;
        emit ChangePointer(body);
    }

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address) {
        return _pointer;
    }
}

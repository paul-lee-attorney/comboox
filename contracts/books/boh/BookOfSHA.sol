// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfSHA.sol";

import "../../common/components/RepoOfDocs.sol";

contract BookOfSHA is IBookOfSHA, RepoOfDocs {

    address private _pointer;

    //##################
    //##    写接口    ##
    //##################

    function changePointer(address body) external onlyDirectKeeper onlyRegistered(body) {
        if (_pointer != address(0)) setStateOfDoc(_pointer, uint8(RODStates.Revoked));
        setStateOfDoc(body, uint8(RODStates.Executed));
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

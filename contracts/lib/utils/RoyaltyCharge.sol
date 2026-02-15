// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "../InterfacesHub.sol";

/// @title RoyaltyCharge
/// @notice Internal helper for charging royalty fees via RegCenter.
library RoyaltyCharge {
    using InterfacesHub for address;

    /// @notice Emitted when a royalty charge is applied.
    /// @param typeOfDoc Document type identifier.
    /// @param version Document version.
    /// @param rate Royalty rate (unit defined by caller).
    /// @param user User number charged.
    /// @param author Author user number receiving royalty.
    event ChargeRoyalty(
        uint indexed typeOfDoc, uint version, uint indexed rate, 
        uint indexed user, uint author
    );

    /// @notice Resolve sender user number and charge royalty.
    /// @param target Caller address.
    /// @param rate Royalty rate (unit defined by caller).
    /// @return usr User number of the caller.
    function msgSender(
        address target,
        uint typeOfDoc,
        uint version,
        uint rate
    ) external returns(uint40 usr) {
        address gk = address(this);
        uint author =
            gk.getRCByGK().getTemp(
                typeOfDoc,
                version
            ).head.author;

        usr = gk.getRCByGK().getUserNo(
            target, rate * (10 ** 10), author
        );

        emit ChargeRoyalty(
            typeOfDoc,
            version,
            rate * (10 ** 10),
            usr,
            author
        );
    }
}

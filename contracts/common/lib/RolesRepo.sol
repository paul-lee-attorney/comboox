// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library RolesRepo {
    bytes32 constant ATTORNEYS = bytes32("Attorneys");

    struct GroupOfRole {
        mapping(uint40 => bool) isMember;
        uint40 admin;
    }

    struct Roles {
        uint8 state; // 0-pending; 1-initiated; 2-finalized
        address bookeeper;
        uint40[2] managers; // 0-owner; 1-generalCounsel; ...
        mapping(bytes32 => GroupOfRole) roles;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function initDoc(
        Roles storage self,
        uint40 owner,
        address keeper
    ) internal {

        require(self.state == 0, 
            "RR.initiate: already initiated");

        self.state = 1;
        self.managers[0] = owner;
        self.bookeeper = keeper;
    }

    function setBookeeper(
        Roles storage self,
        address caller,
        address acct
    ) internal {
        require(caller == self.bookeeper, 
            "RR.setBookeeper: caller not bookeeper");
        self.bookeeper = acct;
    }

    function setManager(
        Roles storage self,
        uint8 title,
        uint40 acct
    ) internal {

        self.managers[title] = acct;

        // ==== GeneralCounsel ====
        if (title == 1 && acct != 0) {
            self.roles[ATTORNEYS].admin = acct;
            self.roles[ATTORNEYS].isMember[acct] = true;
        }
    }

    // ==== role ====

    function setRoleAdmin(
        Roles storage self,
        bytes32 role,
        uint40 caller,
        uint40 acct
    ) internal {

        require(
            caller == self.managers[0],
            "RR.setRoleAdmin: caller not owner"
        );

        self.roles[role].admin = acct;
    }

    function grantRole(
        Roles storage self,
        bytes32 role,
        uint40 caller,
        uint40 acct
    ) internal {
        require(
            caller == roleAdmin(self, role),
            "RR.grantRole: caller not admin of role"
        );
        self.roles[role].isMember[acct] = true;
    }

    function revokeRole(
        Roles storage self,
        bytes32 role,
        uint40 originator,
        uint40 acct
    ) internal {
        require(originator == roleAdmin(self, role), "RR.revokeRole: originator not admin");

        delete self.roles[role].isMember[acct];
    }

    function renounceRole(
        Roles storage self,
        bytes32 role,
        uint40 originator
    ) internal {
        delete self.roles[role].isMember[originator];
    }

    function abandonRole(
        Roles storage self,
        bytes32 role
    ) internal {
        self.roles[role].admin = 0;
        delete self.roles[role];
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isManager(
        Roles storage self,
        uint8 title,
        uint40 acct
    ) internal view returns (bool) {
        return self.managers[title] == acct;
    }

    function isDirectKeeper(
        Roles storage self,
        address keeper
    ) internal view returns (bool) {
        return self.bookeeper == keeper;
    }

    function getKeeper(
        Roles storage self
    ) internal view returns (address) {
        return self.bookeeper;
    }

    function getManager(
        Roles storage self,
        uint8 title
    ) internal view returns (uint40) {
        return self.managers[title];
    }

    // ==== role ====

    function hasRole(
        Roles storage self,
        bytes32 role,
        uint40 acct
    ) internal view returns (bool) {
        return self.roles[role].isMember[acct];
    }

    function roleAdmin(Roles storage self, bytes32 role)
        internal
        view
        returns (uint40)
    {
        return self.roles[role].admin;
    }
}

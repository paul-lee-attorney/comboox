// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library RolesRepo {
    bytes32 private constant _ATTORNEYS = bytes32("Attorneys");

    struct GroupOfRole {
        mapping(uint256 => bool) isMember;
        uint40 admin;
    }

    struct Roles {
        uint40 owner;
        address bookeeper;
        uint40 generalCounsel;
        uint8 state; // 0-pending; 1-initiated; 2-finalized
        mapping(bytes32 => GroupOfRole) roles;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function initDoc(
        Roles storage self,
        uint256 owner,
        address keeper
    ) public {

        require(self.state == 0, 
            "RR.ID: already initiated");

        self.state = 1;
        self.owner = uint40(owner);
        self.bookeeper = keeper;
    }

    function setBookeeper(
        Roles storage self,
        address acct,
        address caller
    ) public {
        require(caller == self.bookeeper, 
            "RR.SK: not bookeeper");
        self.bookeeper = acct;
    }

    function setOwner(
        Roles storage self,
        uint256 acct,
        uint256 caller
    ) public {
        require(caller == self.owner, 
            "RR.SO: not owner");
        self.owner = uint40(acct);
    }

    function setGeneralCounsel(
        Roles storage self,
        uint256 acct,
        uint256 caller,
        address msgSender
    ) public {
        require(caller == self.owner ||
            msgSender == self.bookeeper ||
            caller == self.generalCounsel, 
            "RR.SGC: neither owner nor gc");
        uint40 gc = uint40(acct);
        
        self.generalCounsel = gc;

        if (gc > 0) {
            self.roles[_ATTORNEYS].admin = gc;
            self.roles[_ATTORNEYS].isMember[gc] = true;
        }
    }

    // ==== role ====

    function setRoleAdmin(
        Roles storage self,
        bytes32 role,
        uint256 acct,
        uint256 caller
    ) public {

        require(
            caller == self.owner,
            "RR.SRA: not owner"
        );

        self.roles[role].admin = uint40(acct);
    }

    function grantRole(
        Roles storage self,
        bytes32 role,
        uint256 acct,
        uint256 caller
    ) public {
        require(
            caller == roleAdmin(self, role),
            "RR.GR: not adminOfRole"
        );
        self.roles[role].isMember[acct] = true;
    }

    function revokeRole(
        Roles storage self,
        bytes32 role,
        uint256 acct,
        uint256 caller
    ) public {
        require(caller == roleAdmin(self, role), 
            "RR.RR: not adminOfRole");

        delete self.roles[role].isMember[acct];
    }

    function renounceRole(
        Roles storage self,
        bytes32 role,
        uint256 caller
    ) public {
        delete self.roles[role].isMember[caller];
    }

    function abandonRole(
        Roles storage self,
        bytes32 role,
        uint256 caller
    ) public {
        require(caller == self.owner ||
            caller == roleAdmin(self, role), 
            "RR.AR: neither owner nor adminOfRole");
        self.roles[role].admin = 0;
        delete self.roles[role];
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function isOwner(
        Roles storage self,
        uint256 acct
    ) public view returns (bool) {
        return self.owner == acct && self.owner != 0;
    }

    function isGeneralCounsel(
        Roles storage self,
        uint256 acct
    ) public view returns (bool) {
        return self.generalCounsel == acct && self.generalCounsel != 0;
    }

    function isDirectKeeper(
        Roles storage self,
        address keeper
    ) public view returns (bool) {
        return self.bookeeper == keeper;
    }

    function getKeeper(
        Roles storage self
    ) public view returns (address) {
        return self.bookeeper;
    }

    function getOwner(
        Roles storage self
    ) public view returns (uint40) {
        return self.owner;
    }

    function getGeneralCounsel(
        Roles storage self
    ) public view returns (uint40) {
        return self.generalCounsel;
    }

    // ==== role ====

    function hasRole(
        Roles storage self,
        bytes32 role,
        uint256 acct
    ) public view returns (bool) {
        return self.roles[role].isMember[acct];
    }

    function roleAdmin(Roles storage self, bytes32 role)
        public
        view
        returns (uint40)
    {
        return self.roles[role].admin;
    }
}

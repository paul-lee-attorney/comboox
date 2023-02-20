// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfMembers.sol";

import "../../common/lib/MembersRepo.sol";
import "../../common/lib/TopChain.sol";

import "../../common/ruting/BOSSetting.sol";

contract RegisterOfMembers is IRegisterOfMembers, BOSSetting {
    using MembersRepo for MembersRepo.GeneralMeeting;

    MembersRepo.GeneralMeeting private _gm;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyBOS() {
        require(
            msg.sender == address(_bos),
            "ROM.onlyBOS: msgSender is not bos"
        );
        _;
    }

    modifier memberExist(uint40 acct) {
        require(isMember(acct), "ROM.memberExist: NOT Member");
        _;
    }

    modifier groupExist(uint40 group) {
        require(isGroupRep(group), "ROM.groupExist: NOT group");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setMaxQtyOfMembers(uint8 max) external onlyDirectKeeper {
        _gm.setMaxQtyOfMembers(max);
        emit SetMaxQtyOfMembers(max);
    }

    function setVoteBase(bool onPar) external onlyKeeper {
        if (_gm.setVoteBase(onPar)) emit SetVoteBase(onPar);
    }

    function setAmtBase(bool onPar) external onlyKeeper {
        if (_gm.setAmtBase(onPar)) emit SetAmtBase(onPar);
    }

    function capIncrease(uint64 paid, uint64 par) external onlyBOS {
        uint64 blocknumber = _gm.changeAmtOfCap(paid, par, true);
        emit CapIncrease(paid, par, blocknumber);
    }

    function capDecrease(uint64 paid, uint64 par) external onlyBOS {
        uint64 blocknumber = _gm.changeAmtOfCap(paid, par, false);
        emit CapDecrease(paid, par, blocknumber);
    }

    function addMember(uint40 acct) external onlyBOS {
        require(
            _gm.qtyOfMembers() < _gm.maxQtyOfMembers() ||
                _gm.maxQtyOfMembers() == 0,
            "ROM.addMember: Qty of Members overflow"
        );

        if (_gm.addMember(acct)) emit AddMember(acct, _gm.qtyOfMembers());
    }

    function addShareToMember(uint32 ssn, uint40 acct) external onlyBOS {
        IBookOfShares.Share memory share = _bos.getShare(ssn);

        if (_gm.addShareToMember(share.shareNumber, acct)) {
            _gm.changeAmtOfMember(acct, share.paid, share.par, true);
            emit AddShareToMember(share.shareNumber, acct);
        }
    }

    function removeShareFromMember(uint32 ssn, uint40 acct) external onlyBOS {
        IBookOfShares.Share memory share = _bos.getShare(ssn);

        changeAmtOfMember(acct, share.paid, share.par, false);

        if (_gm.removeShareFromMember(share.shareNumber, acct)) {
            if (_gm.qtyOfSharesInHand(acct) == 0) _gm.delMember(acct);

            emit RemoveShareFromMember(share.shareNumber, acct);
        }
    }

    function changeAmtOfMember(
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool increase
    ) public onlyBOS {
        if (!increase) {
            require(
                _gm.paidOfMember(acct) >= deltaPaid,
                "ROm.changeAmtOfMember: paid amount not enough"
            );
            require(
                _gm.parOfMember(acct) >= deltaPar,
                "ROm.changeAmtOfMember: par amount not enough"
            );
        }

        uint64 blocknumber = _gm.changeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            increase
        );

        emit ChangeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            increase,
            blocknumber
        );
    }

    function addMemberToGroup(uint40 acct, uint40 root)
        external
        onlyKeeper
    {
        if (_gm.addMemberToGroup(acct, root)) emit AddMemberToGroup(acct, root);
    }

    function removeMemberFromGroup(uint40 acct, uint40 root)
        external
        onlyKeeper
    {
        require(
            root == _gm.groupRep(acct),
            "BOS.removeMemberFromGroup: Root is not groupRep of Acct"
        );

        uint40 next = _gm.nextMember(acct);

        if (_gm.removeMemberFromGroup(acct)) {
            emit RemoveMemberFromGroup(acct, root);
            if (acct == root) emit ChangeGroupRep(root, next);
        }
    }

    // ##################
    // ##   查询接口   ##
    // ##################

    function basedOnPar() external view returns (bool) {
        return _gm.basedOnPar();
    }

    function maxQtyOfMembers() external view returns (uint32) {
        return _gm.maxQtyOfMembers();
    }

    function paidCap() external view returns (uint64) {
        return _gm.paidCap();
    }

    function parCap() external view returns (uint64) {
        return _gm.parCap();
    }

    function capAtDate(uint48 date)
        external
        view
        returns (uint64 paid, uint64 par)
    {
        return _gm.capAtDate(date);
    }

    function totalVotes() external view returns (uint64) {
        return _gm.totalVotes();
    }

    function sharesList() external view returns (bytes32[] memory) {
        return _gm.sharesList();
    }

    function isShareNumber(bytes32 sharenumber) external view returns (bool) {
        return _gm.isShareNumber(sharenumber);
    }

    function isMember(uint40 acct) public view returns (bool) {
        return _gm.isMember(acct);
    }

    function paidOfMember(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 paid)
    {
        paid = _gm.paidOfMember(acct);
    }

    function parOfMember(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64 par)
    {
        par = _gm.parOfMember(acct);
    }

    function votesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (uint64)
    {
        return _gm.votesInHand(acct);
    }

    function votesAtDate(uint256 acct, uint48 date)
        external
        view
        returns (uint64)
    {
        return _gm.votesAtDate(acct, date);
    }

    function sharesInHand(uint40 acct)
        external
        view
        memberExist(acct)
        returns (bytes32[] memory)
    {
        return _gm.sharesInHand(acct);
    }

    function qtyOfMembers() external view returns (uint32) {
        return _gm.qtyOfMembers();
    }

    function membersList() external view returns (uint40[] memory) {
        return _gm.membersList();
    }

    function affiliated(uint40 acct1, uint40 acct2)
        external
        view
        memberExist(acct1)
        memberExist(acct2)
        returns (bool)
    {
        return _gm.affiliated(acct1, acct2);
    }

    // ==== group ====

    function groupRep(uint40 acct) external view returns (uint40) {
        return _gm.groupRep(acct);
    }

    function isGroupRep(uint40 acct) public view returns (bool) {
        return _gm.isGroupRep(acct);
    }

    function qtyOfGroups() external view returns (uint32) {
        return _gm.qtyOfGroups();
    }

    function controllor() external view returns (uint40) {
        return _gm.controllor();
    }

    function votesOfController() external view returns (uint64) {
        return _gm.votesOfHead();
    }

    function votesOfGroup(uint40 acct) external view returns (uint64) {
        return _gm.votesOfGroup(acct);
    }

    function membersOfGroup(uint40 acct)
        external
        view
        returns (uint40[] memory)
    {
        return _gm.membersOfGroup(acct);
    }

    function deepOfGroup(uint40 acct) external view returns (uint32) {
        return _gm.deepOfGroup(acct);
    }

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory) {
        return _gm.getSnapshot();
    }
}

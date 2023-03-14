// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfMembers.sol";

import "../../common/lib/MembersRepo.sol";
import "../../common/lib/TopChain.sol"; 
import "../../common/lib/Checkpoints.sol"; 
import "../../common/lib/EnumerableSet.sol"; 

import "../../common/access/AccessControl.sol";

import "../../common/ruting/BOSSetting.sol";

contract RegisterOfMembers is IRegisterOfMembers, BOSSetting, AccessControl {
    using MembersRepo for MembersRepo.GeneralMeeting;
    using TopChain for TopChain.Chain;
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.History;

    MembersRepo.GeneralMeeting private _gm;

    //##################
    //##   Modifier   ##
    //##################

    modifier memberExist(uint256 acct) {
        require(isMember(acct), "ROM.memberExist: NOT Member");
        _;
    }

    modifier groupExist(uint256 group) {
        require(isGroupRep(group), "ROM.groupExist: NOT group");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setMaxQtyOfMembers(uint32 max) external onlyDirectKeeper {
        _gm.chain.setMaxQtyOfMembers(max);
        emit SetMaxQtyOfMembers(max);
    }

    function setVoteBase(bool onPar) external onlyKeeper {
        if (_gm.chain.setVoteBase(onPar)) 
            emit SetVoteBase(onPar);
    }

    function setAmtBase(bool onPar) external onlyKeeper {
        if (_gm.setAmtBase(onPar)) 
            emit SetAmtBase(onPar);
    }

    function capIncrease(uint64 paid, uint64 par) external onlyBOS {
        _gm.changeAmtOfCap(paid, par, true);
        emit CapIncrease(paid, par);
    }

    function capDecrease(uint64 paid, uint64 par) external onlyBOS {
        _gm.changeAmtOfCap(paid, par, false);
        emit CapDecrease(paid, par);
    }

    function addMember(uint256 acct) external onlyBOS {
        require(
            _gm.chain.qtyOfMembers() < _gm.chain.maxQtyOfMembers() ||
                _gm.chain.maxQtyOfMembers() == 0,
            "ROM.addMember: Qty of Members overflow"
        );

        if (_gm.chain.addNode(acct)) 
            emit AddMember(acct, _gm.chain.qtyOfMembers());
    }

    function addShareToMember(uint32 seqOfShare, uint40 acct) external onlyBOS {
        IBookOfShares.Share memory share = _getBOS().getShare(seqOfShare);

        if (_gm.addShareToMember(seqOfShare, acct)) {
            _gm.changeAmtOfMember(acct, share.body.paid, share.body.par, true);
            emit AddShareToMember(seqOfShare, acct);
        }
    }

    function removeShareFromMember(uint32 seqOfShare, uint40 acct) external onlyBOS {
        IBookOfShares.Share memory share = _getBOS().getShare(seqOfShare);

        changeAmtOfMember(acct, share.body.paid, share.body.par, false);

        if (_gm.removeShareFromMember(seqOfShare, acct)) {
            if (_gm.members[acct].sharesInHand.length() == 0) _gm.delMember(acct);

            emit RemoveShareFromMember(seqOfShare, acct);
        }
    }

    function changeAmtOfMember(
        uint40 acct,
        uint64 deltaPaid,
        uint64 deltaPar,
        bool increase
    ) public onlyBOS {
        if (!increase) {
            Checkpoints.Checkpoint memory clip = _gm.members[acct].votesInHand.latest();
            require(
                clip.paid >= deltaPaid &&
                clip.par >= deltaPar,
                "ROM.CAOM: paid or par not enough"
            );
        }

        emit ChangeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            increase
        );

        _gm.changeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            increase
        );
    }

    function addMemberToGroup(uint40 acct, uint40 root)
        external
        onlyKeeper
    {
        if (_gm.chain.top2Sub(acct, root)) emit AddMemberToGroup(acct, root);
    }

    function removeMemberFromGroup(uint256 acct, uint256 root)
        external
        onlyKeeper
    {
        require(
            root == _gm.chain.rootOf(acct),
            "ROM.RMFG: Root is not groupRep of Acct"
        );

        uint256 next = _gm.chain.nextNode(acct);

        if (_gm.chain.sub2Top(acct)) {
            emit RemoveMemberFromGroup(acct, root);
            if (acct == root) emit ChangeGroupRep(root, next);
        }
    }

    // ##################
    // ##   查询接口   ##
    // ##################

    function basedOnPar() external view returns (bool) {
        return _gm.chain.basedOnPar();
    }

    function maxQtyOfMembers() external view returns (uint32) {
        return _gm.chain.maxQtyOfMembers();
    }

    function ownersEquity() external view returns(Checkpoints.Checkpoint memory cap) {
        return _gm.members[0].votesInHand.latest();
    }

    function capAtDate(uint48 date)
        external
        view
        returns (Checkpoints.Checkpoint memory cap)
    {
        cap = _gm.members[0].votesInHand.getAtDate(date); 
    }

    function totalVotes() external view returns (uint64) {
        return _gm.chain.totalVotes();
    }

    function sharesList() external view returns (uint256[] memory) {
        return _gm.members[0].sharesInHand.values();
    }

    function isSeqOfShare(uint256 seqOfShare) external view returns (bool) {
        return _gm.members[0].sharesInHand.contains(seqOfShare);
    }

    function isMember(uint256 acct) public view returns (bool) {
        return _gm.chain.isMember(acct);
    }

    function sharesClipOfMember(uint256 acct)
        external
        view
        memberExist(acct)
        returns (Checkpoints.Checkpoint memory clip)
    {
        clip = _gm.members[acct].votesInHand.latest();
    }

    function votesInHand(uint256 acct)
        external
        view
        memberExist(acct)
        returns (uint64)
    {
        return _gm.chain.nodes[acct].amt;
    }

    function votesAtDate(uint256 acct, uint48 date)
        external
        view
        returns (uint64)
    {
        return _gm.votesAtDate(acct, date);
    }

    function sharesInHand(uint256 acct)
        external
        view
        memberExist(acct)
        returns (uint256[] memory list)
    {
        list = _gm.members[acct].sharesInHand.values();
    }

    function qtyOfMembers() external view returns (uint32) {
        return _gm.chain.qtyOfMembers();
    }

    function membersList() external view returns (uint256[] memory) {
        return _gm.chain.membersList();
    }

    function affiliated(uint256 acct1, uint256 acct2)
        external
        view
        memberExist(acct1)
        memberExist(acct2)
        returns (bool)
    {
        return _gm.chain.affiliated(acct1, acct2);
    }

    // ==== group ====

    function groupRep(uint256 acct) external view returns (uint256) {
        return _gm.chain.rootOf(acct);
    }

    function isGroupRep(uint256 acct) public view returns (bool) {

        return _gm.chain.rootOf(acct) == acct;
    }

    function qtyOfGroups() external view returns (uint32) {
        return _gm.chain.qtyOfBranches();
    }

    function controllor() external view returns (uint40) {
        return _gm.chain.head();
    }

    function votesOfController() external view returns (uint64) {
        uint40 head = _gm.chain.head();
        return _gm.chain.nodes[head].sum;
    }

    function votesOfGroup(uint256 acct) external view returns (uint64) {
        return _gm.chain.votesOfGroup(acct);
    }

    function membersOfGroup(uint256 acct)
        external
        view
        returns (uint256[] memory)
    {
        return _gm.chain.membersOfGroup(acct);
    }

    function deepOfGroup(uint256 acct) external view returns (uint32) {
        return _gm.chain.deepOfBranch(acct);
    }

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory) {
        return _gm.chain.getSnapshot();
    }
}

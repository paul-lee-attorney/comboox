// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfMembers.sol";

import "../../common/access/AccessControl.sol";

contract RegisterOfMembers is IRegisterOfMembers, AccessControl {
    using Checkpoints for Checkpoints.History;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using MembersRepo for MembersRepo.Repo;
    using TopChain for TopChain.Chain;

    MembersRepo.Repo private _repo;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyBOS() {
        require(
            msg.sender == address(_getGK().getROS()),
            "ROM.mf.OBOS: msgSender is not BOS"
        );
        _;
    }

    modifier memberExist(uint256 acct) {
        require(isMember(acct), "ROM.memberExist: NOT Member");
        _;
    }

    modifier groupExist(uint256 group) {
        require(isGroupRep(group), "ROM.groupExist: NOT group");
        _;
    }

    //##################
    //##  Write I/O  ##
    //##################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        _repo.chain.setMaxQtyOfMembers(max);
        emit SetMaxQtyOfMembers(max);
    }

    function setVoteBase(bool onPar) external onlyKeeper {
        if (_repo.chain.setVoteBase(onPar)) 
            emit SetVoteBase(onPar);
    }

    function setAmtBase(bool onPar) external onlyKeeper {
        if (_repo.setAmtBase(onPar)) 
            emit SetAmtBase(onPar);
    }

    function capIncrease(uint votingWeight, uint paid, uint par) external onlyBOS {
        _repo.changeAmtOfCap(votingWeight, paid, par, true);
        emit CapIncrease(paid, par);
    }

    function capDecrease(uint votingWeight, uint paid, uint par) external onlyBOS {
        _repo.changeAmtOfCap(votingWeight, paid, par, false);
        emit CapDecrease(paid, par);
    }

    function addMember(uint256 acct) external onlyBOS {
        if (_repo.chain.addNode(acct)) 
            emit AddMember(acct, _repo.chain.getNumOfMembers());
    }

    function addShareToMember(SharesRepo.Share memory share) external onlyBOS {
        if (_repo.addShareToMember(share.head)) {
            _repo.changeAmtOfMember(share.head.shareholder, share.head.votingWeight, share.body.paid, share.body.par, share.body.cleanPaid, true);
            emit AddShareToMember(share.head.seqOfShare, share.head.shareholder);
        }
    }

    function removeShareFromMember(SharesRepo.Share memory share) external onlyBOS {
        changeAmtOfMember(share.head.shareholder, share.head.votingWeight, share.body.paid, share.body.par, share.body.cleanPaid, false);

        if (_repo.removeShareFromMember(share.head)) {
            if (_repo.members[share.head.shareholder].sharesInHand.length() == 0) 
                _repo.delMember(share.head.shareholder);

            emit RemoveShareFromMember(share.head.seqOfShare, share.head.shareholder);
        }
    }

    function changeAmtOfMember(
        uint acct,
        uint votingWeight,
        uint deltaPaid,
        uint deltaPar,
        uint deltaClean,
        bool increase
    ) public onlyBOS {
        if (!increase) {
            Checkpoints.Checkpoint memory clip = _repo.members[acct].votesInHand.latest();
            require(
                clip.paid >= deltaPaid &&
                clip.par >= deltaPar &&
                clip.cleanPaid >= deltaClean,
                "ROM.CAOM: insufficient amount"
            );
        }

        emit ChangeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            deltaClean,
            increase
        );

        _repo.changeAmtOfMember(
            acct,
            votingWeight,
            deltaPaid,
            deltaPar,
            deltaClean,
            increase
        );
    }

    function addMemberToGroup(uint acct, uint root)
        external
        onlyKeeper
    {
        if (_repo.chain.top2Sub(acct, root)) 
            emit AddMemberToGroup(acct, root);
    }

    function removeMemberFromGroup(uint256 acct, uint256 root)
        external
        onlyKeeper
    {
        require(
            root == _repo.chain.rootOf(acct),
            "ROM.RMFG: Root is not groupRep of Acct"
        );

        uint256 next = _repo.chain.nextNode(acct);

        if (_repo.chain.sub2Top(acct)) {
            emit RemoveMemberFromGroup(acct, root);
            if (acct == root) emit ChangeGroupRep(root, next);
        }
    }

    // ##################
    // ##   查询接口    ##
    // ##################

    function basedOnPar() external view returns (bool) {
        return _repo.chain.basedOnPar();
    }

    function maxQtyOfMembers() external view returns (uint32) {
        return _repo.chain.maxQtyOfMembers();
    }

    function ownersEquity() external view returns(Checkpoints.Checkpoint memory cap) {
        return _repo.members[0].votesInHand.latest();
    }

    function capAtDate(uint date)
        external
        view
        returns (Checkpoints.Checkpoint memory cap)
    {
        cap = _repo.members[0].votesInHand.getAtDate(date); 
    }

    function totalVotes() external view returns (uint64) {
        return _repo.chain.totalVotes();
    }

    function sharesList() external view returns (bytes32[] memory) {
        return _repo.members[0].sharesInHand.values();
    }

    function isSNOfShare(bytes32 sharenumber) external view returns (bool) {
        return _repo.members[0].sharesInHand.contains(sharenumber);
    }

    function isMember(uint256 acct) public view returns (bool) {
        return _repo.chain.isMember(acct);
    }

    // ==== Member ====

    function sharesClipOfMember(uint256 acct)
        external
        view
        memberExist(acct)
        returns (Checkpoints.Checkpoint memory clip)
    {
        clip = _repo.members[acct].votesInHand.latest();
    }

    function votesInHand(uint256 acct)
        external
        view
        memberExist(acct)
        returns (uint64)
    {
        return _repo.chain.nodes[acct].amt;
    }

    function votesAtDate(uint256 acct, uint date)
        external
        view
        returns (uint64)
    {
        return _repo.votesAtDate(acct, date);
    }

    function getVotesHistory(uint acct)
        external view returns (Checkpoints.Checkpoint[] memory)
    {
        return _repo.getVotesHistory(acct);
    }

    function sharesInHand(uint256 acct)
        external
        view
        memberExist(acct)
        returns (bytes32[] memory list)
    {
        list = _repo.members[acct].sharesInHand.values();
    }

    function getNumOfMembers() external view returns (uint32) {
        return _repo.chain.getNumOfMembers();
    }

    function membersList() external view returns (uint256[] memory) {
        return _repo.chain.membersList();
    }

    function affiliated(uint256 acct1, uint256 acct2)
        external
        view
        memberExist(acct1)
        memberExist(acct2)
        returns (bool)
    {
        return _repo.chain.affiliated(acct1, acct2);
    }

    function isClassMember(uint256 acct, uint class)
        external view returns(bool flag)
    {
        flag = _repo.isClassMember(acct, class);
    }

    function getMembersOfClass(uint class)
        external view returns(uint256[] memory members)
    {
        members = _repo.getMembersOfClass(class);
    }

    // ==== group ====

    function groupRep(uint256 acct) external view returns (uint40) {
        return _repo.chain.rootOf(acct);
    }

    function isGroupRep(uint256 acct) public view returns (bool) {

        return _repo.chain.rootOf(acct) == acct;
    }

    function qtyOfGroups() external view returns (uint256) {
        return _repo.chain.qtyOfBranches();
    }

    function controllor() external view returns (uint40) {
        return _repo.chain.head();
    }

    function votesOfController() external view returns (uint64) {
        uint40 head = _repo.chain.head();
        return _repo.chain.nodes[head].sum;
    }

    function votesOfGroup(uint256 acct) external view returns (uint64) {
        return _repo.chain.votesOfGroup(acct);
    }

    function membersOfGroup(uint256 acct)
        external
        view
        returns (uint256[] memory)
    {
        return _repo.chain.membersOfGroup(acct);
    }

    function deepOfGroup(uint256 acct) external view returns (uint256) {
        return _repo.chain.deepOfBranch(acct);
    }

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory) {
        return _repo.chain.getSnapshot();
    }
}

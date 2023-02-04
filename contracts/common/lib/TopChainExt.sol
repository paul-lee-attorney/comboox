// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./TopChain.sol";

contract TopChainExt {
    using TopChain for TopChain.Chain;

    TopChain.Chain private _gm;

    /* Node[0] {
        prev: tail;
        next: head;
        ptr: qtyOfMembers;
        amt: maxQtyOfMembers;
        sum: totalVotes;
        cat: basedOnPar;
    } */

    //##################
    //##    写接口    ##
    //##################

    // ==== Node ====

    function addNode(uint40 acct) external returns (bool flag) {
        return _gm.addNode(acct);
    }

    function delNode(uint40 acct) external returns (bool flag) {
        return _gm.delNode(acct);
    }

    // ==== ChangeAmt ====

    function changeAmt(
        uint40 acct,
        uint64 deltaAmt,
        bool increase
    ) external returns (bool flag) {
        return _gm.changeAmt(acct, deltaAmt, increase);
    }

    // ==== jumpChain ====

    function top2Sub(uint40 acct, uint40 root) external returns (bool flag) {
        return _gm.top2Sub(acct, root);
    }

    function sub2Top(uint40 acct) external returns (bool flag) {
        return _gm.sub2Top(acct);
    }

    function setMaxQtyOfMembers(uint16 max) external {
        _gm.setMaxQtyOfMembers(max);
    }

    function setVoteBase(bool onPar) external returns (bool flag) {
        return _gm.setVoteBase(onPar);
    }

    // ==== restoreChain ====

    function restoreChain(TopChain.Node[] memory snapshot) external {
        _gm.restoreChain(snapshot);
    }

    //##################
    //##    读接口    ##
    //##################

    function isMember(uint40 acct) public view returns (bool) {
        return _gm.isMember(acct);
    }

    // ==== Zero Node ====

    function tail() external view returns (uint40) {
        return _gm.tail();
    }

    function head() external view returns (uint40) {
        return _gm.head();
    }

    function qtyOfMembers() public view returns (uint32) {
        return _gm.qtyOfMembers();
    }

    function maxQtyOfMembers() public view returns (uint32) {
        return _gm.maxQtyOfMembers();
    }

    function totalVotes() external view returns (uint64) {
        return _gm.totalVotes();
    }

    function basedOnPar() public view returns (bool) {
        return _gm.basedOnPar();
    }

    // ==== locate position ====

    function getPos(
        uint64 amount,
        uint40 prev,
        uint40 next,
        bool increase
    ) public view returns (uint40, uint40) {
        return _gm.getPos(amount, prev, next, increase);
    }

    function nextNode(uint40 acct) public view returns (uint40 next) {
        return _gm.nextNode(acct);
    }

    function getNode(uint40 acct)
        external
        view
        returns (
            uint40 prev,
            uint40 next,
            uint40 ptr,
            uint64 amt,
            uint64 sum,
            uint8 cat
        )
    {
        return _gm.getNode(acct);
    }

    // ==== group ====

    function groupRep(uint40 acct) public view returns (uint40) {
        return _gm.rootOf(acct);
    }

    function deepOfBranch(uint40 acct) public view returns (uint32 deep) {
        return _gm.deepOfBranch(acct);
    }

    function votesOfGroup(uint40 group) external view returns (uint64 votes) {
        return _gm.votesOfGroup(group);
    }

    function membersOfGroup(uint40 acct)
        external
        view
        returns (uint40[] memory)
    {
        return _gm.membersOfGroup(acct);
    }

    function affiliated(uint40 acct1, uint40 acct2)
        external
        view
        returns (bool)
    {
        return _gm.affiliated(acct1, acct2);
    }

    // ==== members ====

    function membersList() external view returns (uint40[] memory) {
        return _gm.membersList();
    }

    // ==== backup ====

    function getSnapshot() external view returns (TopChain.Node[] memory) {
        return _gm.getSnapshot();
    }
}

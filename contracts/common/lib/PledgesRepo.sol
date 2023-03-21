// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library PledgesRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    enum StateOfPld {
        Pending,
        Issued,
        Locked,
        Released,
        Executed,
        Revoked
    }

    struct Head {
        uint32 seqOfShare;
        uint16 seqOfPld;
        uint48 createDate;
        uint48 triggerDate;
        uint16 monOfGuarantee;
        uint40 pledgor;
        uint40 debtor;
        uint8 state;
    }

    struct Body {
        uint40 creditor; //质权人、债权人
        uint64 paid;
        uint64 par;
        uint64 guaranteedAmt;
    }

    //Pledge 质权
    struct Pledge {
        Head head; //质押编号
        Body body;
        bytes32 hashLock;
    }

    struct Repo{
        // seqOfShare => seqOfPld => Pledge
        mapping(uint256 => mapping(uint256 => Pledge)) pledges;
        EnumerableSet.UintSet snList;
    }

    //##################
    //##    写接口    ##
    //##################

    function snParser(uint256 sn) public pure returns (Head memory head) {
        head = Head({
            seqOfShare: uint32(sn >> 224),
            seqOfPld: uint16(sn >> 208),
            createDate: uint48(sn >> 160),
            triggerDate: uint48(sn >> 112),
            monOfGuarantee: uint16(sn >> 96),
            pledgor: uint40(sn >> 56),
            debtor: uint40(sn >> 16),
            state: 0
        });
    } 

    function codifyHead(Head memory head) public pure returns (uint256 sn) {
        sn = uint256(head.seqOfShare) << 224 +
            uint256(head.seqOfPld) << 208 + 
            uint256(head.createDate) << 160 +
            uint256(head.triggerDate) << 112 +
            uint256(head.monOfGuarantee) << 96 +
            uint256(head.pledgor) << 56 +
            uint256(head.debtor) << 16;
    } 

    function createPledge(
            Repo storage repo, 
            uint256 sn, 
            uint40 creditor, 
            uint64 paid, 
            uint64 par,
            uint64 guaranteedAmt
    ) public returns (Head memory head) 
    {
        head = snParser(sn);
        head = issuePledge(repo, head, creditor, paid, par, guaranteedAmt);
    }

    function issuePledge(
        Repo storage repo,
        Head memory head,
        uint40 creditor,
        uint64 paid,
        uint64 par,
        uint64 guaranteedAmt
    ) public returns(Head memory regHead) {
        Pledge memory pld;

        head.createDate = uint48(block.timestamp);
        head.state = uint8(StateOfPld.Issued);

        pld.head = head;

        pld.body = Body({
            creditor: creditor,
            paid: paid,
            par: par,
            guaranteedAmt: guaranteedAmt
        });

        regHead = regPledge(repo, pld);
    }

    function regPledge(
        Repo storage repo,
        Pledge memory pld
    ) public returns(Head memory regHead){
        pld.head.seqOfPld = _increaseCounterOfPld(repo, pld.head.seqOfShare);

        repo.pledges[pld.head.seqOfShare][pld.head.seqOfPld] = pld;
        repo.snList.add(codifyHead(pld.head));

        regHead = pld.head;
    }

    function updatePledge(
        Pledge storage pld,
        uint40 creditor,
        uint64 paid,
        uint64 par,
        uint64 guaranteedAmt
    ) public {
        require(pld.head.state == uint8(StateOfPld.Issued), "PR.UP: wrong state");
        require(block.timestamp < pld.head.triggerDate + pld.head.monOfGuarantee * 2592000, 
            "PR.UP: pledge expired");

        pld.body = Body({
            creditor : creditor,
            paid: paid,
            par : par,
            guaranteedAmt: guaranteedAmt
        });
    }

    function lockPledge(
        Pledge storage pld,
        bytes32 hashLock
    ) public returns (bool flag){
        require (block.timestamp < pld.head.triggerDate + pld.head.monOfGuarantee * 2592000, 
            "PR.RP: pledge expired");

        if (pld.head.state == uint8(StateOfPld.Issued)){
            pld.head.state = uint8(StateOfPld.Locked);
            pld.hashLock = hashLock;
            flag = true;
        }
    }

    function releasePledge(
        Pledge storage pld,
        string memory hashKey
    ) public returns (bool flag){
        require (pld.head.state == uint8(StateOfPld.Locked), "PR.RP: wrong state");
        if (pld.hashLock == keccak256(bytes(hashKey))) {
            pld.head.state = uint8(StateOfPld.Released);
            flag = true;
        }
    }

    function execPledge(Pledge storage pld, uint40 caller) public returns(bool flag)
    {
        require(block.timestamp >= pld.head.triggerDate && 
            block.timestamp < pld.head.triggerDate + pld.head.monOfGuarantee * 2592000,
            "PR.EP: pledge not available");

        require(caller == pld.body.creditor, "PR.EP: caller not creditor");

        if (pld.head.state == uint8(StateOfPld.Issued) ||
            pld.head.state == uint8(StateOfPld.Locked))
        {
            pld.head.state = uint8(StateOfPld.Executed);
            flag = true;
        }        
    }

    function reovkePledge(Pledge storage pld, uint40 caller) public returns(bool flag)
    {
        require(block.timestamp > pld.head.triggerDate + pld.head.monOfGuarantee * 2592000,
            "PR.EP: pledge not expired");

        if (caller == pld.head.pledgor) {
            pld.head.state = uint8(StateOfPld.Executed);
            flag = true;
        }
    }

    function _increaseCounterOfPld(Repo storage repo, uint256 seqOfShare) 
        private returns (uint16 seqOfPld) 
    {
        repo.pledges[seqOfShare][0].head.seqOfPld++;
        seqOfPld = repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    //#################
    //##    读接口    ##
    //#################

    function counterOfPld(Repo storage repo, uint256 seqOfShare) 
        public view 
        returns (uint16) 
    {
        return repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    function getPledgesOfShare(Repo storage repo, uint256 seqOfShare) 
        public view 
        returns (Pledge[] memory) 
    {
        uint256 len = counterOfPld(repo, seqOfShare);

        require(len > 0, "BOP.POS: no pledges found");

        Pledge[] memory output = new Pledge[](len);

        while (len > 0) {
            output[len - 1] = repo.pledges[seqOfShare][len];
            len--;
        }

        return output;
    }

    function getSnList(Repo storage repo) public view returns (uint256[] memory list)
    {
        list = repo.snList.values();
    }

}

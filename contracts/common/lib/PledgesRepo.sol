// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library PledgesRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Head {
        uint32 seqOfShare;
        uint32 seqOfPld;
        uint48 createDate;
        uint48 expireDate;
        uint40 pledgor;
        uint40 debtor;
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
            seqOfPld: uint32(sn >> 192),
            createDate: uint48(sn >> 144),
            expireDate: uint48(sn >> 96),
            pledgor: uint40(sn >> 56),
            debtor: uint40(sn >> 16)
        });
    } 

    function codifyHead(Head memory head) public pure returns (uint256 sn) {
        sn = uint256(head.seqOfShare) << 224 +
            uint256(head.seqOfPld) << 192 + 
            uint256(head.createDate) << 144 +
            uint256(head.pledgor) << 56 +
            uint256(head.debtor) << 16;
    } 

    function createPledge(
            Repo storage repo, 
            uint256 sn, 
            uint40 creditor, 
            uint16 monOfGuarantee, 
            uint64 paid, 
            uint64 par, 
            uint64 guaranteedAmt
    ) public returns (Head memory head) 
    {
        head = snParser(sn);
        head = issuePledge(repo, head, creditor, monOfGuarantee, paid, par, guaranteedAmt);
    }


    function issuePledge(
        Repo storage repo,
        Head memory head,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 paid,
        uint64 par,
        uint64 guaranteedAmt
    ) public returns(Head memory regHead) {
        Pledge memory pld;

        head.createDate = uint48(block.timestamp);
        head.expireDate = uint48(block.timestamp) +
            monOfGuarantee * 2592000;

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
        pld.head.seqOfPld = _increaseCounterOfPledges(repo, pld.head.seqOfShare);

        repo.pledges[pld.head.seqOfShare][pld.head.seqOfPld] = pld;
        repo.snList.add(codifyHead(pld.head));

        regHead = pld.head;
    }

    function updatePledge(
        Pledge storage pld,
        uint40 creditor,
        uint48 expireDate,
        uint64 paid,
        uint64 par,
        uint64 guaranteedAmt
    ) public {
        pld.head.expireDate = expireDate;

        pld.body = Body({
            creditor : creditor,
            paid: paid,
            par : par,
            guaranteedAmt : guaranteedAmt
        });
    }

    function _increaseCounterOfPledges(Repo storage repo, uint256 seqOfShare) 
        private returns (uint32 seqOfPld)
    {
        repo.pledges[seqOfShare][0].head.seqOfPld++;
        seqOfPld = repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    //#################
    //##    读接口    ##
    //#################

    function counterOfPledges(Repo storage repo, uint256 seqOfShare) 
        public view 
        returns (uint32) 
    {
        return repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    function getPledgesOfShare(Repo storage repo, uint256 seqOfShare) 
        public view 
        returns (Pledge[] memory) 
    {
        uint256 len = counterOfPledges(repo, seqOfShare);

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

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./ArrayUtils.sol";

library SharesRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using ArrayUtils for uint256[];

    struct Head {
        uint32 seq; // 股票序列号
        uint32 preSeq; // 前序股票序列号（股转时原标的股序列号）
        uint16 class; // 股票类别/轮次编号
        uint48 issueDate; // 股票签发日期（秒时间戳）
        uint48 payInDeadline; // 出资期限（秒时间戳）
        uint40 shareholder; // 股东代码
        uint32 price; // 发行价格（实缴出资价）
        uint8 state; //股票状态 （0:正常，1:查封）        
    }

    struct Body {
        uint64 paid; // 实缴出资
        uint64 par; // 认缴出资（注册资本面值）
        uint64 cleanPaid; // 清洁实缴出资（扣除出质、远期、销售要约金额）
        uint64 cleanPar; // 清洁认缴出资
    }

    //Share 股票
    struct Share {
        Head head; //出资证明书编号（股票编号）
        Body body;
    }

    struct Repo {
        // seqOfShare => Share
        mapping(uint256 => Share) shares;
        EnumerableSet.UintSet snList;
    }

    //#################
    //##    Write    ##
    //#################

    function codifyHead(Head memory head) public pure returns (uint256 sn)
    {
        sn = uint256(head.seq) << 224 +
            uint256(head.preSeq) << 192 +
            uint256(head.class) << 176 + 
            uint256(head.issueDate) << 128 +
            uint256(head.shareholder) << 40 +
            uint256(head.price) << 8;
    }

    function snParser(uint256 sn) public pure returns(Head memory head)
    {
        head = Head({
            seq: uint32(sn >> 224),
            preSeq: uint32(sn >> 192),
            class: uint16(sn >> 176),
            issueDate: uint48(sn >> 128),
            payInDeadline: uint48(sn >> 80),
            shareholder: uint40(sn >> 40),
            price: uint32(sn >> 8),
            state: uint8(sn)
        });
    }

    // ==== issue/regist share ====

    function createShare(Repo storage repo, uint256 sharenumber, uint64 paid, uint64 par)
        public returns (Head memory head)
    {
        head = snParser(sharenumber);
        head = issueShare(repo, head, paid, par);
    }


    function issueShare(Repo storage repo, Head memory head, uint64 paid, uint64 par)
        public returns (Head memory regHead)
    {
        if (head.issueDate == 0) head.issueDate = uint48(block.timestamp);
        if (head.class > counterOfClass(repo)) head.class = increaseCounterOfClass(repo);

        regHead = regShare(repo, head, paid, par);
    }

    function regShare(Repo storage repo, Head memory head, uint64 paid, uint64 par)
        public returns(Head memory regHead)
    {
        require(paid > 0, "SR.RS: zero paid");
        require(par > 0, "SR.RS: zero par");
        require(par >= paid, "SR.RS: paid overflow");

        require(head.issueDate <= block.timestamp, "SR.RS: future issueDate");
        require(head.issueDate <= head.payInDeadline, "SR.RS: issueDate later than payInDeadline");

        require(head.shareholder > 0, "SR.RS: zero shareholder");

        require(head.class > 0, "SR.RS: zero class");

        head.seq = increaseCounterOfShare(repo);

        uint256 sn = codifyHead(head);

        if (repo.snList.add(sn)) {
            repo.shares[head.seq].head = head;
            repo.shares[head.seq].body = Body({
                paid: paid,
                par: par,
                cleanPaid: paid,
                cleanPar: par
            });

            regHead = head;
        }
    }

    // ==== deregist/delete share ====

    function deregShare(Repo storage repo, uint256 seq) public returns(bool flag)
    {
        if (repo.snList.remove(codifyHead(repo.shares[seq].head))) {
            delete repo.shares[seq];
            flag = true;
        }
    }

    // ==== counters ====

    function increaseCounterOfShare(Repo storage repo) public returns(uint32 seq)
    {
        repo.shares[0].head.seq++;
        seq = repo.shares[0].head.seq;
    }

    function increaseCounterOfClass(Repo storage repo) public returns(uint16 seq)
    {
        repo.shares[0].head.class++;
        seq = repo.shares[0].head.class;
    }

    // ==== amountChange ====

    function payInCapital(Share storage share, uint64 amt) public
    {
        require(amt > 0, "SR.PIC: zero amount");

        require(share.head.payInDeadline >= block.timestamp, "SR.PIC: missed deadline");
        require(share.body.paid + amt <= share.body.par, 
            "SR.PIC: payIn amount overflow");

        share.body.paid += amt;
        share.body.cleanPaid += amt;
    }

    function subAmtFromShare(Share storage share, uint64 paid, uint64 par) public
    {
        require(par > 0, "SR.SAFS: zero par");
        require(share.body.cleanPar >= par, "SR.SAFS: insufficient cleanPar");
        require(share.body.cleanPaid >= paid, "SR.SAFS: insufficient cleanPaid");

        share.body.paid -= paid;
        share.body.par -= par;

        share.body.cleanPaid -= paid;
        share.body.cleanPar -= par;
    }

    function increaseCleanAmt(Share storage share, uint64 paid, uint64 par) public
    {
        require(par > 0 || paid > 0, "SR.SAFS: zero amt");

        require(share.body.cleanPar + par <= share.body.par, "SR.SAFS: par overflow");
        require(share.body.cleanPaid + paid <= share.body.paid, "SR.SAFS: paid overflow");

        share.body.cleanPaid += paid;
        share.body.cleanPar += par;
    }

    function decreaseCleanAmt(Share storage share, uint64 paid, uint64 par) public
    {
        require(par > 0 || paid > 0, "SR.SAFS: zero amt");

        require(share.body.cleanPar >= par, "SR.SAFS: insufficient cleanPar");
        require(share.body.cleanPaid >= paid, "SR.SAFS: insufficient cleanPaid");

        share.body.cleanPaid -= paid;
        share.body.cleanPar -= par;
    }

    // ==== update head of Share ====

    function updatePayInDeadline(Share storage share, uint48 deadline) public 
    {
        require (deadline > block.timestamp, "SR.UPID: passed deadline");
        share.head.payInDeadline = deadline;
    }

    //####################
    //##    查询接口     ##
    //####################

    function counterOfShare(Repo storage repo) public view returns(uint32 seq)
    {
        seq = repo.shares[0].head.seq;
    }

    function counterOfClass(Repo storage repo) public view returns(uint32 seq)
    {
        seq = repo.shares[0].head.class;
    }

    function attrOfClass(Repo storage repo, uint16 class) 
        public view returns (uint256[] memory seqList, uint256[] memory members)
    {
        require (class > 0, "SR.SOC: zero class");
        require (class <= counterOfClass(repo), "SR.SOC: class overflow");

        uint256[] memory snList = repo.snList.values();

        uint256 len = snList.length;
        uint256[] memory nlist = new uint256[](len);
        uint256[] memory mList = new uint256[](len);

        uint256 ptr;
        while (len > 0) {
            uint256 sn = snList[len-1];

            if (uint16(sn >> 176) == class)
            {
                nlist[ptr] = uint32(sn >> 224);
                mList[ptr] = uint40(sn >> 40);
                
                ptr++;
            } 

            len--;
        }

        seqList = nlist.resize(ptr);
        members = mList.refine();
    }
}

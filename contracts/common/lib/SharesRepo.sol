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
        uint32 seqOfShare; // 股票序列号
        uint32 preSeq; // 前序股票序列号（股转时原标的股序列号）
        uint16 class; // 股票类别/轮次编号
        uint48 issueDate; // 股票签发日期（秒时间戳）
        uint40 shareholder; // 股东代码
        uint32 price; // 发行价格（实缴出资价）
    }

    struct Body {
        uint48 payInDeadline; // 出资期限（秒时间戳）
        uint64 paid; // 实缴出资
        uint64 par; // 认缴出资（注册资本面值）
        uint64 cleanPaid; // 清洁实缴出资（扣除出质、远期、销售要约金额）
        uint8 state;
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

    function snParser(uint256 sn) public pure returns(Head memory head)
    {
        head = Head({
            seqOfShare: uint32(sn >> 224),
            preSeq: uint32(sn >> 192),
            class: uint16(sn >> 176),
            issueDate: uint48(sn >> 128),
            shareholder: uint40(sn >> 88),
            price: uint32(sn >> 56)
        });
    }

    function codifyHead(Head memory head) public pure returns (uint256 sn)
    {
        sn = uint256(head.seqOfShare) << 224 +
            uint256(head.preSeq) << 192 +
            uint256(head.class) << 176 + 
            uint256(head.issueDate) << 128 +
            uint256(head.shareholder) << 88 +
            uint256(head.price) << 56;
    }

    // ==== issue/regist share ====

    function createShare(Repo storage repo, uint256 sharenumber, uint48 payInDeadline, uint64 paid, uint64 par)
        public returns (Share memory newShare)
    {

        Share memory share;
        share.head = snParser(sharenumber);
        share.body = Body({
            payInDeadline: payInDeadline,
            paid: paid,
            par: par,
            cleanPaid: paid,
            state: 0
        });
        newShare = issueShare(repo, share);
    }


    function issueShare(Repo storage repo, Share memory share)
        public returns (Share memory newShare)
    {
        if (share.head.issueDate == 0) 
            share.head.issueDate = uint48(block.timestamp);

        newShare = regShare(repo, share);
    }

    function regShare(Repo storage repo, Share memory share)
        public returns(Share memory newShare)
    {
        require(share.body.paid > 0, "SR.RS: zero paid");
        require(share.body.par > 0, "SR.RS: zero par");
        require(share.body.par >= share.body.paid, "SR.RS: paid overflow");

        require(share.head.issueDate <= block.timestamp, "SR.RS: future issueDate");
        require(share.head.issueDate <= share.body.payInDeadline, "SR.RS: issueDate later than payInDeadline");

        require(share.head.shareholder > 0, "SR.RS: zero shareholder");

        require(share.head.class > 0, "SR.RS: zero class");

        share.head.seqOfShare = increaseCounterOfShare(repo);
        if (share.head.class > counterOfClass(repo)) 
            share.head.class = increaseCounterOfClass(repo);

        uint256 sn = codifyHead(share.head);

        if (repo.snList.add(sn)) {
            repo.shares[share.head.seqOfShare] = share;
            newShare = share;
        }
    }

    // ==== deregist/delete share ====

    function deregShare(Repo storage repo, uint256 seqOfShare) public returns(bool flag)
    {
        if (repo.snList.remove(codifyHead(repo.shares[seqOfShare].head))) {
            delete repo.shares[seqOfShare];
            flag = true;
        }
    }

    // ==== counters ====

    function increaseCounterOfShare(Repo storage repo) public returns(uint32 seqOfShare)
    {
        repo.shares[0].head.seqOfShare++;
        seqOfShare = repo.shares[0].head.seqOfShare;
    }

    function increaseCounterOfClass(Repo storage repo) public returns(uint16 seqOfShare)
    {
        repo.shares[0].head.class++;
        seqOfShare = repo.shares[0].head.class;
    }

    // ==== amountChange ====

    function payInCapital(Share storage share, uint64 amt) public
    {
        require(amt > 0, "SR.PIC: zero amount");

        require(share.body.payInDeadline >= block.timestamp, "SR.PIC: missed deadline");
        require(share.body.paid + amt <= share.body.par, 
            "SR.PIC: payIn amount overflow");

        share.body.paid += amt;
        share.body.cleanPaid += amt;
    }

    function subAmtFromShare(Share storage share, uint64 paid, uint64 par) public
    {
        require(par > 0, "SR.SAFS: zero par");
        require(share.body.cleanPaid >= paid, "SR.SAFS: insufficient cleanPaid");

        share.body.paid -= paid;
        share.body.par -= par;

        share.body.cleanPaid -= paid;
    }

    function increaseCleanPaid(Share storage share, uint64 paid) public
    {
        require(paid > 0, "SR.SAFS: zero amt");

        // require(share.body.cleanPar + par <= share.body.par, "SR.SAFS: par overflow");
        require(share.body.cleanPaid + paid <= share.body.paid, "SR.SAFS: paid overflow");

        share.body.cleanPaid += paid;
        // share.body.cleanPar += par;
    }

    function decreaseCleanPaid(Share storage share, uint64 paid) public
    {
        require(paid > 0, "SR.SAFS: zero amt");

        // require(share.body.cleanPar >= par, "SR.SAFS: insufficient cleanPar");
        require(share.body.cleanPaid >= paid, "SR.SAFS: insufficient cleanPaid");

        share.body.cleanPaid -= paid;
        // share.body.cleanPar -= par;
    }

    // ==== update head of Share ====

    function updatePayInDeadline(Share storage share, uint48 deadline) public 
    {
        require (block.timestamp < deadline, "SR.UPID: passed deadline");
        require (block.timestamp <= share.body.payInDeadline, "SR.UPID: missed original deadline");

        share.body.payInDeadline = deadline;
    }

    //####################
    //##    查询接口     ##
    //####################

    function counterOfShare(Repo storage repo) public view returns(uint32 seqOfShare)
    {
        seqOfShare = repo.shares[0].head.seqOfShare;
    }

    function counterOfClass(Repo storage repo) public view returns(uint32 seqOfShare)
    {
        seqOfShare = repo.shares[0].head.class;
    }

    function sharesOfClass(Repo storage repo, uint16 class) 
        public view returns (uint256[] memory seqList)
    {
        require (class > 0, "SR.SOC: zero class");
        require (class <= counterOfClass(repo), "SR.SOC: class overflow");

        uint256[] memory snList = repo.snList.values();

        uint256 len = snList.length;
        uint256[] memory list = new uint256[](len);
 
        uint256 ptr;
        while (len > 0) {
            uint256 sn = snList[len-1];

            if (uint16(sn >> 176) == class) {
                list[ptr] = uint32(sn >> 224);
                ptr++;
            }

            len--;
        }

        seqList = list.resize(ptr);
    }
}

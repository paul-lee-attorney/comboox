// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ArrayUtils.sol";
import "./EnumerableSet.sol";

library SharesRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using ArrayUtils for uint256[];

    struct Head {
        uint32 seqOfShare; // 股票序列号
        uint32 preSeq; // 前序股票序列号（股转时原标的股序列号）
        uint16 class; // 股票类别/轮次编号
        uint48 issueDate; // 股票签发日期（秒时间戳）
        uint40 shareholder; // 股东代码
        uint32 priceOfPaid; // 发行价格（实缴出资价）
        uint32 priceOfPar; // 发行价格（认缴出资价）
        uint16 para;
        uint8 arg;
    }

    struct Body {
        uint48 payInDeadline; // 出资期限（秒时间戳）
        uint64 paid; // 实缴出资
        uint64 par; // 认缴出资（注册资本面值）
        uint64 cleanPaid; // 清洁实缴出资（扣除出质、远期、销售要约金额）
        uint8 state;
        uint8 para;
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
            priceOfPaid: uint32(sn >> 56),
            priceOfPar: uint32(sn >> 24),
            para: uint16(sn >> 8),
            arg: uint8(sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (uint sn)
    {
        // sn = (uint256(head.seqOfShare) << 224) +
        //     (uint256(head.preSeq) << 192) +
        //     (uint256(head.class) << 176) + 
        //     (uint256(head.issueDate) << 128) +
        //     (uint256(head.shareholder) << 88) +
        //     (uint256(head.priceOfPaid) << 56) + 
        //     (uint256(head.priceOfPar) << 24) +
        //     (uint256(head.para) << 8) +
        //     head.arg;

        bytes memory _sn = abi.encodePacked(head.seqOfShare, head.preSeq, head.class, head.issueDate, head.shareholder, head.priceOfPaid, head.priceOfPar, head.para, head.arg);

        assembly {
            sn := mload(add(_sn, 0x20))
        }

    }

    // ==== issue/regist share ====

    function createShare(Repo storage repo, uint256 sharenumber, uint payInDeadline, uint paid, uint par)
        public returns (Share memory newShare)
    {

        Share memory share;
        share.head = snParser(sharenumber);
        share.body = Body({
            payInDeadline: uint48(payInDeadline),
            paid: uint48(paid),
            par: uint48(par),
            cleanPaid: uint48(paid),
            state: 0,
            para: 0
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

    function payInCapital(Share storage share, uint amt) public
    {
        require(amt > 0, "SR.PIC: zero amount");

        require(share.body.payInDeadline >= block.timestamp, "SR.PIC: missed deadline");
        require(share.body.paid + amt <= share.body.par, 
            "SR.PIC: payIn amount overflow");

        share.body.paid += uint64(amt);
        share.body.cleanPaid += uint64(amt);
    }

    function subAmtFromShare(Share storage share, uint paid, uint par) public
    {
        require(par > 0, "SR.SAFS: zero par");
        require(share.body.cleanPaid >= paid, "SR.SAFS: insufficient cleanPaid");

        share.body.paid -= uint64(paid);
        share.body.par -= uint64(par);

        share.body.cleanPaid -= uint64(paid);
    }

    function increaseCleanPaid(Share storage share, uint paid) public
    {
        require(paid > 0, "SR.SAFS: zero amt");

        // require(share.body.cleanPar + par <= share.body.par, "SR.SAFS: par overflow");
        require(share.body.cleanPaid + paid <= share.body.paid, "SR.SAFS: paid overflow");

        share.body.cleanPaid += uint64(paid);
        // share.body.cleanPar += par;
    }

    function decreaseCleanPaid(Share storage share, uint paid) public
    {
        require(paid > 0, "SR.SAFS: zero amt");

        // require(share.body.cleanPar >= par, "SR.SAFS: insufficient cleanPar");
        require(share.body.cleanPaid >= paid, "SR.SAFS: insufficient cleanPaid");

        share.body.cleanPaid -= uint64(paid);
        // share.body.cleanPar -= par;
    }

    // ==== update head of Share ====

    function updatePayInDeadline(Share storage share, uint deadline) public 
    {
        require (block.timestamp < deadline, "SR.UPID: passed deadline");
        require (block.timestamp <= share.body.payInDeadline, "SR.UPID: missed original deadline");

        share.body.payInDeadline = uint48(deadline);
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

    function sharesOfClass(Repo storage repo, uint class) 
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

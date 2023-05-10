// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ArrayUtils.sol";
import "./EnumerableSet.sol";

library SharesRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;
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
        uint8 argu;
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
        EnumerableSet.Bytes32Set snList;
    }

    //#################
    //##    Write    ##
    //#################

    function snParser(bytes32 sn) public pure returns(Head memory head)
    {
        uint _sn = uint(sn);
        
        head = Head({
            seqOfShare: uint32(_sn >> 224),
            preSeq: uint32(_sn >> 192),
            class: uint16(_sn >> 176),
            issueDate: uint48(_sn >> 128),
            shareholder: uint40(_sn >> 88),
            priceOfPaid: uint32(_sn >> 56),
            priceOfPar: uint32(_sn >> 24),
            para: uint16(_sn >> 8),
            argu: uint8(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 sn)
    {
        bytes memory _sn = abi.encodePacked(
                            head.seqOfShare, 
                            head.preSeq, 
                            head.class, 
                            head.issueDate, 
                            head.shareholder, 
                            head.priceOfPaid, 
                            head.priceOfPar, 
                            head.para, 
                            head.argu);

        assembly {
            sn := mload(add(_sn, 0x20))
        }

    }

    // ==== issue/regist share ====

    function createShare(
        Repo storage repo, 
        bytes32 sharenumber, 
        uint payInDeadline, 
        uint paid, 
        uint par
    ) public returns (Share memory newShare) {

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
        // require(share.body.paid > 0, "SR.RS: zero paid");
        require(share.body.par > 0, "SR.RS: zero par");
        require(share.body.par >= share.body.paid, "SR.RS: paid overflow");

        require(share.head.issueDate <= block.timestamp, "SR.RS: future issueDate");
        require(share.head.issueDate <= share.body.payInDeadline, "SR.RS: issueDate later than payInDeadline");

        require(share.head.shareholder > 0, "SR.RS: zero shareholder");

        require(share.head.class > 0, "SR.RS: zero class");

        share.head.seqOfShare = _increaseCounterOfShare(repo);
        if (share.head.class > counterOfClasses(repo)) 
            share.head.class = _increaseCounterOfClass(repo);

        bytes32 sn = codifyHead(share.head);

        if (repo.snList.add(sn)) {
            repo.shares[share.head.seqOfShare] = share;
            newShare = share;
        }
    }

    // ==== deregist/delete share ====

    function deregShare(Repo storage repo, uint256 seqOfShare) 
        public returns(bool flag)
    {
        if (repo.snList.remove(codifyHead(repo.shares[seqOfShare].head))) {
            delete repo.shares[seqOfShare];
            flag = true;
        }
    }

    // ==== counters ====

    function _increaseCounterOfShare(Repo storage repo) 
        private returns(uint32 seqOfShare)
    {
        repo.shares[0].head.seqOfShare++;
        seqOfShare = repo.shares[0].head.seqOfShare;
    }

    function _increaseCounterOfClass(Repo storage repo) 
        private returns(uint16 seqOfShare)
    {
        repo.shares[0].head.class++;
        seqOfShare = repo.shares[0].head.class;
    }

    // ==== amountChange ====

    function payInCapital(Share storage share, uint amt) public
    {
        require(amt > 0, "SR.PIC: zero amount");

        require(block.timestamp <= share.body.payInDeadline, 
            "SR.PIC: missed deadline");
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

        require(share.body.cleanPaid + paid <= share.body.paid, 
            "SR.SAFS: paid overflow");

        share.body.cleanPaid += uint64(paid);
    }

    function decreaseCleanPaid(Share storage share, uint paid) public
    {
        require(paid > 0, "SR.SAFS: zero amt");

        require(share.body.cleanPaid >= paid, 
            "SR.SAFS: insufficient cleanPaid");

        share.body.cleanPaid -= uint64(paid);
    }

    // ==== update head of Share ====

    function updatePayInDeadline(Share storage share, uint deadline) public 
    {
        require (block.timestamp < deadline, "SR.UPID: passed deadline");
        require (block.timestamp <= share.body.payInDeadline, 
            "SR.UPID: missed original deadline");

        share.body.payInDeadline = uint48(deadline);
    }

    //####################
    //##    查询接口     ##
    //####################

    function counterOfShares(Repo storage repo) public view returns(uint32 seqOfShare)
    {
        seqOfShare = repo.shares[0].head.seqOfShare;
    }

    function counterOfClasses(Repo storage repo) public view returns(uint16 seqOfShare)
    {
        seqOfShare = repo.shares[0].head.class;
    }

    function sharesOfClass(Repo storage repo, uint class) 
        public view returns (uint256[] memory seqList)
    {
        require (class > 0, "SR.SOC: zero class");
        require (class <= counterOfClasses(repo), "SR.SOC: class overflow");

        bytes32[] memory snList = repo.snList.values();

        uint256 len = snList.length;
        uint256[] memory list = new uint256[](len);
 
        uint256 ptr;
        while (len > 0) {
            uint256 sn = uint256(snList[len-1]);

            if (uint16(sn >> 176) == class) {
                list[ptr] = uint32(sn >> 224);
                ptr++;
            }

            len--;
        }

        seqList = list.resize(ptr);
    }
}

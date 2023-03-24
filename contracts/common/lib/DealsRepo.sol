// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./SigsRepo.sol";

import "../access/AccessControl.sol";

import "../components/SigPage.sol";

library DealsRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using SigsRepo for SigsRepo.Page;

    // _deals[0].head {
    //     seq: counterOfClosedDeal;
    //     preSeq: counterOfDeal;
    //     typeOfDeal: typeOfIA;
    // }    

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        PreEmptive,
        TagAlong,
        DragAlong,
        FirstRefusal,
        FreeGift
    }

    enum TypeOfIA {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STint,
        SText_STint,
        CI_SText_STint,
        CI_SText
    }

    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }


    struct Head {
        uint8 typeOfDeal;
        uint16 seq;
        uint16 preSeq;
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 seller;
        uint32 priceOfPaid;
        uint32 priceOfPar;
        uint48 closingDate;
        uint8 state;
    }

    struct Body {
        uint40 buyer;
        uint40 groupOfBuyer;
        uint64 paid;
        uint64 par;
    }

    struct Deal {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    struct Repo {
        mapping(uint256 => Deal) deals;
        EnumerableSet.UintSet snList;
    }

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(Repo storage repo, uint256 seq) {
        require(
            repo.deals[seq].head.state == uint8(StateOfDeal.Cleared),
            "DR.mf.OC: wrong stateOfDeal"
        );
        _;
    }

    //#################
    //##    写接口    ##
    //#################

    function snParser(uint256 sn) public pure returns(Head memory head) {
        return Head({
            typeOfDeal: uint8(sn >> 248),
            seq: uint16(sn >> 240),
            preSeq: uint16(sn >> 224),
            classOfShare: uint16(sn >> 208),
            seqOfShare: uint32(sn >> 192),
            seller: uint40(sn >> 160),
            priceOfPaid: uint32(sn >> 120),
            priceOfPar: uint32(sn >> 88),
            closingDate: uint48(sn >> 56),
            state: uint8(sn >> 8)
        });
    } 

    function codifyHead(Head memory head) public pure returns(uint256 sn) {
        sn = uint256(head.typeOfDeal) << 248 +
            uint256(head.seq) << 240 +
            uint256(head.preSeq) << 224 +
            uint256(head.classOfShare) << 208 +
            uint256(head.seqOfShare) << 192 +
            uint256(head.seller) << 160 +
            uint256(head.priceOfPaid) << 120 +
            uint256(head.priceOfPar) << 88;
    }

    function createDeal(
        Repo storage repo,
        uint256 sn,
        uint40 buyer,
        uint40 groupOfBuyer,
        uint64 paid,
        uint64 par
    ) public returns (uint16 seqOfDeal)  {

        Deal memory deal;

        deal.head = snParser(sn);

        deal.body = Body({
            buyer: buyer,
            groupOfBuyer: groupOfBuyer,
            paid: paid,
            par: par
        });

        seqOfDeal = regDeal(repo, deal);
    }

    function regDeal(Repo storage repo, Deal memory deal) 
        public returns(uint16 seqOfDeal) 
    {
        require(deal.body.par != 0, "DR.RD: zero par");
        require(deal.body.par >= deal.body.paid, "DR.RD: paid overflow");

        deal.head.seq = _increaseCounterOfDeal(repo);

        if (repo.snList.add(codifyHead(deal.head))) {
            repo.deals[deal.head.seq] = Deal({
                head: deal.head,
                body: deal.body,
                hashLock: bytes32(0)
            });
            seqOfDeal = deal.head.seq;
        }
    }

    function _increaseCounterOfDeal(Repo storage repo) private returns(uint16 seq){
        repo.deals[0].head.preSeq++;
        seq = repo.deals[0].head.preSeq;
    }

    function delDeal(Repo storage repo, uint256 seq) public returns (bool flag) {
        if (repo.snList.remove(codifyHead(repo.deals[seq].head))) {
            delete repo.deals[seq];
            repo.deals[0].head.preSeq--;
            flag = true;
        }
    }

    function lockDealSubject(Repo storage repo, uint256 seq) public returns (bool flag) {
        if (repo.deals[seq].head.state == uint8(StateOfDeal.Drafting)) {
            repo.deals[seq].head.state = uint8(StateOfDeal.Locked);
            flag = true;
        }
    }

    function releaseDealSubject(Repo storage repo, uint256 seq) public returns (bool flag)
    {
        if (repo.deals[seq].head.state >= uint8(StateOfDeal.Locked)) {
            repo.deals[seq].head.state = uint8(StateOfDeal.Drafting);
            flag = true;
        }
    }

    function clearDealCP(
        Repo storage repo,
        uint256 seq,
        bytes32 hashLock,
        uint48 closingDate
    ) public {
        Deal storage deal = repo.deals[seq];

        require(
            block.timestamp < closingDate,
            "IA.CDCP: not FUTURE time"
        );

        require(deal.head.state == uint8(StateOfDeal.Locked), 
            "IA.CDCP: wrong Deal state");

        deal.head.state = uint8(StateOfDeal.Cleared);
        deal.hashLock = hashLock;
        if (closingDate != 0) deal.head.closingDate = closingDate;
    }

    function closeDeal(Repo storage repo, uint256 seq, string memory hashKey)
        public onlyCleared(repo, seq) returns (bool flag)
    {
        Deal storage deal = repo.deals[seq];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "IA.closeDeal: hashKey NOT correct"
        );

        require(
            block.timestamp <= deal.head.closingDate,
            "IA.closeDeal: MISSED closing date"
        );

        deal.head.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);

        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function revokeDeal(Repo storage repo, uint256 seq, string memory hashKey)
        external onlyCleared(repo, seq) returns (bool flag)
    {
        Deal storage deal = repo.deals[seq];

        require(
            deal.head.closingDate < block.timestamp,
            "NOT reached closing date"
        );

        require(
            deal.head.typeOfDeal != uint8(TypeOfDeal.FreeGift),
            "FreeGift deal cannot be revoked"
        );

        require(
            deal.head.state == uint8(StateOfDeal.Cleared),
            "wrong state of Deal"
        );

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.head.state = uint8(StateOfDeal.Terminated);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function terminateDeal(Repo storage repo, uint256 seqOfDeal) public returns(bool flag){
        Head storage head = repo.deals[seqOfDeal].head;

        require(head.state == uint8(StateOfDeal.Locked), "IA.TD: wrong stateOfDeal");

        head.state = uint8(StateOfDeal.Terminated);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function takeGift(Repo storage repo, uint256 seq)
        public returns (bool flag)
    {
        Deal storage deal = repo.deals[seq];

        require(
            deal.head.typeOfDeal == uint8(TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            repo.deals[deal.head.preSeq].head.state == uint8(StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.head.state == uint8(StateOfDeal.Locked), "wrong state");

        deal.head.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function _increaseCounterOfClosedDeal(Repo storage repo) private {
        repo.deals[0].head.seq++;
    }

    //  #################################
    //  ##       查询接口               ##
    //  ################################

    function counterOfDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.preSeq;
    }

    function counterOfClosedDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.seq;
    }
}

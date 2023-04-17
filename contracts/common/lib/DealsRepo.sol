// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library DealsRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // _deals[0].head {
    //     seqOfDeal: counterOfClosedDeal;
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
        uint16 seqOfDeal;
        uint16 preSeq;
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 seller;
        uint32 priceOfPaid;
        uint32 priceOfPar;
        uint48 closingDate;
        uint16 para;
    }

    struct Body {
        uint40 buyer;
        uint40 groupOfBuyer;
        uint64 paid;
        uint64 par;
        uint8 state;
        uint16 para;
        uint16 argu;
        bool flag;
    }

    struct Deal {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    struct Repo {
        mapping(uint256 => Deal) deals;
        EnumerableSet.Bytes32Set snList;
    }

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(Repo storage repo, uint256 seqOfDeal) {
        require(
            repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Cleared),
            "DR.mf.OC: wrong stateOfDeal"
        );
        _;
    }

    //#################
    //##    写接口    ##
    //#################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            typeOfDeal: uint8(_sn >> 248),
            seqOfDeal: uint16(_sn >> 232),
            preSeq: uint16(_sn >> 216),
            classOfShare: uint16(_sn >> 200),
            seqOfShare: uint32(_sn >> 168),
            seller: uint40(_sn >> 128),
            priceOfPaid: uint32(_sn >> 96),
            priceOfPar: uint32(_sn >> 64),
            closingDate: uint48(_sn >> 16),
            para: uint16(_sn) 
        });

    } 

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfDeal,
                            head.seqOfDeal,
                            head.preSeq,
                            head.classOfShare,
                            head.seqOfShare,
                            head.seller,
                            head.priceOfPaid,
                            head.priceOfPaid,
                            head.closingDate,
                            head.para);        
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function createDeal(
        Repo storage repo,
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par
    ) public returns (uint16 seqOfDeal)  {

        Deal memory deal;

        deal.head = snParser(sn);

        deal.body.buyer = uint40(buyer);
        deal.body.groupOfBuyer = uint40(groupOfBuyer);
        deal.body.paid = uint64(paid);
        deal.body.par = uint64(par);

        seqOfDeal = regDeal(repo, deal);
    }

    function regDeal(Repo storage repo, Deal memory deal) 
        public returns(uint16 seqOfDeal) 
    {
        require(deal.body.par != 0, "DR.RD: zero par");
        require(deal.body.par >= deal.body.paid, "DR.RD: paid overflow");

        deal.head.seqOfDeal = _increaseCounterOfDeal(repo);

        if (repo.snList.add(codifyHead(deal.head))) {
            repo.deals[deal.head.seqOfDeal] = Deal({
                head: deal.head,
                body: deal.body,
                hashLock: bytes32(0)
            });
            seqOfDeal = deal.head.seqOfDeal;
        }
    }

    function _increaseCounterOfDeal(Repo storage repo) private returns(uint16 seqOfDeal){
        repo.deals[0].head.preSeq++;
        seqOfDeal = repo.deals[0].head.preSeq;
    }

    function delDeal(Repo storage repo, uint256 seqOfDeal) public returns (bool flag) {
        if (repo.snList.remove(codifyHead(repo.deals[seqOfDeal].head))) {
            delete repo.deals[seqOfDeal];
            repo.deals[0].head.preSeq--;
            flag = true;
        }
    }

    function lockDealSubject(Repo storage repo, uint256 seqOfDeal) public returns (bool flag) {
        if (repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Drafting)) {
            repo.deals[seqOfDeal].body.state = uint8(StateOfDeal.Locked);
            flag = true;
        }
    }

    function releaseDealSubject(Repo storage repo, uint256 seqOfDeal) public returns (bool flag)
    {
        if (repo.deals[seqOfDeal].body.state >= uint8(StateOfDeal.Locked)) {
            repo.deals[seqOfDeal].body.state = uint8(StateOfDeal.Drafting);
            flag = true;
        }
    }

    function clearDealCP(
        Repo storage repo,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDate
    ) public {
        Deal storage deal = repo.deals[seqOfDeal];

        require(
            block.timestamp < closingDate,
            "IA.CDCP: not FUTURE time"
        );

        require(deal.body.state == uint8(StateOfDeal.Locked), 
            "IA.CDCP: wrong Deal state");

        deal.body.state = uint8(StateOfDeal.Cleared);
        deal.hashLock = hashLock;
        if (closingDate != 0) deal.head.closingDate = uint48(closingDate);
    }

    function closeDeal(Repo storage repo, uint256 seqOfDeal, string memory hashKey)
        public onlyCleared(repo, seqOfDeal) returns (bool flag)
    {
        Deal storage deal = repo.deals[seqOfDeal];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "IA.closeDeal: hashKey NOT correct"
        );

        require(
            block.timestamp <= deal.head.closingDate,
            "IA.closeDeal: MISSED closing date"
        );

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);

        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function revokeDeal(Repo storage repo, uint256 seqOfDeal, string memory hashKey)
        external onlyCleared(repo, seqOfDeal) returns (bool flag)
    {
        Deal storage deal = repo.deals[seqOfDeal];

        require(
            block.timestamp > deal.head.closingDate,
            "DR.RD: NOT reached closing date"
        );

        require(
            deal.head.typeOfDeal != uint8(TypeOfDeal.FreeGift),
            "FreeGift deal cannot be revoked"
        );

        require(
            deal.body.state == uint8(StateOfDeal.Cleared),
            "wrong state of Deal"
        );

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.body.state = uint8(StateOfDeal.Terminated);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function terminateDeal(Repo storage repo, uint256 seqOfDeal) public returns(bool flag){
        Body storage body = repo.deals[seqOfDeal].body;

        require(body.state == uint8(StateOfDeal.Locked), "IA.TD: wrong stateOfDeal");

        body.state = uint8(StateOfDeal.Terminated);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function takeGift(Repo storage repo, uint256 seqOfDeal)
        public returns (bool flag)
    {
        Deal storage deal = repo.deals[seqOfDeal];

        require(
            deal.head.typeOfDeal == uint8(TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            repo.deals[deal.head.preSeq].body.state == uint8(StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.body.state == uint8(StateOfDeal.Locked), "wrong state");

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function _increaseCounterOfClosedDeal(Repo storage repo) private {
        repo.deals[0].head.seqOfDeal++;
    }

    function setTypeOfIA(Repo storage repo, uint t) public {
        repo.deals[0].head.typeOfDeal = uint8(t);
    }

    //  ################################
    //  ##       查询接口              ##
    //  ###############################

    function getTypeOfIA(Repo storage repo) external view returns (uint8) {
        return repo.deals[0].head.typeOfDeal;
    }

    function counterOfDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.preSeq;
    }

    function counterOfClosedDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.seqOfDeal;
    }

    function isDeal(Repo storage repo, uint256 seqOfDeal) public view returns (bool) {
        return repo.deals[seqOfDeal].head.seqOfDeal == seqOfDeal;
    }

    function getHeadOfDeal(Repo storage repo, uint256 seq) external view returns (Head memory)
    {
        return repo.deals[seq].head;
    }

    function getBodyOfDeal(Repo storage repo,  uint256 seq) external view returns (Body memory)
    {
        return repo.deals[seq].body;
    }

    function getHashLockOfDeal(Repo storage repo, uint256 seq) external view returns (bytes32)
    {
        return repo.deals[seq].hashLock;
    }
    
    function getDeal(Repo storage repo, uint256 seq) external view returns (Deal memory)
    {
        return repo.deals[seq];
    }

    function getSNList(Repo storage repo) external view returns (bytes32[] memory) {
        return repo.snList.values();
    }

}

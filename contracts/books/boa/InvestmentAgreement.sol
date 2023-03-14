// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/SigsRepo.sol";

import "../../common/access/AccessControl.sol";
// import "../../common/ruting/SigPageSetting.sol";

import "../../common/components/SigPage.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is IInvestmentAgreement, SigPage {
    using EnumerableSet for EnumerableSet.UintSet;
    using SigsRepo for SigsRepo.Page;
    // using SNParser for bytes32;

    // _deals[0].head {
    //     seq: counterOfClosedDeal;
    //     preSeq: counterOfDeal;
    //     typeOfDeal: typeOfIA;
    // }    

    // seq => Deal
    mapping(uint256 => Deal) private _deals;
    EnumerableSet.UintSet private _seqList;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(uint256 seq) {
        require(
            _deals[seq].head.state == uint8(StateOfDeal.Cleared),
            "IA.mf.OC: wrong stateOfDeal"
        );
        _;
    }

    //#################
    //##    写接口    ##
    //#################

    function _headParser(bytes32 sn) private pure returns(Head memory head) {
        return Head({
            typeOfDeal: uint8(sn[0]),
            classOfShare: uint16(bytes2(sn<<8)),
            seqOfShare: uint32(bytes4(sn<<24)),
            seller: uint40(bytes5(sn<<56)),
            price: uint32(bytes4(sn<<96)),
            seq: uint32(bytes4(sn<<128)),
            preSeq: uint32(bytes4(sn<<160)),
            closingDate: uint48(bytes6(sn<<192)),
            state: uint8(sn[30])
        });
    } 

    function createDeal(
        bytes32 sn,
        uint40 buyer,
        uint40 groupOfBuyer,
        uint64 paid,
        uint64 par
    ) external attorneyOrKeeper {

        Deal memory deal;

        deal.head = _headParser(sn);

        deal.body = Body({
            buyer: buyer,
            groupOfBuyer: groupOfBuyer,
            paid: paid,
            par: par
        });

        regDeal(deal);
    }

    function regDeal(Deal memory deal) 
        public attorneyOrKeeper 
        returns(uint32 seqOfDeal) 
    {
        require(deal.body.par != 0, "IA.createDeal: par is ZERO");
        require(deal.body.par >= deal.body.paid, "IA.createDeal: paid overflow");

        _increaseCounterOfDeal();

        seqOfDeal = counterOfDeal();

        deal.head.seq = seqOfDeal;

        _deals[seqOfDeal] = Deal({
            head: deal.head,
            body: deal.body,
            hashLock: bytes32(0)
        });

        _seqList.add(seqOfDeal);

        if (!finalized()) {
            if (deal.head.seller != 0) _sigPages[0].addBlank(false, seqOfDeal, deal.head.seller);
            _sigPages[0].addBlank(true, seqOfDeal, deal.body.buyer);
        } else {
            if (deal.head.seller != 0) _sigPages[1].addBlank(false, seqOfDeal, deal.head.seller);
            _sigPages[1].addBlank(true, seqOfDeal, deal.body.buyer);
        }     
    }

    function delDeal(uint256 seq) external onlyAttorney {
        if (_seqList.remove(seq)) {

            Deal memory deal = _deals[seq];

            if (deal.head.seller != 0) {
                _sigPages[0].removeBlank(deal.head.seq, deal.head.seller);
            }

            _sigPages[0].removeBlank(deal.head.seq, deal.body.buyer);

            delete _deals[seq];

            _deals[0].head.preSeq--;
        }

    }

    function lockDealSubject(uint256 seq) external onlyKeeper returns (bool flag) {
        Deal storage deal = _deals[seq];
        if (deal.head.state == uint8(StateOfDeal.Drafting)) {
            deal.head.state = uint8(StateOfDeal.Locked);
            flag = true;
        }
    }

    function releaseDealSubject(uint256 seq)
        external
        onlyDirectKeeper
        returns (bool flag)
    {
        Deal storage deal = _deals[seq];
        if (deal.head.state >= uint8(StateOfDeal.Locked)) {
            deal.head.state = uint8(StateOfDeal.Drafting);
            flag = true;
        }
    }

    function clearDealCP(
        uint256 seq,
        bytes32 hashLock,
        uint48 closingDate
    ) external onlyDirectKeeper {
        Deal storage deal = _deals[seq];

        require(
            block.timestamp < closingDate,
            "IA.CDCP: not FUTURE time"
        );

        require(deal.head.state == uint8(StateOfDeal.Locked), 
            "IA.CDCP: wrong Deal state");

        emit ClearDealCP(deal.head.seq, deal.head.state, hashLock, deal.head.closingDate);
        deal.head.state = uint8(StateOfDeal.Cleared);
        deal.hashLock = hashLock;
        if (closingDate != 0) deal.head.closingDate = closingDate;

    }

    function closeDeal(uint256 seq, string memory hashKey)
        external
        onlyCleared(seq)
        onlyDirectKeeper
        returns (bool)
    {
        Deal storage deal = _deals[seq];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "IA.closeDeal: hashKey NOT correct"
        );

        require(
            block.timestamp <= deal.head.closingDate,
            "IA.closeDeal: MISSED closing date"
        );

        deal.head.state = uint8(StateOfDeal.Closed);

        emit CloseDeal(deal.head.seq, hashKey);
        _increaseCounterOfClosedDeal();

        return (counterOfDeal() == counterOfClosedDeal());
    }

    function revokeDeal(uint256 seq, string memory hashKey)
        external
        onlyCleared(seq)
        onlyDirectKeeper
        returns (bool)
    {
        Deal storage deal = _deals[seq];

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

        emit RevokeDeal(deal.head.seq, hashKey);

        // _deals[0].paid ++;
        _increaseCounterOfClosedDeal();

        return (counterOfDeal() == counterOfClosedDeal());
    }

    function terminateDeal(uint256 seqOfDeal) external onlyKeeper {
        Head storage head = _deals[seqOfDeal].head;

        require(head.state == uint8(StateOfDeal.Locked), "IA.TD: wrong stateOfDeal");

        emit TerminateDeal(seqOfDeal);
        head.state = uint8(StateOfDeal.Terminated);
    }

    function takeGift(uint256 seq)
        external
        onlyKeeper
        returns (bool)
    {
        Deal storage deal = _deals[seq];

        require(
            deal.head.typeOfDeal == uint8(TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            _deals[deal.head.preSeq].head.state == uint8(StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.head.state == uint8(StateOfDeal.Locked), "wrong state");

        emit CloseDeal(deal.head.seq, "0");
        deal.head.state = uint8(StateOfDeal.Closed);

        // _deals[0].paid++;
        _increaseCounterOfClosedDeal();

        return (counterOfDeal() == counterOfClosedDeal());
    }

    function setTypeOfIA(uint8 t) external onlyAttorney {
        _deals[0].head.typeOfDeal = t;
    }

    //  #################################
    //  ##       查询接口               ##
    //  ################################

    function getTypeOfIA() external view returns (uint8) {
        return _deals[0].head.typeOfDeal;
    }

    function _increaseCounterOfDeal() private {
        _deals[0].head.preSeq++;
    }

    function counterOfDeal() public view returns (uint32) {
        return _deals[0].head.preSeq;
    }

    function _increaseCounterOfClosedDeal() private {
        _deals[0].head.seq++;
    }

    function counterOfClosedDeal() public view returns (uint32) {
        return _deals[0].head.seq;
    }

    function isDeal(uint256 seq) public view returns (bool) {
        return _seqList.contains(seq);
    }

    function getHeadOfDeal(uint256 seq) external view returns (Head memory)
    {
        return _deals[seq].head;
    }

    function getBodyOfDeal(uint256 seq) external view returns (Body memory)
    {
        return _deals[seq].body;
    }

    function hashLockOfDeal(uint256 seq) external view returns (bytes32)
    {
        return _deals[seq].hashLock;
    }
    
    function getDeal(uint256 seq) external view returns (Deal memory)
    {
        return _deals[seq];
    }

    function seqList() external view returns (uint256[] memory) {
        return _seqList.values();
    }
}

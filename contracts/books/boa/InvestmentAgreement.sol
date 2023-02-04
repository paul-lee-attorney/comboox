// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROMSetting.sol";

import "../../common/lib/SNParser.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/components/SigPage.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is
    IInvestmentAgreement,
    BOSSetting,
    ROMSetting,
    SigPage
{
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STint,
        SText_STint,
        CI_SText_STint,
        CI_SText,
        PreEmptive,
        TagAlong,
        DragAlong,
        FirstRefusal,
        FreeGift
    }

    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }

    struct Deal {
        bytes32 sn;
        uint64 paid;
        uint64 par;
        uint48 closingDate;
        uint8 state;
        bytes32 hashLock;
    }

    // _deals[0] {
    //     paid: counterOfDeal;
    //     state: typeOfIA;
    // }

    // seq => Deal
    mapping(uint256 => Deal) private _deals;

    EnumerableSet.Bytes32Set private _dealsList;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(uint16 seq) {
        require(
            _deals[seq].state == uint8(StateOfDeal.Cleared),
            "IA.onlyCleared: wrong stateOfDeal"
        );
        _;
    }

    //#################
    //##    写接口    ##
    //#################

    function createDeal(
        bytes32 sn,
        uint64 paid,
        uint64 par,
        uint48 closingDate
    ) external attorneyOrKeeper(uint8(TitleOfKeepers.SHAKeeper)) {
        require(par != 0, "IA.createDeal: par is ZERO");
        require(par >= paid, "IA.createDeal: paid overflow");

        _deals[0].paid++;

        uint16 seq = uint16(_deals[0].paid);

        Deal storage deal = _deals[seq];

        deal.sn = sn;
        deal.paid = paid;
        deal.par = par;
        deal.closingDate = closingDate;

        _dealsList.add(sn);

        uint40 seller = sn.sellerOfDeal();
        uint40 buyer = sn.buyerOfDeal();

        if (finalized()) {
            if (
                seller != 0 &&
                sn.typeOfDeal() != uint8(TypeOfDeal.DragAlong) &&
                sn.typeOfDeal() != uint8(TypeOfDeal.FreeGift)
            ) addBlank(seller, seq);
            addBlank(buyer, seq);
        } else {
            if (seller != 0) addBlank(seller, 0);
            addBlank(buyer, 0);
        }

        emit CreateDeal(sn, paid, par, closingDate);
    }

    function updateDeal(
        uint16 seq,
        uint64 paid,
        uint64 par,
        uint48 closingDate
    ) external attorneyOrKeeper(uint8(TitleOfKeepers.SHAKeeper)) {
        require(isDeal(seq), "IA.updateDeal: deal not exist");

        Deal storage deal = _deals[seq];
        deal.paid = paid;
        deal.par = par;
        deal.closingDate = closingDate;

        emit UpdateDeal(deal.sn, paid, par, closingDate);
    }

    function setTypeOfIA(uint8 t) external onlyPending onlyAttorney {
        _deals[0].state = t;
    }

    function delDeal(uint16 seq) external onlyPending onlyAttorney {
        bytes32 sn = _deals[seq].sn;
        uint40 seller = sn.sellerOfDeal();

        if (seller != 0) {
            removeBlank(seller, seq);
        }

        removeBlank(sn.buyerOfDeal(), seq);

        delete _deals[seq];
        _dealsList.remove(sn);
    }

    function lockDealSubject(uint16 seq) external returns (bool flag) {
        require(
            _gk.isKeeper(uint8(TitleOfKeepers.BOAKeeper), msg.sender) ||
                _gk.isKeeper(uint8(TitleOfKeepers.SHAKeeper), msg.sender),
            "IA.lockDealSubject: caller has no access right"
        );

        Deal storage deal = _deals[seq];
        if (deal.state == uint8(StateOfDeal.Drafting)) {
            deal.state = uint8(StateOfDeal.Locked);
            flag = true;
            emit LockDealSubject(deal.sn);
        }
    }

    function releaseDealSubject(uint16 seq)
        external
        onlyDK
        returns (bool flag)
    {
        Deal storage deal = _deals[seq];
        if (deal.state >= uint8(StateOfDeal.Locked)) {
            deal.state = uint8(StateOfDeal.Drafting);
            flag = true;
            emit ReleaseDealSubject(deal.sn);
        }
    }

    function clearDealCP(
        uint16 seq,
        bytes32 hashLock,
        uint48 closingDate
    ) external onlyDK {
        Deal storage deal = _deals[seq];

        require(
            block.timestamp + 15 minutes < closingDate,
            "closingDate shall be FUTURE time"
        );

        require(
            closingDate <= closingDeadline(),
            "closingDate LATER than deadline"
        );

        require(deal.state == uint8(StateOfDeal.Locked), "Deal state wrong");

        deal.state = uint8(StateOfDeal.Cleared);

        deal.hashLock = hashLock;

        if (closingDate != 0) deal.closingDate = closingDate;

        emit ClearDealCP(deal.sn, deal.state, hashLock, deal.closingDate);
    }

    function closeDeal(uint16 seq, string memory hashKey)
        external
        onlyCleared(seq)
        onlyDK
        returns (bool)
    {
        Deal storage deal = _deals[seq];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "IA.closeDeal: hashKey NOT correct"
        );

        require(
            block.timestamp + 900 <= deal.closingDate,
            "IA.closeDeal: MISSED closing date"
        );

        deal.state = uint8(StateOfDeal.Closed);

        emit CloseDeal(deal.sn, hashKey);

        return _checkCompletionOfIA();
    }

    function _checkCompletionOfIA() private view returns (bool) {
        bytes32[] memory list = _dealsList.values();

        uint256 len = list.length;

        while (len > 0) {
            bytes32 sn = list[len - 1];

            uint16 seq = sn.seqOfDeal();

            if (_deals[seq].state < uint8(StateOfDeal.Closed)) return false;

            len--;
        }

        return true;
    }

    function revokeDeal(uint16 seq, string memory hashKey)
        external
        onlyCleared(seq)
        onlyDK
        returns (bool)
    {
        Deal storage deal = _deals[seq];

        require(
            deal.closingDate < block.timestamp - 15 minutes,
            "NOT reached closing date"
        );

        require(
            deal.sn.typeOfDeal() != uint8(TypeOfDeal.FreeGift),
            "FreeGift deal cannot be revoked"
        );

        require(
            deal.state == uint8(StateOfDeal.Cleared),
            "wrong state of Deal"
        );

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "hashKey NOT correct"
        );

        deal.state = uint8(StateOfDeal.Terminated);

        emit RevokeDeal(deal.sn, hashKey);

        return _checkCompletionOfIA();
    }

    function takeGift(uint16 seq)
        external
        onlyKeeper(uint8(TitleOfKeepers.SHAKeeper))
    {
        Deal storage deal = _deals[seq];

        require(
            deal.sn.typeOfDeal() == uint8(TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            _deals[deal.sn.preSeqOfDeal()].state == uint8(StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.state == uint8(StateOfDeal.Locked), "wrong state");

        deal.state = uint8(StateOfDeal.Closed);

        emit CloseDeal(deal.sn, "0");
    }

    //  #################################
    //  ##       查询接口               ##
    //  ################################

    function typeOfIA() external view returns (uint8) {
        return _deals[0].state;
    }

    function isDeal(uint16 seq) public view returns (bool) {
        return _dealsList.contains(_deals[seq].sn);
    }

    function counterOfDeals() external view returns (uint16) {
        return uint16(_deals[0].paid);
    }

    function getDeal(uint16 seq)
        external
        view
        returns (
            bytes32 sn,
            uint64 paid,
            uint64 par,
            uint8 state, // 0-pending 1-locked 2-cleared 3-closed 4-terminated
            bytes32 hashLock
        )
    {
        Deal storage deal = _deals[seq];

        sn = deal.sn;
        paid = deal.paid;
        par = deal.par;
        state = deal.state;
        hashLock = deal.hashLock;
    }

    function closingDateOfDeal(uint16 seq) external view returns (uint48) {
        return _deals[seq].closingDate;
    }

    function dealsList() external view returns (bytes32[] memory) {
        return _dealsList.values();
    }
}

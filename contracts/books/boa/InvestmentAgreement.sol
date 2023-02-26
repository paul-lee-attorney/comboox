// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/SNParser.sol";

import "../../common/access/AccessControl.sol";
import "../../common/ruting/SigPageSetting.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is IInvestmentAgreement, SigPageSetting {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SNParser for bytes32;

    // _deals[0] {
    //     paid: counterOfClosedDeal;
    //     par: counterOfDeal;
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
    ) external attorneyOrKeeper {
        require(par != 0, "IA.createDeal: par is ZERO");
        require(par >= paid, "IA.createDeal: paid overflow");

        _deals[0].par++;

        uint16 seq = uint16(_deals[0].par);

        Deal storage deal = _deals[seq];

        deal.sn = sn;
        deal.paid = paid;
        deal.par = par;
        deal.closingDate = closingDate;

        _dealsList.add(sn);

        uint40 seller = sn.sellerOfDeal();
        uint40 buyer = sn.buyerOfDeal();

        // if (finalized()) {
            // if (
            //     seller != 0 &&
            //     sn.typeOfDeal() != uint8(TypeOfDeal.DragAlong) &&
            //     sn.typeOfDeal() != uint8(TypeOfDeal.FreeGift)
            // ) _page.addBlank(seq, seller);
            // _page.addBlank(seq, buyer);

            // emit CreateDeal(sn, paid, par, closingDate);
        if (!finalized()) {
            if (seller != 0) _page.addBlank(0, seller);
            _page.addBlank(0, buyer);
        }      
    }

    function updateDeal(
        uint16 seq,
        uint64 paid,
        uint64 par,
        uint48 closingDate
    ) external attorneyOrKeeper() {
        require(isDeal(seq), "IA.updateDeal: deal not exist");

        Deal storage deal = _deals[seq];

        if (finalized()) emit UpdateDeal(deal.sn, paid, par, closingDate);

        deal.paid = paid;
        deal.par = par;
        deal.closingDate = closingDate;
    }

    function setTypeOfIA(uint8 t) external onlyAttorney {
        _deals[0].state = t;
    }

    function delDeal(uint16 seq) external onlyAttorney {
        bytes32 sn = _deals[seq].sn;
        uint40 seller = sn.sellerOfDeal();

        if (seller != 0) {
            _page.removeBlank(seq, seller);
        }

        _page.removeBlank(seq, sn.buyerOfDeal());

        if (_dealsList.remove(sn)) {
            delete _deals[seq];
            _deals[0].par--;
        }

    }

    function lockDealSubject(uint16 seq) external onlyKeeper returns (bool flag) {
        Deal storage deal = _deals[seq];
        if (deal.state == uint8(StateOfDeal.Drafting)) {
            deal.state = uint8(StateOfDeal.Locked);
            flag = true;
        }
    }

    function releaseDealSubject(uint16 seq)
        external
        onlyDirectKeeper
        returns (bool flag)
    {
        Deal storage deal = _deals[seq];
        if (deal.state >= uint8(StateOfDeal.Locked)) {
            deal.state = uint8(StateOfDeal.Drafting);
            flag = true;
            // emit ReleaseDealSubject(deal.sn);
        }
    }

    function clearDealCP(
        uint16 seq,
        bytes32 hashLock,
        uint48 closingDate
    ) external onlyDirectKeeper {
        Deal storage deal = _deals[seq];

        require(
            block.timestamp < closingDate,
            "closingDate shall be FUTURE time"
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
        onlyDirectKeeper
        returns (bool)
    {
        Deal storage deal = _deals[seq];

        require(
            deal.hashLock == keccak256(bytes(hashKey)),
            "IA.closeDeal: hashKey NOT correct"
        );

        require(
            block.timestamp <= deal.closingDate,
            "IA.closeDeal: MISSED closing date"
        );

        deal.state = uint8(StateOfDeal.Closed);

        emit CloseDeal(deal.sn, hashKey);

        _deals[0].paid++;

        return (_deals[0].paid == _deals[0].par);
    }

    function revokeDeal(uint16 seq, string memory hashKey)
        external
        onlyCleared(seq)
        onlyDirectKeeper
        returns (bool)
    {
        Deal storage deal = _deals[seq];

        require(
            deal.closingDate < block.timestamp,
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

        _deals[0].paid ++;

        return (_deals[0].paid == _deals[0].par);
    }

    function takeGift(uint16 seq)
        external
        onlyKeeper
        returns (bool)
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

        emit CloseDeal(deal.sn, "0");
        deal.state = uint8(StateOfDeal.Closed);

        _deals[0].paid++;

        return (_deals[0].paid == _deals[0].par);
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
        return uint16(_deals[0].par);
    }

    function getDeal(uint16 seq)
        external
        view
        returns (Deal memory deal)
    {
        deal = _deals[seq];
    }

    // function closingDateOfDeal(uint16 seq) external view returns (uint48) {
    //     return _deals[seq].closingDate;
    // }

    function dealsList() external view returns (bytes32[] memory) {
        return _dealsList.values();
    }
}

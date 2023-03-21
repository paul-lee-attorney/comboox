// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "../../common/components/SigPage.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is IInvestmentAgreement, SigPage {
    using EnumerableSet for EnumerableSet.UintSet;
    using SigsRepo for SigsRepo.Page;
    using DealsRepo for DealsRepo.Repo;

    DealsRepo.Repo private _repo;

    //#################
    //##    写接口    ##
    //#################

    function createDeal(
        uint256 sn,
        uint40 buyer,
        uint40 groupOfBuyer,
        uint64 paid,
        uint64 par
    ) external attorneyOrKeeper returns (uint16 seqOfDeal) {
        seqOfDeal = _repo.createDeal(sn, buyer, groupOfBuyer, paid, par);
    }

    function regDeal(DealsRepo.Deal memory deal) 
        public attorneyOrKeeper 
        returns(uint16 seqOfDeal) 
    {
        seqOfDeal = _repo.regDeal(deal);

        if (!finalized()) {
            if (deal.head.seller != 0) _sigPages[0].addBlank(false, seqOfDeal, deal.head.seller);
            _sigPages[0].addBlank(true, seqOfDeal, deal.body.buyer);
        } else {
            if (deal.head.seller != 0) _sigPages[1].addBlank(false, seqOfDeal, deal.head.seller);
            _sigPages[1].addBlank(true, seqOfDeal, deal.body.buyer);
        } 
    }

    function delDeal(uint256 seq) external onlyAttorney {

        DealsRepo.Deal memory deal = _repo.deals[seq];

        if (_repo.delDeal(seq)) {
            if (deal.head.seller != 0) {
                _sigPages[0].removeBlank(deal.head.seq, deal.head.seller);
            }
            _sigPages[0].removeBlank(deal.head.seq, deal.body.buyer);
        }
    }

    function lockDealSubject(uint256 seq) external onlyKeeper returns (bool flag) {
        flag = _repo.lockDealSubject(seq);
    }

    function releaseDealSubject(uint256 seq)
        external
        onlyDirectKeeper
        returns (bool flag)
    {
        flag = _repo.releaseDealSubject(seq);
    }

    function clearDealCP(
        uint256 seq,
        bytes32 hashLock,
        uint48 closingDate
    ) external onlyDirectKeeper {
        emit ClearDealCP(seq, hashLock, closingDate);
        _repo.clearDealCP(seq, hashLock, closingDate);
    }

    function closeDeal(uint256 seq, string memory hashKey)
        external
        onlyDirectKeeper
        returns (bool flag)
    {        
        emit CloseDeal(seq, hashKey);
        flag = _repo.closeDeal(seq, hashKey);
    }

    function revokeDeal(uint256 seq, string memory hashKey)
        external
        onlyDirectKeeper
        returns (bool flag)
    {
        emit RevokeDeal(seq, hashKey);
        flag = _repo.revokeDeal(seq, hashKey);
    }

    function terminateDeal(uint256 seqOfDeal) 
        external onlyKeeper returns(bool flag)
    {
        emit TerminateDeal(seqOfDeal);
        flag = _repo.terminateDeal(seqOfDeal);
    }

    function takeGift(uint256 seq)
        external onlyKeeper returns (bool flag)
    {
        emit CloseDeal(seq, "0");
        flag = _repo.takeGift(seq);
    }

    function setTypeOfIA(uint8 t) external onlyAttorney {
        _repo.deals[0].head.typeOfDeal = t;
    }

    //  #################################
    //  ##       查询接口               ##
    //  ################################

    function getTypeOfIA() external view returns (uint8) {
        return _repo.deals[0].head.typeOfDeal;
    }

    function counterOfDeal() public view returns (uint16) {
        return _repo.deals[0].head.preSeq;
    }

    function counterOfClosedDeal() public view returns (uint16) {
        return _repo.deals[0].head.seq;
    }

    function isDeal(uint256 seq) public view returns (bool) {
        return _repo.deals[seq].head.seq == seq;
    }

    function getHeadOfDeal(uint256 seq) external view returns (DealsRepo.Head memory)
    {
        return _repo.deals[seq].head;
    }

    function getBodyOfDeal(uint256 seq) external view returns (DealsRepo.Body memory)
    {
        return _repo.deals[seq].body;
    }

    function getHashLockOfDeal(uint256 seq) external view returns (bytes32)
    {
        return _repo.deals[seq].hashLock;
    }
    
    function getDeal(uint256 seq) external view returns (DealsRepo.Deal memory)
    {
        return _repo.deals[seq];
    }

    function getSnList() external view returns (uint256[] memory) {
        return _repo.snList.values();
    }
}

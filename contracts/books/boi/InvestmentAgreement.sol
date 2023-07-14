// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "../../common/components/SigPage.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is IInvestmentAgreement, SigPage {
    using DealsRepo for DealsRepo.Repo;
    using SigsRepo for SigsRepo.Page;

    DealsRepo.Repo private _repo;

    //#################
    //##    写接口    ##
    //#################

    function addDeal(
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par
    ) external attorneyOrKeeper {
        uint seqOfDeal = _repo.addDeal(sn, buyer, groupOfBuyer, paid, par);
        emit AddDeal(seqOfDeal);
    }

    function regDeal(DealsRepo.Deal memory deal) 
        public attorneyOrKeeper returns(uint16 seqOfDeal) 
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
                _sigPages[0].removeBlank(deal.head.seqOfDeal, deal.head.seller);
            }
            _sigPages[0].removeBlank(deal.head.seqOfDeal, deal.body.buyer);
        }
    }

    function lockDealSubject(uint256 seq) external onlyKeeper returns (bool flag) {
        flag = _repo.lockDealSubject(seq);
    }

    function releaseDealSubject(uint256 seq)
        external onlyDirectKeeper returns (bool flag)
    {
        flag = _repo.releaseDealSubject(seq);
    }

    function clearDealCP(
        uint256 seq,
        bytes32 hashLock,
        uint closingDeadline
    ) external onlyDirectKeeper {
        _repo.clearDealCP(seq, hashLock, closingDeadline);
        emit ClearDealCP(seq, hashLock, closingDeadline);
    }

    function closeDeal(uint256 seq, string memory hashKey)
        external
        onlyDirectKeeper
        returns (bool flag)
    {        
        flag = _repo.closeDeal(seq, hashKey);
        emit CloseDeal(seq, hashKey);
    }

    function directCloseDeal(uint256 seq)
        external
        onlyDirectKeeper
        returns (bool flag)
    {        
        flag = _repo.directCloseDeal(seq);
        emit CloseDeal(seq, '');
    }

    // function revokeDeal(uint256 seq, string memory hashKey)
    //     external
    //     onlyDirectKeeper
    //     returns (bool flag)
    // {
    //     flag = _repo.revokeDeal(seq, hashKey);
    //     emit RevokeDeal(seq, hashKey);
    // }

    function terminateDeal(uint256 seqOfDeal) 
        external onlyKeeper returns(bool flag)
    {
        flag = _repo.terminateDeal(seqOfDeal);
        emit TerminateDeal(seqOfDeal);
    }

    function takeGift(uint256 seq)
        external onlyKeeper returns (bool flag)
    {
        flag = _repo.takeGift(seq);
        emit CloseDeal(seq, "0");
    }

    function setTypeOfIA(uint t) external attorneyOrKeeper() {
        _repo.setTypeOfIA(t);
    }

    //  #################################
    //  ##       查询接口               ##
    //  ################################

    function getTypeOfIA() external view returns (uint8) {
        return _repo.getTypeOfIA();
    }

    function counterOfDeal() public view returns (uint16) {
        return _repo.counterOfDeal();
    }

    function counterOfClosedDeal() public view returns (uint16) {
        return _repo.counterOfClosedDeal();
    }

    function isDeal(uint256 seqOfDeal) public view returns (bool) {
        return _repo.isDeal(seqOfDeal);
    }

    function getHeadOfDeal(uint256 seq) external view returns (DealsRepo.Head memory)
    {
        return _repo.getHeadOfDeal(seq);
    }

    function getBodyOfDeal(uint256 seq) external view returns (DealsRepo.Body memory)
    {
        return _repo.getBodyOfDeal(seq);
    }

    function getHashLockOfDeal(uint256 seq) external view returns (bytes32)
    {
        return _repo.getHashLockOfDeal(seq);
    }
    
    function getDeal(uint256 seqOfDeal) external view returns (DealsRepo.Deal memory)
    {
        return _repo.getDeal(seqOfDeal);
    }

    function getSeqList() external view returns (uint[] memory) {
        return _repo.getSeqList();
    }
}

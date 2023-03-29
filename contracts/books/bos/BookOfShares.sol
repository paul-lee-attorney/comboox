// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfShares.sol";
import "../../common/access/AccessControl.sol";
import "../../common/ruting/ROMSetting.sol";

contract BookOfShares is IBookOfShares, ROMSetting, AccessControl {
    using LockersRepo for LockersRepo.Repo;
    using SharesRepo for SharesRepo.Repo;
    using SharesRepo for SharesRepo.Share;
    using SharesRepo for SharesRepo.Head;
    using SharesRepo for uint256;

    SharesRepo.Repo private _repo;

    LockersRepo.Repo private _lockers;

    //##################
    //##   Modifier   ##
    //##################

    modifier shareExist(uint256 seqOfShare) {
        require(isShare(seqOfShare), "BOS.mf.SE: seqOfShare NOT exist");
        _;
    }

    modifier notFreezed(uint256 seqOfShare) {
        require(_repo.shares[seqOfShare].body.state == 0, 
            "BOS.mf.NF: share is freezed");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== IssueShare ====

    function issueShare(uint256 shareNumber, uint48 payInDeadline, uint64 paid, uint64 par) 
        external onlyKeeper
    {

        SharesRepo.Share memory newShare = 
            _repo.createShare(shareNumber, payInDeadline, paid, par);

        _rom.addMember(newShare.head.shareholder);

        emit IssueShare(newShare.head.seqOfShare, paid, par);

        _rom.addShareToMember(newShare);
        _rom.capIncrease(paid, par);
    }

    function regShare(SharesRepo.Share memory share) 
        public onlyKeeper returns(SharesRepo.Share memory newShare)
    {
        newShare = _repo.regShare(share);
        emit IssueShare(newShare.head.seqOfShare, newShare.body.paid, newShare.body.par);

        _rom.addShareToMember(newShare);
    }

    // ==== PayInCapital ====

    function setPayInAmt(uint256 snOfLocker, uint64 amount) 
        external onlyDirectKeeper
    {
        if (_lockers.lockValue(snOfLocker, amount, uint32(snOfLocker >> 216)))
            emit SetPayInAmt(snOfLocker, amount);
    }

    function requestPaidInCapital(uint256 snOfLocker, string memory hashKey, uint8 salt, uint256 caller)
        external onlyDirectKeeper
    {
        uint64 amount = uint64(_lockers.releaseValue(snOfLocker, hashKey, salt, caller));
        if (amount > 0) {
            SharesRepo.Share storage share = _repo.shares[uint32(snOfLocker >> 216)];
            require(share.head.shareholder == caller, "BOS.RPIC: not shareholder");

            share.payInCapital(amount);
            _rom.changeAmtOfMember(share.head.shareholder, amount, 0, true);
            _rom.capIncrease(amount, 0);
        }
    }

    function withdrawPayInAmt(uint256 snOfLocker) external onlyDirectKeeper {
        if (_lockers.burnLocker(snOfLocker, uint32(snOfLocker >> 216)))
            emit WithdrawPayInAmt(snOfLocker);
    }

    // ==== TransferShare ====

    function transferShare(
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint40 to,
        uint32 price
    ) external onlyKeeper shareExist(seqOfShare) notFreezed(seqOfShare) {
        SharesRepo.Share storage share = _repo.shares[seqOfShare];

        require(to != 0, "BOS.TS: shareholder is ZERO");

        _decreaseShareAmt(share, paid, par);

        _rom.addMember(to);

        SharesRepo.Share memory newShare;

        newShare.head = SharesRepo.Head({
            seqOfShare: 0,
            preSeq: share.head.seqOfShare,            
            class: share.head.class,
            issueDate: uint48(block.timestamp),
            shareholder: to,
            price: price
        });

        newShare.body = SharesRepo.Body({
            payInDeadline: share.body.payInDeadline,
            paid: paid,
            par: par,
            cleanPaid: paid,
            state: 0
        });        

        regShare(newShare);
    }

    // ==== DecreaseCapital ====

    function decreaseCapital(
        uint256 seqOfShare,
        uint64 paid,
        uint64 par
    ) external onlyDirectKeeper shareExist(seqOfShare) notFreezed(seqOfShare) {
        SharesRepo.Share storage share = _repo.shares[seqOfShare];        

        _decreaseShareAmt(share, paid, par);

        _rom.capDecrease(paid, par);
    }

    // ==== cleanAmt ====

    function decreaseCleanPaid(uint256 seqOfShare, uint64 paid)
        external shareExist(seqOfShare) notFreezed(seqOfShare)
    {
        require(msg.sender == _gk.getBook(uint8(TitleOfBooks.BookOfPledges)) ||
        _gk.isKeeper(msg.sender), "BOS.DCA: neither keeper nor BOP");

        emit DecreaseCleanPaid(seqOfShare, paid);
        _repo.shares[seqOfShare].decreaseCleanPaid(paid);
    }

    function increaseCleanPaid(uint256 seqOfShare, uint64 paid)
        external shareExist(seqOfShare) notFreezed(seqOfShare)
    {
        require(msg.sender == _gk.getBook(uint8(TitleOfBooks.BookOfPledges)) ||
        _gk.isKeeper(msg.sender), "BOS.DCA: neither keeper nor BOP");

        emit IncreaseCleanPaid(seqOfShare, paid);
        _repo.shares[seqOfShare].increaseCleanPaid(paid);
    }

    // ==== State & PaidInDeadline ====

    function updateStateOfShare(uint256 seqOfShare, uint8 state)
        external onlyDirectKeeper shareExist(seqOfShare)
    {
        emit UpdateStateOfShare(seqOfShare, state);
        _repo.shares[seqOfShare].body.state = state;
    }

    function updatePaidInDeadline(uint256 seqOfShare, uint48 deadline)
        external onlyDirectKeeper shareExist(seqOfShare)
    {
        emit UpdatePaidInDeadline(seqOfShare, deadline);
        _repo.shares[seqOfShare].updatePayInDeadline(deadline);
    }

    // ==== private funcs ====

    function _deregisterShare(uint256 seqOfShare) private {
        if (_repo.deregShare(seqOfShare))
            emit DeregisterShare(seqOfShare);
    }

    function _payInCapital(SharesRepo.Share storage share, uint64 amount) private 
    {
        emit PayInCapital(share.head.seqOfShare, amount);
        share.payInCapital(amount);
    }

    function _decreaseShareAmt(SharesRepo.Share storage share, uint64 paid, uint64 par) 
        private 
    {
        if (par == share.body.par) {
            _rom.removeShareFromMember(share);
            _repo.deregShare(share.head.seqOfShare);
        } else {
            _subAmtFromShare(share, paid, par);
            _rom.changeAmtOfMember(
                share.head.shareholder,
                paid,
                par,
                false
            );
        }
    }

    function _subAmtFromShare(
        SharesRepo.Share storage share,
        uint64 paid,
        uint64 par
    ) private {

        emit SubAmountFromShare(share.head.seqOfShare, paid, par);
        share.subAmtFromShare(paid, par);
     }

    // ##################
    // ##   查询接口   ##
    // ##################

    function counterOfShares() public view returns (uint32) {
        return _repo.shares[0].head.seqOfShare;
    }

    function counterOfClasses() public view returns (uint16) {
        return _repo.shares[0].head.class;
    }

    // ==== SharesRepo ====

    function isShare(uint256 seqOfShare) public view returns (bool) {
        return _repo.shares[seqOfShare].head.issueDate > 0;
    }

    function getHeadOfShare(uint256 seqOfShare) external view 
        shareExist(seqOfShare) returns (SharesRepo.Head memory head)
    {
        head = _repo.shares[seqOfShare].head;
    }

    function getBodyOfShare(uint256 seqOfShare) external view
        shareExist(seqOfShare) returns (SharesRepo.Body memory body)
    {
        body = _repo.shares[seqOfShare].body;
    }

    function getShare(uint256 seqOfShare) external view shareExist(seqOfShare)
        returns (SharesRepo.Share memory share)
    {
        share = _repo.shares[seqOfShare];
    }

    // ==== PayInCapital ====

    function getLocker(uint256 snOfLocker) external view returns (uint64 amount) {
        amount = uint64(_lockers.lockers[snOfLocker]);
    }

    function getSharesOfClass(uint16 class) external view
        returns (uint256[] memory seqList)
    {
        return _repo.sharesOfClass(class);
    }
}

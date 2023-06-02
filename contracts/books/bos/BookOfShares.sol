// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfShares.sol";
import "../../common/access/AccessControl.sol";

contract BookOfShares is IBookOfShares, AccessControl {
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

    function issueShare(bytes32 shareNumber, uint payInDeadline, uint paid, uint par) 
        external onlyKeeper
    {

        SharesRepo.Share memory newShare = 
            _repo.createShare(shareNumber, payInDeadline, paid, par);

        _gk.getROM().addMember(newShare.head.shareholder);
        _gk.getROM().addShareToMember(newShare);
        _gk.getROM().capIncrease(paid, par);

        emit IssueShare(newShare.head.codifyHead(), paid, par);
    }

    function regShare(SharesRepo.Share memory share) 
        public onlyKeeper returns(SharesRepo.Share memory newShare)
    {
        newShare = _repo.regShare(share);
        _gk.getROM().addShareToMember(newShare);

        emit IssueShare(newShare.head.codifyHead(), newShare.body.paid, newShare.body.par);
    }

    // ==== PayInCapital ====

    function setPayInAmt(bytes32 snOfLocker, uint amount) 
        external onlyDirectKeeper
    {
        if (_lockers.lockValue(snOfLocker, amount, uint32(uint(snOfLocker) >> 216)))
            emit SetPayInAmt(snOfLocker, amount);
    }

    function requestPaidInCapital(bytes32 snOfLocker, string memory hashKey, uint salt, uint256 caller)
        external onlyDirectKeeper
    {
        uint64 amount = uint64(_lockers.releaseValue(snOfLocker, hashKey, salt, caller));
        if (amount > 0) {
            SharesRepo.Share storage share = _repo.shares[uint32(uint(snOfLocker) >> 216)];
            require(share.head.shareholder == caller, "BOS.RPIC: not shareholder");

            share.payInCapital(amount);
            _gk.getROM().changeAmtOfMember(share.head.shareholder, amount, 0, amount, true);
            _gk.getROM().capIncrease(amount, 0);
        }
    }

    function withdrawPayInAmt(bytes32 snOfLocker) external onlyDirectKeeper {
        if (_lockers.burnLocker(snOfLocker, uint32(uint(snOfLocker) >> 216)))
            emit WithdrawPayInAmt(snOfLocker);
    }

    // ==== TransferShare ====

    function transferShare(
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint to,
        uint priceOfPaid,
        uint priceOfPar
    ) external onlyKeeper shareExist(seqOfShare) notFreezed(seqOfShare) {
        SharesRepo.Share storage share = _repo.shares[seqOfShare];

        require(to != 0, "BOS.TS: shareholder is ZERO");

        _decreaseShareAmt(share, paid, par);

        _gk.getROM().addMember(to);

        SharesRepo.Share memory newShare;

        newShare.head = SharesRepo.Head({
            seqOfShare: 0,
            preSeq: share.head.seqOfShare,            
            class: share.head.class,
            issueDate: uint48(block.timestamp),
            shareholder: uint40(to),
            priceOfPaid: uint32(priceOfPaid),
            priceOfPar: uint32(priceOfPar),
            para: 0,
            argu: 0
        });

        newShare.body = SharesRepo.Body({
            payInDeadline: share.body.payInDeadline,
            paid: uint64(paid),
            par: uint64(par),
            cleanPaid: uint64(paid),
            state: 0,
            para: 0
        });        

        regShare(newShare);
    }

    // ==== DecreaseCapital ====

    function decreaseCapital(
        uint256 seqOfShare,
        uint paid,
        uint par
    ) external onlyDirectKeeper shareExist(seqOfShare) notFreezed(seqOfShare) {
        SharesRepo.Share storage share = _repo.shares[seqOfShare];        

        _decreaseShareAmt(share, paid, par);

        _gk.getROM().capDecrease(paid, par);
    }

    // ==== cleanAmt ====

    function decreaseCleanPaid(uint256 seqOfShare, uint paid)
        external shareExist(seqOfShare) notFreezed(seqOfShare)
    {
        require(msg.sender == address(_gk.getBOP()) ||
        _gk.isKeeper(msg.sender), "BOS.DCP: neither keeper nor BOP");

        SharesRepo.Share storage share = _repo.shares[seqOfShare];

        share.decreaseCleanPaid(paid);
        _gk.getROM().changeAmtOfMember(share.head.shareholder, 0, 0, paid, false);
        emit DecreaseCleanPaid(seqOfShare, paid);
    }

    function increaseCleanPaid(uint256 seqOfShare, uint paid)
        external shareExist(seqOfShare) notFreezed(seqOfShare)
    {
        require(msg.sender == address(_gk.getBOP()) ||
        _gk.isKeeper(msg.sender), "BOS.DCA: neither keeper nor BOP");

        SharesRepo.Share storage share = _repo.shares[seqOfShare];

        share.increaseCleanPaid(paid);
        _gk.getROM().changeAmtOfMember(share.head.shareholder, 0, 0, paid, true);
        emit IncreaseCleanPaid(seqOfShare, paid);
    }

    // ==== State & PaidInDeadline ====

    function updateStateOfShare(uint256 seqOfShare, uint state)
        external onlyDirectKeeper shareExist(seqOfShare)
    {
        emit UpdateStateOfShare(seqOfShare, state);
        _repo.shares[seqOfShare].body.state = uint8(state);
    }

    function updatePaidInDeadline(uint256 seqOfShare, uint deadline)
        external onlyDirectKeeper shareExist(seqOfShare)
    {
        _repo.shares[seqOfShare].updatePayInDeadline(deadline);
        emit UpdatePaidInDeadline(seqOfShare, deadline);
    }

    // ==== private funcs ====

    function _deregisterShare(uint256 seqOfShare) private {
        if (_repo.deregShare(seqOfShare))
            emit DeregisterShare(seqOfShare);
    }

    function _payInCapital(SharesRepo.Share storage share, uint amount) private 
    {
        emit PayInCapital(share.head.seqOfShare, amount);
        share.payInCapital(amount);
    }

    function _decreaseShareAmt(SharesRepo.Share storage share, uint paid, uint par) 
        private 
    {
        if (par == share.body.par) {
            _gk.getROM().removeShareFromMember(share);
            _repo.deregShare(share.head.seqOfShare);
        } else {
            _subAmtFromShare(share, paid, par);
            _gk.getROM().changeAmtOfMember(
                share.head.shareholder,
                paid,
                par,
                paid,
                false
            );
        }
    }

    function _subAmtFromShare(
        SharesRepo.Share storage share,
        uint paid,
        uint par
    ) private {
        share.subAmtFromShare(paid, par);
        emit SubAmountFromShare(share.head.seqOfShare, paid, par);
     }

    // ##################
    // ##   查询接口   ##
    // ##################

    function counterOfShares() public view returns (uint32) {
        return _repo.counterOfShares();
    }

    function counterOfClasses() public view returns (uint16) {
        return _repo.counterOfClasses();
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

    function getLocker(bytes32 snOfLocker) external view returns (uint64 amount) {
        amount = uint64(_lockers.lockers[snOfLocker]);
    }

    function getSharesOfClass(uint class) external view
        returns (uint256[] memory seqList)
    {
        return _repo.sharesOfClass(class);
    }
}

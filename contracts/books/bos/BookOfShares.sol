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
    using LockersRepo for bytes32;
    using SharesRepo for SharesRepo.Repo;
    using SharesRepo for SharesRepo.Share;
    using SharesRepo for SharesRepo.Head;
    using SharesRepo for uint256;

    IGeneralKeeper private _gk = _getGK();
    IBookOfMembers private _bom = _gk.getBOM();
    IBookOfPledges private _bop = _gk.getBOP();

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
            _repo.addShare(shareNumber, payInDeadline, paid, par);
        
        require ( newShare.head.issueDate <= newShare.body.payInDeadline, 
            "BOS.issueShare: issueDate later than payInDeadline");

        _bom.addMember(newShare.head.shareholder);
        _bom.addShareToMember(newShare);
        _bom.capIncrease(paid, par);

        emit IssueShare(newShare.head.codifyHead(), paid, par);
    }

    function regShare(SharesRepo.Share memory share) 
        public onlyKeeper returns(SharesRepo.Share memory newShare)
    {
        newShare = _repo.regShare(share);
        _bom.addShareToMember(newShare);

        emit IssueShare(newShare.head.codifyHead(), newShare.body.paid, newShare.body.par);
    }

    // ==== PayInCapital ====

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) 
        external onlyDK
    {
        SharesRepo.Share storage share = _repo.shares[seqOfShare];

        LockersRepo.Head memory head = LockersRepo.Head({
            from: share.head.seqOfShare,
            to: share.head.shareholder,
            expireDate: uint48(expireDate),
            value: uint128(amt)
        });

        _lockers.lockPoints(head, hashLock);
        emit SetPayInAmt(LockersRepo.codifyHead(head), hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) 
        external onlyDK
    {
        LockersRepo.Head memory head = 
            _lockers.pickupPoints(hashLock, hashKey, 0);
        if (head.value > 0) {
            SharesRepo.Share storage share = _repo.shares[head.from];
            // require(share.head.shareholder == caller, "BOS.RPIC: not shareholder");

            _payInCapital(share, head.value);
            _bom.changeAmtOfMember(share.head.shareholder, head.value, 0, head.value, true);
            _bom.capIncrease(head.value, 0);
        }
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        LockersRepo.Head memory head = 
            _lockers.withdrawDeposit(hashLock, seqOfShare);
        emit WithdrawPayInAmt(head.from, head.value);
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

        _bom.addMember(to);

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
    ) external onlyDK shareExist(seqOfShare) notFreezed(seqOfShare) {
        SharesRepo.Share storage share = _repo.shares[seqOfShare];        

        _decreaseShareAmt(share, paid, par);

        _bom.capDecrease(paid, par);
    }

    // ==== cleanAmt ====

    function decreaseCleanPaid(uint256 seqOfShare, uint paid)
        external shareExist(seqOfShare) notFreezed(seqOfShare)
    {
        require(msg.sender == address(_bop) ||
        _gk.isKeeper(msg.sender), "BOS.DCP: neither keeper nor BOP");

        SharesRepo.Share storage share = _repo.shares[seqOfShare];

        share.decreaseCleanPaid(paid);
        _bom.changeAmtOfMember(share.head.shareholder, 0, 0, paid, false);
        emit DecreaseCleanPaid(seqOfShare, paid);
    }

    function increaseCleanPaid(uint256 seqOfShare, uint paid)
        external shareExist(seqOfShare) notFreezed(seqOfShare)
    {
        require(msg.sender == address(_bop) ||
        _gk.isKeeper(msg.sender), "BOS.DCA: neither keeper nor BOP");

        SharesRepo.Share storage share = _repo.shares[seqOfShare];

        share.increaseCleanPaid(paid);
        _bom.changeAmtOfMember(share.head.shareholder, 0, 0, paid, true);
        emit IncreaseCleanPaid(seqOfShare, paid);
    }

    // ==== State & PaidInDeadline ====

    function updateStateOfShare(uint256 seqOfShare, uint state)
        external onlyDK shareExist(seqOfShare)
    {
        emit UpdateStateOfShare(seqOfShare, state);
        _repo.shares[seqOfShare].body.state = uint8(state);
    }

    // function updatePaidInDeadline(uint256 seqOfShare, uint deadline)
    //     external onlyDK shareExist(seqOfShare)
    // {
    //     _repo.shares[seqOfShare].updatePayInDeadline(deadline);
    //     emit UpdatePaidInDeadline(seqOfShare, deadline);
    // }

    // ==== private funcs ====

    function _deregisterShare(uint256 seqOfShare) private {
        if (_repo.deregShare(seqOfShare))
            emit DeregisterShare(seqOfShare);
    }

    function _payInCapital(SharesRepo.Share storage share, uint amount) private 
    {
        share.payInCapital(amount);
        emit PayInCapital(share.head.seqOfShare, amount);
    }

    function _decreaseShareAmt(SharesRepo.Share storage share, uint paid, uint par) 
        private 
    {
        if (par == share.body.par) {
            _bom.removeShareFromMember(share);
            _repo.deregShare(share.head.seqOfShare);
        } else {
            _subAmtFromShare(share, paid, par);
            _bom.changeAmtOfMember(
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

    function getLocker(bytes32 hashLock) external view returns (LockersRepo.Locker memory locker) {
        locker = _lockers.getLocker(hashLock);
    }

    function getLocksList() external view returns (bytes32[] memory) {
        return _lockers.getSnList();
    }

    function getSharesOfClass(uint class) external view
        returns (uint256[] memory seqList)
    {
        return _repo.sharesOfClass(class);
    }
}

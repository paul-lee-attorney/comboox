// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfShares.sol";

import "../../common/lib/SharesRepo.sol";
import "../../common/lib/EnumerableSet.sol";

import "../../common/access/AccessControl.sol";

import "../../common/ruting/ROMSetting.sol";

contract BookOfShares is IBookOfShares, ROMSetting, AccessControl {
    using SharesRepo for SharesRepo.Repo;
    using SharesRepo for SharesRepo.Share;
    using SharesRepo for SharesRepo.Head;
    using SharesRepo for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    SharesRepo.Repo private _repo;

    // zero(16b) & ssn & expireDate & shareholder & hashLock (128b) => amount
    mapping(bytes32 => uint256) private _lockers;

    //##################
    //##   Modifier   ##
    //##################

    modifier shareExist(uint256 seq) {
        require(isShare(seq), "BOS.mf.SE: seq NOT exist");
        _;
    }

    modifier notFreezed(uint256 seq) {
        require(_repo.shares[seq].head.state == 0, 
            "BOS.mf.NF: share is freezed");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== IssueShare ====

    function issueShare(
        uint256 shareNumber,
        uint64 paid,
        uint64 par
    ) external onlyKeeper {
        SharesRepo.Head memory head = shareNumber.snParser();
        IRegisterOfMembers _rom = _getROM();        

        _rom.addMember(head.shareholder);

        uint32 seq = _repo.issueShare(shareNumber, paid, par);

        emit IssueShare(seq, paid, par);

        _rom.addShareToMember(seq, head.shareholder);
        _rom.capIncrease(paid, par);
    }

    function regShare(
        SharesRepo.Head memory head,
        uint64 paid,
        uint64 par
    ) public onlyKeeper {
        head.seq = uint32(_repo.regShare(head, paid, par));
        emit IssueShare(head.seq, paid, par);
        _getROM().addShareToMember(head.seq, head.shareholder);
    }


    // ==== PayInCapital ====

    function setPayInAmt(bytes32 hashLock, uint64 amount) external onlyDirectKeeper {
        require(_lockers[hashLock] == 0, "BOS.SPIA: locker occupied");
        emit SetPayInAmt(hashLock, amount);
        _lockers[hashLock] = amount;
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey)
        external
        onlyDirectKeeper
    {
        require(
            bytes28(hashLock << 32) == bytes28(keccak256(bytes(hashKey)) << 32),
            "BOS.RPIC: wrong key"
        );

        uint64 amount = uint64(_lockers[hashLock]);

        SharesRepo.Share storage share = _repo.shares[uint32(bytes4(hashLock))];
        IRegisterOfMembers _rom = _getROM();

        share.payInCapital(amount);
        _rom.changeAmtOfMember(share.head.shareholder, amount, 0, true);
        _rom.capIncrease(amount, 0);

        delete _lockers[hashLock];
    }

    function withdrawPayInAmt(bytes32 hashLock) external onlyDirectKeeper {
        require(
            _repo.shares[uint32(bytes4(hashLock))].head.payInDeadline < block.timestamp,
            "BOS.WPIA: still within effective period"
        );

        emit WithdrawPayInAmt(hashLock);
        delete _lockers[hashLock];
    }

    // ==== TransferShare ====

    function transferShare(
        uint256 seq,
        uint64 paid,
        uint64 par,
        uint40 to,
        uint32 price
    ) external onlyKeeper shareExist(seq) notFreezed(seq) {
        SharesRepo.Share storage share = _repo.shares[seq];

        require(to != 0, "BOS.TS: shareholder is ZERO");

        _decreaseShareAmt(share, paid, par);

        _getROM().addMember(to);

        SharesRepo.Head memory head = SharesRepo.Head({
            seq: 0,
            preSeq: share.head.seq,            
            class: share.head.class,
            issueDate: uint48(block.timestamp),
            payInDeadline: share.head.payInDeadline,
            shareholder: to,
            price: price,
            state: 0
        });

        regShare(head, paid, par);
    }

    // ==== DecreaseCapital ====

    function decreaseCapital(
        uint256 seq,
        uint64 paid,
        uint64 par
    ) external onlyDirectKeeper shareExist(seq) notFreezed(seq) {
        SharesRepo.Share storage share = _repo.shares[seq];        

        _decreaseShareAmt(share, paid, par);

        _getROM().capDecrease(paid, par);
    }

    // ==== cleanAmt ====

    function decreaseCleanAmt(uint256 seq, uint64 paid, uint64 par)
        external
        onlyKeeper
        shareExist(seq)
        notFreezed(seq)
    {
        emit DecreaseCleanAmt(seq, paid, par);
        _repo.shares[seq].decreaseCleanAmt(paid, par);
    }

    function increaseCleanAmt(uint256 seq, uint64 paid, uint64 par)
        external
        onlyKeeper
        shareExist(seq)
        notFreezed(seq)
    {
        emit IncreaseCleanAmt(seq, paid, par);
        _repo.shares[seq].increaseCleanAmt(paid, par);
    }

    // ==== State & PaidInDeadline ====

    function updateStateOfShare(uint256 seq, uint8 state)
        external
        onlyDirectKeeper
        shareExist(seq)
    {
        emit UpdateStateOfShare(seq, state);
        _repo.shares[seq].head.state = state;
    }

    /// @param seq - 股票短号
    /// @param deadline - 实缴出资期限
    function updatePaidInDeadline(uint256 seq, uint48 deadline)
        external
        onlyDirectKeeper
        shareExist(seq)
    {
        emit UpdatePaidInDeadline(seq, deadline);
        _repo.shares[seq].updatePayInDeadline(deadline);
    }

    // ==== private funcs ====

    function _deregisterShare(uint256 seq) private {
        if (_repo.deregShare(seq))
            emit DeregisterShare(seq);
    }

    function _payInCapital(SharesRepo.Share storage share, uint64 amount) private {
        emit PayInCapital(share.head.seq, amount);
        share.payInCapital(amount);
    }

    function _decreaseShareAmt(
        SharesRepo.Share storage share,
        uint64 paid,
        uint64 par
    ) private {

        IRegisterOfMembers _rom = _getROM();

        if (par == share.body.par) {
            _rom.removeShareFromMember(share.head.seq, share.head.shareholder);
            _repo.deregShare(share.head.seq);
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

        emit SubAmountFromShare(share.head.seq, paid, par);
        share.subAmtFromShare(paid, par);
     }

    // ##################
    // ##   查询接口   ##
    // ##################

    function counterOfShares() public view returns (uint32) {
        return _repo.shares[0].head.seq;
    }

    function counterOfClasses() public view returns (uint16) {
        return _repo.shares[0].head.class;
    }

    // ==== SharesRepo ====

    function isShare(uint256 seq) public view returns (bool) {
        return _repo.shares[seq].head.issueDate > 0;
    }

    function getHeadOfShare(uint256 seq)
        external
        view
        shareExist(seq)
        returns (SharesRepo.Head memory head)
    {
        head = _repo.shares[seq].head;
    }

    function getBodyOfShare(uint256 seq)
        external
        view
        shareExist(seq)
        returns (SharesRepo.Body memory body)
    {
        body = _repo.shares[seq].body;
    }

    function getShare(uint256 seq)
        external
        view
        shareExist(seq)
        returns (SharesRepo.Share memory share)
    {
        share = _repo.shares[seq];
    }

    // ==== PayInCapital ====

    function getLocker(bytes32 hashLock) external view returns (uint64 amount) {
        amount = uint64(_lockers[hashLock]);
    }

    function getAttrOfClass(uint16 class) external view
        returns (uint256[] memory seqList, uint256[] memory members)
    {
        return _repo.attrOfClass(class);
    }
}

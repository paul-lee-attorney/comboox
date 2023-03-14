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

    // _shares[0].body {
    //     paid: counterOfShares;
    //     par: counterOfClass;
    // }

    // seq => Share
    mapping(uint256 => Share) private _shares;

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
        require(_shares[seq].head.state == 0, "BOS.mf.NF: share is freezed");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    // ==== IssueShare ====

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        head = Head({
            class: uint16(bytes2(sn)),
            seq: uint32(bytes4(sn<<16)),
            preSeq: uint32(bytes4(sn<<48)), 
            issueDate: uint48(bytes6(sn<<80)),
            paidInDeadline: uint48(bytes6(sn<<128)),
            shareholder: uint40(bytes5(sn<<176)),
            price: uint32(bytes4(sn<<216)),
            state: uint8(sn[31])
        });
    }

    function issueShare(
        bytes32 shareNumber,
        uint64 paid,
        uint64 par
    ) external onlyKeeper {
        Head memory head = snParser(shareNumber);

        require(
            head.shareholder != 0,
            "BOS.IS: zero shareholder"
        );

        // uint48 issueDate = sharenumber.issueDate();
        if (head.issueDate == 0) head.issueDate = uint48(block.timestamp);
        else require( head.issueDate <= block.timestamp,
            "BOS.IS: future issueDate");

        require(head.issueDate <= head.paidInDeadline, 
            "BOS.IS: issueDate LATER than paidInDeadline");

        require(paid <= par, "BOS.IS: paid BIGGER than par");

        // 判断是否需要添加新股东，若添加是否会超过法定人数上限
        _getROM().addMember(head.shareholder);

        if (head.class > counterOfClasses()) {
            _increaseCounterOfClasses();
            head.class = counterOfClasses();
        }

        // 在《股权簿》中添加新股票（签发新的《出资证明书》）
        regShare(head, paid, par);

        // 将股票编号加入《股东名册》记载的股东名下
        // _getROM().addShareToMember(head.seq, head.shareholder);

        // 增加“认缴出资”和“实缴出资”金额
        _getROM().capIncrease(paid, par);
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
        Share storage share = _shares[uint32(bytes4(hashLock))];

        require(
            share.head.paidInDeadline >= block.timestamp,
            "BOS.RPIC: missed paidInDate"
        );

        require(
            bytes28(hashLock << 32) == bytes28(keccak256(bytes(hashKey)) << 32),
            "BOS.RPIC: wrong key"
        );

        uint64 amount = uint64(_lockers[hashLock]);

        // 增加“股票”项下实缴出资金额
        _payInCapital(share, amount);

        _getROM().changeAmtOfMember(share.head.shareholder, amount, 0, true);

        // 增加公司的“实缴出资”总额
        _getROM().capIncrease(amount, 0);

        // remove payInAmount;
        delete _lockers[hashLock];
    }

    function withdrawPayInAmt(bytes32 hashLock) external onlyDirectKeeper {
        require(
            _shares[uint32(bytes4(hashLock))].head.paidInDeadline < block.timestamp,
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
        Share storage share = _shares[seq];

        require(to != 0, "BOS.TS: shareholder is ZERO");

        _decreaseShareAmt(share, paid, par);

        // 判断是否需要新增股东，若需要判断是否超过法定人数上限
        _getROM().addMember(to);

        Head memory head = Head({
            class: share.head.class,
            seq: 0,
            preSeq: share.head.seq,            
            issueDate: uint48(block.timestamp),
            paidInDeadline: share.head.paidInDeadline,
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
        Share storage share = _shares[seq];

        // 减少特定“股票”项下的认缴和实缴金额
        _decreaseShareAmt(share, paid, par);

        // 减少公司“注册资本”和“实缴出资”总额
        _getROM().capDecrease(paid, par);
    }

    // ==== cleanAmt ====

    function decreaseCleanAmt(uint256 seq, uint64 paid, uint64 par)
        external
        onlyKeeper
        shareExist(seq)
        notFreezed(seq)
    {
        Share storage share = _shares[seq];

        require(paid <= share.body.cleanPaid, "BOS.DCA: INSUFFICIENT cleanPaid");
        require(par <= share.body.cleanPar, "BOS.DCA: INSUFFICIENT cleanPar");

        emit DecreaseCleanAmt(seq, paid, par);

        share.body.cleanPaid -= paid;
        share.body.cleanPar -= par;
    }

    function increaseCleanAmt(uint256 seq, uint64 paid, uint64 par)
        external
        onlyKeeper
        shareExist(seq)
        notFreezed(seq)
    {
        Share storage share = _shares[seq];
        require(
            share.body.paid >= (share.body.cleanPaid + paid),
            "BOS.ICA: paid overflow"
        );
        require(
            share.body.par >= (share.body.cleanPar + par),
            "BOS.ICA: par overflow"
        );

        emit IncreaseCleanAmt(seq, paid, par);

        share.body.cleanPaid += paid;
        share.body.cleanPar += par;
    }

    // ==== State & PaidInDeadline ====

    /// @param seq - 股票短号
    /// @param state - 股票状态 （0:正常，1:查封 ）
    function updateStateOfShare(uint256 seq, uint8 state)
        external
        onlyDirectKeeper
        shareExist(seq)
    {
        emit UpdateStateOfShare(seq, state);
        _shares[seq].head.state = state;
    }

    /// @param seq - 股票短号
    /// @param paidInDeadline - 实缴出资期限
    function updatePaidInDeadline(uint256 seq, uint48 paidInDeadline)
        external
        onlyDirectKeeper
        shareExist(seq)
    {
        emit UpdatePaidInDeadline(seq, paidInDeadline);
        _shares[seq].head.paidInDeadline = paidInDeadline;
    }

    // ==== private funcs ====

    function _increaseCounterOfShares() private {
        _shares[0].body.paid++;
    }

    function _increaseCounterOfClasses() private {
        _shares[0].body.par++;
    }

    function regShare(
        Head memory head,
        uint64 paid,
        uint64 par
    ) public onlyKeeper {

        _increaseCounterOfShares();
        head.seq = counterOfShares();

        Share storage share = _shares[head.seq];

        emit IssueShare(head.seq, paid, par);

        share.head = head;

        share.body = Body({
            paid: paid,
            par: par,
            cleanPaid: paid,
            cleanPar: par
        });

        _getROM().addShareToMember(head.seq, head.shareholder);
    }

    function _deregisterShare(uint256 seq) private {
        emit DeregisterShare(seq);
        delete _shares[seq];
    }

    function _payInCapital(Share storage share, uint64 amount) private {
        uint48 paidInDate = uint48(block.timestamp);

        require(
            paidInDate < share.head.paidInDeadline,
            "BOS.PIC: missed payInDeadline"
        );
        require(
            share.body.paid + amount <= share.body.par,
            "BOS.PIC: amount overflow"
        );

        emit PayInCapital(share.head.seq, amount, paidInDate);
        share.body.paid += amount; //溢出校验已通过

        share.body.cleanPaid += amount;
        share.body.cleanPar += amount;
    }

    function _decreaseShareAmt(
        Share storage share,
        uint64 paid,
        uint64 par
    ) private {

        require(par > 0, "par is ZERO");
        require(share.body.cleanPar >= par, "par OVERFLOW");
        require(share.body.cleanPaid >= paid, "cleanPaid OVERFLOW");
        // require(share.state < 4, "FREEZED share");
        require(paid <= par, "paid BIGGER than par");

        // 若拟降低的面值金额等于股票面值，则删除相关股票
        if (par == share.body.par) {
            _getROM().removeShareFromMember(share.head.seq, share.head.shareholder);
            _deregisterShare(share.head.seq);
        } else {
            // 仅调低认缴和实缴金额，保留原股票
            _subAmountFromShare(share, paid, par);
            _getROM().changeAmtOfMember(
                share.head.shareholder,
                paid,
                par,
                false
            );
        }
    }

    function _subAmountFromShare(
        Share storage share,
        uint64 paid,
        uint64 par
    ) private {

        emit SubAmountFromShare(share.head.seq, paid, par);

        share.body.paid -= paid;
        share.body.par -= par;

        share.body.cleanPaid -= paid;
        share.body.cleanPar -= par;
    }

    // ##################
    // ##   查询接口   ##
    // ##################

    function counterOfShares() public view returns (uint32) {
        return uint32(_shares[0].body.paid);
    }

    function counterOfClasses() public view returns (uint16) {
        return uint16(_shares[0].body.par);
    }

    // ==== SharesRepo ====

    function isShare(uint256 seq) public view returns (bool) {
        return _shares[seq].head.seq > 0;
    }

    function getHeadOfShare(uint256 seq)
        external
        view
        shareExist(seq)
        returns (Head memory head)
    {
        head = _shares[seq].head;
    }

    function getBodyOfShare(uint256 seq)
        external
        view
        shareExist(seq)
        returns (Body memory body)
    {
        body = _shares[seq].body;
    }

    function getShare(uint256 seq)
        external
        view
        shareExist(seq)
        returns (Share memory share)
    {
        share = _shares[seq];
    }

    // ==== PayInCapital ====

    function getLocker(bytes32 hashLock) external view returns (uint64 amount) {
        amount = uint64(_lockers[hashLock]);
    }
}

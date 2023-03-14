// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/Checkpoints.sol";
import "./PledgesRepo.sol";


import "../../books/bos/IBookOfShares.sol";
// import "../../books/bop/IBookOfPledges.sol";

library OptionsRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.History;

    enum OptTypes {
        CallPrice,          // 0
        PutPrice,           // 1
        CallRoe,            // 2
        PutRoe,             // 3
        CallIrr,            // 4
        PutIrr,             // 5
        CallPriceWithCnds,  // 6
        PutPriceWithCnds,   // 7
        CallRoeWithCnds,    // 8
        PutRoeWithCnds,     // 9
        CallIrrWithCnds,    // 10
        PutIrrWithCnds      // 11
    }

    enum OptStates {
        Pending,    // 0
        Issued,     // 1    
        Executed,   // 2
        Futured,    // 3
        Pledged,    // 4
        Closed,     // 5
        Revoked,    // 6
        Expired     // 7
    }

    enum FutureStates{
        Pending,
        Issued,
        Closed,
        Revoked,
        Expired
    }

    enum LogOps {
        NotApplicable,
        And,
        Or,
        AndOr,
        OrAnd,
        Equal,
        NotEqual
    }

    enum ComOps {
        NotApplicable,
        Equal,
        NotEqual,
        Bigger,
        Smaller,
        BiggerOrEqual,
        SmallerOrEqual
    }

    struct Head {
        uint32 seqOfOpt;    //4     0
        uint8 typeOfOpt;      //1 5   4
        uint32 rate;        //4 9   5
        uint48 triggerDate; //6 15  9
        uint8 execDays;     //1 16  15
        uint8 closingDays;  //1 17  16
        uint16 classOfShare;    //2 19  17
        uint8 logicOperator;    //1 20  19
        uint8 compOperator1;   //1 21    20
        uint32 para1;          //4 25  21
        uint8 compOperator2;   //1 26 25
        uint32 para2;          //4 30  26
        uint8 state;            //1 31  30
    }

    struct Body {
        uint48 closingDate;
        uint40 rightholder;
        uint40 obligor;
        uint64 paid;
        uint64 par;
    }

    struct Future {
        uint32 seqOfFuture;
        uint32 seqOfShare;
        uint40 buyer;
        uint64 paid;
        uint64 par;
        uint8 state;
    }

    struct Oracle {
        uint48 timestamp;
        uint32 data1;
        uint32 data2;
    }

    struct Option {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    struct Record {
        EnumerableSet.UintSet obligors;
        mapping(uint256 => Future) futures;
        mapping(uint256 => PledgesRepo.Pledge) pledges;
        Checkpoints.History oracles;
    }

    struct Repo {
        mapping(uint256 => Option) options;
        mapping(uint256 => Record) records;
    }

    // ###############
    // ##   写接口   ##
    // ###############

    // ==== Repo ====

    function snParser(bytes32 sn) public pure returns (Head memory head) {
        head = Head({
            seqOfOpt: uint32(bytes4(sn)),
            typeOfOpt: uint8(sn[4]),
            rate: uint32(bytes4(sn<<40)),
            triggerDate: uint48(bytes6(sn<<72)),
            execDays: uint8(sn[15]),
            closingDays: uint8(sn[16]),
            classOfShare: uint16(bytes2(sn<<128)),
            logicOperator: uint8(sn[18]),
            compOperator1: uint8(sn[19]),
            para1: uint32(bytes4(sn<<160)),
            compOperator2: uint8(sn[25]),
            para2: uint32(bytes4(sn<<200)),
            state: uint8(sn[30])
        });
    }

    function issueOption(
        Repo storage repo,
        bytes32 sn,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    ) public returns (uint32 seqOfOpt) {

        Head memory head = snParser(sn);
        seqOfOpt = createOption(repo, head, rightholder, obligor, paid, par);
    }

    function createOption(
        Repo storage repo,
        Head memory head,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    ) public returns(uint32 seqOfOpt) {

        require(head.rate > 0, "OR.CO: ZERO rate");
        require(
            head.triggerDate > block.timestamp,
            "OR.CO: triggerDate not future"
        );
        require(
            head.execDays > 0,
            "OR.CO: ZERO execDays"
        );
        require(head.closingDays > 0, "OR.CO: ZERO closingDays");

        require(rightholder > 0, "OR.CO: ZERO rightholder");
        require(obligor > 0, "OR.CO: ZERO obligor");

        require(paid > 0, "OR.CO: ZERO paid");
        require(par >= paid, "OR.CO: INSUFFICIENT par");

        increaseCounterOfOptions(repo);

        seqOfOpt = counterOfOptions(repo);

        head.seqOfOpt = seqOfOpt;        
        head.state = uint8(OptStates.Pending);

        Option storage opt = repo.options[seqOfOpt];

        opt.head = head;
        opt.body = Body({
            closingDate: (head.triggerDate + uint48(head.execDays + head.closingDays) * 86400),
            rightholder: uint40(rightholder),
            obligor: uint40(obligor),
            paid: paid,
            par: par
        });

        repo.records[seqOfOpt].obligors.add(obligor);
    }

    // ==== Option ====

    function execOption(
        Repo storage repo,
        uint256 seqOfOpt
    ) public {
        Option storage opt = repo.options[seqOfOpt]; 
        Record storage rcd = repo.records[seqOfOpt];

        require(
            opt.head.state == uint8(OptStates.Issued),
            "OR.EO: wrong state of Opt"
        );
        require(
            block.timestamp >= opt.head.triggerDate,
            "OR.EO: NOT reached TriggerDate"
        );

        if (opt.head.execDays > 0)
            require(
                block.timestamp <= opt.head.triggerDate + opt.head.execDays * 86400,
                "OR.EO: NOT in exercise period"
            );

        Checkpoints.Checkpoint memory cp = rcd.oracles.latest();

        if (opt.head.typeOfOpt > uint8(OptTypes.PutIrr))
            require(
                checkConditions(opt.head, uint32(cp.paid), uint32(cp.par)),
                "OR.EO: conditions NOT satisfied"
            );

        opt.body.closingDate = uint48(block.timestamp) + opt.head.closingDays * 86400;
        opt.head.state = uint8(OptStates.Executed);
    }

    // --- Head ----

    function checkConditions(
        Head memory head,
        uint32 data1,
        uint32 data2
    ) public pure returns (bool flag) {
        bool flag1;
        bool flag2;

        if (head.compOperator1 == uint8(ComOps.Equal)) flag1 = data1 == head.para1;
        else if (head.compOperator1 == uint8(ComOps.NotEqual)) flag1 = data1 != head.para1;
        else if (head.compOperator1 == uint8(ComOps.Bigger)) flag1 = data1 > head.para1;
        else if (head.compOperator1 == uint8(ComOps.Smaller)) flag1 = data1 < head.para1;
        else if (head.compOperator1 == uint8(ComOps.BiggerOrEqual)) flag1 = data1 >= head.para1;
        else if (head.compOperator1 == uint8(ComOps.SmallerOrEqual)) flag1 = data1 <= head.para1;

        if (head.compOperator2 == uint8(ComOps.Equal)) flag2 = data2 == head.para2;
        else if (head.compOperator2 == uint8(ComOps.NotEqual)) flag2 = data2 != head.para2;
        else if (head.compOperator2 == uint8(ComOps.Bigger)) flag2 = data2 > head.para2;
        else if (head.compOperator2 == uint8(ComOps.Smaller)) flag2 = data2 < head.para2;
        else if (head.compOperator2 == uint8(ComOps.BiggerOrEqual)) flag2 = data2 >= head.para2;
        else if (head.compOperator2 == uint8(ComOps.SmallerOrEqual)) flag2 = data2 <= head.para2;

        if (head.logicOperator == uint8(LogOps.And)) flag = flag1 && flag2;
        else if (head.logicOperator == uint8(LogOps.Or)) flag = flag1 || flag2;
        else if (head.logicOperator == uint8(LogOps.AndOr)) flag = flag1;
        else if (head.logicOperator == uint8(LogOps.OrAnd)) flag = flag2;
        else if (head.logicOperator == uint8(LogOps.Equal)) flag = flag1 == flag2;
        else if (head.logicOperator == uint8(LogOps.NotEqual)) flag = flag1 != flag2;
    }

    // ==== Futures ====

    function addFuture(
        Repo storage repo,
        uint256 seqOfOpt,
        IBookOfShares.Share memory share,
        Future memory future
    ) public returns (bool flag) {
        Option storage opt = repo.options[seqOfOpt];
        Record storage rcd = repo.records[seqOfOpt];

        require(
            block.timestamp <= opt.body.closingDate,
            "OR.AF: MISSED closingDate"
        );
        require(opt.head.state == uint8(OptStates.Executed), 
            "OR.AF: option NOT executed");

        if (opt.head.typeOfOpt % 2 == 1) {
            require(
                opt.body.rightholder == share.head.shareholder,
                "OR.AF: WRONG shareholder"
            );
            require (
                rcd.obligors.contains(future.buyer),
                "OR.AF: wrong future buyer"
            );
        } else {
            require(
                rcd.obligors.contains(share.head.shareholder),
                "OR.AF: WRONG sharehoder"
            );
            require(
                opt.body.rightholder == future.buyer,
                "OR.AF: Wrong future buyer"
            );
        }

        require(opt.body.paid >= rcd.futures[0].paid + future.paid, 
            "NOT sufficient paid");
        require(opt.body.par >= rcd.futures[0].par + future.par, 
            "NOT sufficient par");
        
        rcd.futures[0].paid += future.paid;
        rcd.futures[0].par += future.par;
        
        _increaseCounterOfFutures(rcd);
        future.seqOfFuture = counterOfFutures(rcd);

        rcd.futures[future.seqOfFuture] = future;

        if (opt.body.par == rcd.futures[0].par && 
            opt.body.paid == rcd.futures[0].paid) 
        {
            opt.head.state = uint8(OptStates.Futured);
        }
        
        flag = true;
    }

    function removeFuture(
        Repo storage repo,
        uint256 seqOfOpt,
        uint256 seqOfFt
    ) public returns (bool flag) {
        Future storage ft = repo.records[seqOfOpt].futures[seqOfFt];

        if (ft.par > 0 && repo.options[seqOfOpt].body.closingDate < block.timestamp) {
            ft.state = uint8(FutureStates.Revoked);
            flag = true;
        }
    }

    // ==== Pledge ====

    function requestPledge(
        Repo storage repo,
        uint256 seqOfOpt,
        IBookOfShares.Share memory share,
        uint64 paid,
        uint64 par
    ) public returns (bool flag) {
        Option storage opt = repo.options[seqOfOpt];
        Record storage rcd = repo.records[seqOfOpt];

        require(opt.head.state < uint8(OptStates.Closed), "OR.RP: WRONG state");
        require(opt.head.state > uint8(OptStates.Issued), "OR.RP: WRONG state");

        // uint8 typeOfOpt = sn.typeOfOpt();

        if (opt.head.typeOfOpt % 2 == 1)
            require(
                rcd.obligors.contains(share.head.shareholder),
                "OR.RP: WRONG shareholder"
            );
        else
            require(
                opt.body.rightholder == share.head.shareholder,
                "OR.RP: WRONG sharehoder"
            );

        require(
            opt.body.paid >= rcd.pledges[0].body.pledgedPar + paid,
            "OR.RP: pledge paid OVERFLOW"
        );

        rcd.pledges[0].body.pledgedPar += paid;

        _increaseCounterOfPledges(rcd);

        PledgesRepo.Pledge memory pld = PledgesRepo.Pledge({
            head: PledgesRepo.Head({
                seqOfShare: share.head.seq,
                seqOfPledge: counterOfPledges(rcd),
                createDate: uint48(block.timestamp),
                expireDate: opt.body.closingDate,
                pledgor: share.head.shareholder,
                debtor: share.head.shareholder
            }),
            body: PledgesRepo.Body({
                creditor: opt.body.rightholder,
                pledgedPaid: paid,
                pledgedPar: par,
                guaranteedAmt: paid
            })
        });

        rcd.pledges[pld.head.seqOfPledge] = pld;

        if (opt.body.paid == rcd.pledges[0].body.pledgedPar) 
            opt.head.state = uint8(OptStates.Pledged);

        flag = true;
    }

    // ==== Option ====

    function lockOption(
        Option storage opt,
        bytes32 hashLock
    ) public {
        require(opt.head.state > uint8(OptStates.Issued), 
            "OR.LO: WRONG state");

        opt.hashLock = hashLock;
    }

    function closeOption(
        Option storage opt,
        string memory hashKey
    ) public {
        require(opt.head.state > uint8(OptStates.Issued), 
            "OR.CO: WRONG state");
        require(opt.head.state < uint8(OptStates.Closed), 
            "OR.CO: WRONG state");
        require(
            block.timestamp <= opt.body.closingDate,
            "OR.CO: MISSED closingDate"
        );
        require(
            opt.hashLock == keccak256(bytes(hashKey)),
            "OR.CO: WRONG key"
        );

        opt.head.state = uint8(OptStates.Closed);
    }

    function revokeOption(Option storage opt) public {
        require(opt.head.state < uint8(OptStates.Closed), "OR.RO: WRONG state");
        require(block.timestamp > opt.body.closingDate, "OR.RO: closingDate NOT expired");

        opt.head.state = uint8(OptStates.Revoked);
    }

    // ################
    // ##  查询接口  ##
    // ################

    // ==== Repo ====

    function increaseCounterOfOptions(Repo storage repo) public {
        repo.options[0].head.seqOfOpt++;
    } 

    function counterOfOptions(Repo storage repo)
        public view returns (uint32)
    {
        return repo.options[0].head.seqOfOpt;
    }
    
    function optionsOfRepo(Repo storage repo) 
        external view returns (Option[] memory) 
    {
        uint256 len = counterOfOptions(repo);
        Option[] memory output = new Option[](len);
        
        while (len > 0) {
            output[len-1] = repo.options[len];
            len--;
        }
        return output;
    }

    // ==== Record ====
    
    function _increaseCounterOfFutures(Record storage rcd) private {
        rcd.futures[0].seqOfFuture++;
    }

    function counterOfFutures(Record storage rcd)
        public view returns (uint32)
    {
        return rcd.futures[0].seqOfFuture;
    }

    function futuresOfOption(Record storage rcd)
        public view returns (Future[] memory)
    {
        uint256 len = counterOfFutures(rcd);
        Future[] memory output = new Future[](len);

        while (len > 0) {
            output[len - 1] = rcd.futures[len];
            len--;
        }

        return output;
    }

    function _increaseCounterOfPledges(Record storage rcd) private {
        rcd.pledges[0].head.seqOfPledge++;
    }

    function counterOfPledges(Record storage rcd) 
        public view
        returns (uint32)
    {
        return rcd.pledges[0].head.seqOfPledge;
    }

    function pledgesOfOption(Record storage rcd)
        public view returns (PledgesRepo.Pledge[] memory)
    {
        uint256 len = counterOfPledges(rcd);
        PledgesRepo.Pledge[] memory output = new PledgesRepo.Pledge[](len);

        while (len > 0) {
            output[len - 1] = rcd.pledges[len];
            len--;
        }

        return output;
    }
}

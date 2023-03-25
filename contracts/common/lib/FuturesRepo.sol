// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/SharesRepo.sol";
import "../../common/lib/Checkpoints.sol";
import "./PledgesRepo.sol";

library FuturesRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.History;

    enum FutureStates{
        Pending,
        Issued,
        Crystalized,
        Closed,
        Revoked,
        Terminated
    }

    struct Head {
        uint32 seq;
        uint16 classOfShare;
        uint32 priceOfPaid;
        uint32 priceOfPar;
        uint40 obligor;
        uint48 issueDate;
        uint16 closingDays;
        uint32 preSeq;
    }

    struct Body {
        uint40 rightholder;
        uint64 paid;
        uint64 par;
        uint48 closingDate;
        uint8 state;
    }

    struct Future {
        Head head;
        Body body;
    }

    struct Pack {
        uint32 seqOfFt;
        uint32 seqOfShare;
        uint64 paid;
        uint64 par;
    }

    struct Repo {
        mapping(uint256 => Future) futures;
        // seqOfFt => seqOfShare => Pack
        mapping(uint256 => mapping(uint256 => Pack)) packs;
        EnumerableSet.UintSet snList;
    }

    // ###############
    // ##   修饰器   ##
    // ###############

    modifier ftExist(Repo storage repo, uint32 seq) {
        require(repo.futures[seq].head.issueDate > 0, "FR.mf.FE: ft not exist");
        _;
    }

    // ###############
    // ##   写接口   ##
    // ###############

    // ==== snParser & codifyHead ====

    function snParser(uint256 sn) public pure returns (Head memory head) {
        head = Head({
            seq: uint32(sn >> 224),
            classOfShare: uint16(sn >> 208),
            priceOfPaid: uint32(sn >> 176),
            priceOfPar: uint32(sn >> 144),
            obligor: uint40(sn >> 104),
            issueDate: uint48(sn >> 56),
            closingDays: uint16(sn >> 40),
            preSeq: uint32(sn >> 8)
        });
    }

    function codifyHead(Head memory head) public pure returns (uint256 sn) {
        sn = (uint256(head.seq) << 224) +
            (uint256(head.classOfShare) << 208) +
            (uint256(head.priceOfPaid) << 176) +
            (uint256(head.priceOfPar) << 144) +
            (uint256(head.obligor) << 104) + 
            (uint256(head.issueDate) << 56) +
            (uint256(head.closingDays) << 40) +
            (uint256(head.preSeq) << 8);
    }

    // ==== create/issue/reg Future ====

    function createFuture(
        Repo storage repo,
        uint256 sn,
        uint40 rightholder,
        uint64 paid,
        uint64 par
    ) public returns (uint32 seqOfFt) {
        Future memory ft;

        ft.head = snParser(sn);
        ft.body = Body({
            rightholder: rightholder,
            paid: paid,
            par: par,
            closingDate: 0,
            state: 0
        });

        seqOfFt = issueFuture(repo, ft);
    }

    function issueFuture(
        Repo storage repo,
        Future memory ft 
    ) public returns(uint32 seqOfFt) {

        require(ft.head.closingDays > 0, "FR.IF: zero closingDays");

        require(ft.head.classOfShare > 0, "FR.IF: zero class");
        require(ft.head.priceOfPaid > 0, "FR.IF: ZERO priceOfPaid");

        require(ft.body.rightholder > 0, "FR.IF: ZERO rightholder");
        require(ft.head.obligor > 0, "FR.IF: ZERO obligor");

        require(ft.body.paid > 0, "FR.IF: ZERO paid");
        require(ft.body.par >= ft.body.paid, "FR.IF: INSUFFICIENT par");

        ft.head.issueDate = uint48(block.timestamp);
        
        ft.body.closingDate = ft.head.issueDate + uint48(ft.head.closingDays) * 86400;
        ft.body.state = uint8(FutureStates.Issued);

        seqOfFt = regFuture(repo, ft);
    }

    function regFuture(Repo storage repo, Future memory ft) public returns(uint32 seqOfFt)
    {
        ft.head.seq = _increaseCounterOfFutures(repo);

        if (repo.snList.add(codifyHead(ft.head))) {            
            repo.futures[ft.head.seq] = ft;
            seqOfFt = ft.head.seq;
        }
    }

    

    // ==== UpdateBody ====
    function crystalizeFuture(Repo storage repo, Pack memory pack)
        public ftExist(repo, pack.seqOfFt) returns (bool flag)
    {
        Future storage ft = repo.futures[pack.seqOfFt];
        Pack storage sum = repo.packs[pack.seqOfFt][0];
        Pack storage p = repo.packs[pack.seqOfFt][pack.seqOfShare];

        if ((ft.body.paid > sum.paid || ft.body.par > sum.par) &&
            p.seqOfFt == 0)
        {
            repo.packs[pack.seqOfFt][pack.seqOfShare] = pack;

            sum.paid += pack.paid;
            sum.par += pack.par;

            flag = true;
        }
    }


    // ==== Option ====

    // function execOption(
    //     Repo storage repo,
    //     uint256 seqOfOpt
    // ) public {
    //     Option storage opt = repo.options[seqOfOpt]; 
    //     Record storage rcd = repo.records[seqOfOpt];

    //     require(
    //         opt.head.state == uint8(OptStates.Issued),
    //         "OR.EO: wrong state of Opt"
    //     );
    //     require(
    //         block.timestamp >= opt.head.triggerDate,
    //         "OR.EO: NOT reached TriggerDate"
    //     );

    //     if (opt.head.execDays > 0)
    //         require(
    //             block.timestamp <= opt.head.triggerDate + opt.head.execDays * 86400,
    //             "OR.EO: NOT in exercise period"
    //         );

    //     Checkpoints.Checkpoint memory cp = rcd.oracles.latest();

    //     if (opt.head.typeOfOpt > uint8(OptTypes.PutIrr))
    //         require(
    //             checkConditions(opt.head, uint32(cp.paid), uint32(cp.par)),
    //             "OR.EO: conditions NOT satisfied"
    //         );

    //     opt.body.closingDate = uint48(block.timestamp) + opt.head.closingDays * 86400;
    //     opt.head.state = uint8(OptStates.Executed);
    // }

    // // --- Head ----

    // function checkConditions(
    //     Head memory head,
    //     uint32 data1,
    //     uint32 data2
    // ) public pure returns (bool flag) {
    //     bool flag1;
    //     bool flag2;

    //     if (head.compOperator1 == uint8(ComOps.Equal)) flag1 = data1 == head.para1;
    //     else if (head.compOperator1 == uint8(ComOps.NotEqual)) flag1 = data1 != head.para1;
    //     else if (head.compOperator1 == uint8(ComOps.Bigger)) flag1 = data1 > head.para1;
    //     else if (head.compOperator1 == uint8(ComOps.Smaller)) flag1 = data1 < head.para1;
    //     else if (head.compOperator1 == uint8(ComOps.BiggerOrEqual)) flag1 = data1 >= head.para1;
    //     else if (head.compOperator1 == uint8(ComOps.SmallerOrEqual)) flag1 = data1 <= head.para1;

    //     if (head.compOperator2 == uint8(ComOps.Equal)) flag2 = data2 == head.para2;
    //     else if (head.compOperator2 == uint8(ComOps.NotEqual)) flag2 = data2 != head.para2;
    //     else if (head.compOperator2 == uint8(ComOps.Bigger)) flag2 = data2 > head.para2;
    //     else if (head.compOperator2 == uint8(ComOps.Smaller)) flag2 = data2 < head.para2;
    //     else if (head.compOperator2 == uint8(ComOps.BiggerOrEqual)) flag2 = data2 >= head.para2;
    //     else if (head.compOperator2 == uint8(ComOps.SmallerOrEqual)) flag2 = data2 <= head.para2;

    //     if (head.logicOperator == uint8(LogOps.And)) flag = flag1 && flag2;
    //     else if (head.logicOperator == uint8(LogOps.Or)) flag = flag1 || flag2;
    //     else if (head.logicOperator == uint8(LogOps.AndOr)) flag = flag1;
    //     else if (head.logicOperator == uint8(LogOps.OrAnd)) flag = flag2;
    //     else if (head.logicOperator == uint8(LogOps.Equal)) flag = flag1 == flag2;
    //     else if (head.logicOperator == uint8(LogOps.NotEqual)) flag = flag1 != flag2;
    // }

    // // ==== Futures ====

    // function addFuture(
    //     Repo storage repo,
    //     uint256 seqOfOpt,
    //     SharesRepo.Share memory share,
    //     Future memory future
    // ) public returns (bool flag) {
    //     Option storage opt = repo.options[seqOfOpt];
    //     Record storage rcd = repo.records[seqOfOpt];

    //     require(
    //         block.timestamp <= opt.body.closingDate,
    //         "OR.AF: MISSED closingDate"
    //     );
    //     require(opt.head.state == uint8(OptStates.Executed), 
    //         "OR.AF: option NOT executed");

    //     if (opt.head.typeOfOpt % 2 == 1) {
    //         require(
    //             opt.body.rightholder == share.head.shareholder,
    //             "OR.AF: WRONG shareholder"
    //         );
    //         require (
    //             rcd.obligors.contains(future.buyer),
    //             "OR.AF: wrong future buyer"
    //         );
    //     } else {
    //         require(
    //             rcd.obligors.contains(share.head.shareholder),
    //             "OR.AF: WRONG sharehoder"
    //         );
    //         require(
    //             opt.body.rightholder == future.buyer,
    //             "OR.AF: Wrong future buyer"
    //         );
    //     }

    //     require(opt.body.paid >= rcd.futures[0].paid + future.paid, 
    //         "NOT sufficient paid");
    //     require(opt.body.par >= rcd.futures[0].par + future.par, 
    //         "NOT sufficient par");
        
    //     rcd.futures[0].paid += future.paid;
    //     rcd.futures[0].par += future.par;
        
    //     _increaseCounterOfFutures(rcd);
    //     future.seqOfFuture = counterOfFutures(rcd);

    //     rcd.futures[future.seqOfFuture] = future;

    //     if (opt.body.par == rcd.futures[0].par && 
    //         opt.body.paid == rcd.futures[0].paid) 
    //     {
    //         opt.head.state = uint8(OptStates.Futured);
    //     }
        
    //     flag = true;
    // }

    // function removeFuture(
    //     Repo storage repo,
    //     uint256 seqOfOpt,
    //     uint256 seqOfFt
    // ) public returns (bool flag) {
    //     Future storage ft = repo.records[seqOfOpt].futures[seqOfFt];

    //     if (ft.par > 0 && repo.options[seqOfOpt].body.closingDate < block.timestamp) {
    //         ft.state = uint8(FutureStates.Revoked);
    //         flag = true;
    //     }
    // }

    // // ==== Pledge ====

    // function requestPledge(
    //     Repo storage repo,
    //     uint256 seqOfOpt,
    //     SharesRepo.Share memory share,
    //     uint64 paid,
    //     uint64 par
    // ) public returns (bool flag) {
    //     Option storage opt = repo.options[seqOfOpt];
    //     Record storage rcd = repo.records[seqOfOpt];

    //     require(opt.head.state < uint8(OptStates.Closed), "OR.RP: WRONG state");
    //     require(opt.head.state > uint8(OptStates.Issued), "OR.RP: WRONG state");

    //     // uint8 typeOfOpt = sn.typeOfOpt();

    //     if (opt.head.typeOfOpt % 2 == 1)
    //         require(
    //             rcd.obligors.contains(share.head.shareholder),
    //             "OR.RP: WRONG shareholder"
    //         );
    //     else
    //         require(
    //             opt.body.rightholder == share.head.shareholder,
    //             "OR.RP: WRONG sharehoder"
    //         );

    //     require(
    //         opt.body.paid >= rcd.pledges[0].body.pledgedPar + paid,
    //         "OR.RP: pledge paid OVERFLOW"
    //     );

    //     rcd.pledges[0].body.pledgedPar += paid;

    //     _increaseCounterOfPledges(rcd);

    //     PledgesRepo.Pledge memory pld = PledgesRepo.Pledge({
    //         head: PledgesRepo.Head({
    //             seqOfShare: share.head.seqOfShare,
    //             seqOfPledge: counterOfPledges(rcd),
    //             createDate: uint48(block.timestamp),
    //             expireDate: opt.body.closingDate,
    //             pledgor: share.head.shareholder,
    //             debtor: share.head.shareholder
    //         }),
    //         body: PledgesRepo.Body({
    //             creditor: opt.body.rightholder,
    //             pledgedPaid: paid,
    //             pledgedPar: par,
    //             guaranteedAmt: paid
    //         })
    //     });

    //     rcd.pledges[pld.head.seqOfPledge] = pld;

    //     if (opt.body.paid == rcd.pledges[0].body.pledgedPar) 
    //         opt.head.state = uint8(OptStates.Pledged);

    //     flag = true;
    // }

    // // ==== Option ====

    // function lockOption(
    //     Option storage opt,
    //     bytes32 hashLock
    // ) public {
    //     require(opt.head.state > uint8(OptStates.Issued), 
    //         "OR.LO: WRONG state");

    //     opt.hashLock = hashLock;
    // }

    // function closeOption(
    //     Option storage opt,
    //     string memory hashKey
    // ) public {
    //     require(opt.head.state > uint8(OptStates.Issued), 
    //         "OR.CO: WRONG state");
    //     require(opt.head.state < uint8(OptStates.Closed), 
    //         "OR.CO: WRONG state");
    //     require(
    //         block.timestamp <= opt.body.closingDate,
    //         "OR.CO: MISSED closingDate"
    //     );
    //     require(
    //         opt.hashLock == keccak256(bytes(hashKey)),
    //         "OR.CO: WRONG key"
    //     );

    //     opt.head.state = uint8(OptStates.Closed);
    // }

    // function revokeOption(Option storage opt) public {
    //     require(opt.head.state < uint8(OptStates.Closed), "OR.RO: WRONG state");
    //     require(block.timestamp > opt.body.closingDate, "OR.RO: closingDate NOT expired");

    //     opt.head.state = uint8(OptStates.Revoked);
    // }

    function _increaseCounterOfFutures(Repo storage repo) private returns(uint32 seqOfFt) {
        repo.futures[0].head.seq++;
        seqOfFt = repo.futures[0].head.seq;
    } 


    // // ################
    // // ##  查询接口  ##
    // // ################

    // // ==== Repo ====


    // function counterOfOptions(Repo storage repo)
    //     public view returns (uint32)
    // {
    //     return repo.options[0].head.seqOfOpt;
    // }
    
    // function optionsOfRepo(Repo storage repo) 
    //     external view returns (Option[] memory) 
    // {
    //     uint256 len = counterOfOptions(repo);
    //     Option[] memory output = new Option[](len);
        
    //     while (len > 0) {
    //         output[len-1] = repo.options[len];
    //         len--;
    //     }
    //     return output;
    // }

    // // ==== Record ====
    
    // function _increaseCounterOfFutures(Record storage rcd) private {
    //     rcd.futures[0].seqOfFuture++;
    // }

    // function counterOfFutures(Record storage rcd)
    //     public view returns (uint32)
    // {
    //     return rcd.futures[0].seqOfFuture;
    // }

    // function futuresOfOption(Record storage rcd)
    //     public view returns (Future[] memory)
    // {
    //     uint256 len = counterOfFutures(rcd);
    //     Future[] memory output = new Future[](len);

    //     while (len > 0) {
    //         output[len - 1] = rcd.futures[len];
    //         len--;
    //     }

    //     return output;
    // }

    // function _increaseCounterOfPledges(Record storage rcd) private {
    //     rcd.pledges[0].head.seqOfPledge++;
    // }

    // function counterOfPledges(Record storage rcd) 
    //     public view
    //     returns (uint32)
    // {
    //     return rcd.pledges[0].head.seqOfPledge;
    // }

    // function pledgesOfOption(Record storage rcd)
    //     public view returns (PledgesRepo.Pledge[] memory)
    // {
    //     uint256 len = counterOfPledges(rcd);
    //     PledgesRepo.Pledge[] memory output = new PledgesRepo.Pledge[](len);

    //     while (len > 0) {
    //         output[len - 1] = rcd.pledges[len];
    //         len--;
    //     }

    //     return output;
    // }
}

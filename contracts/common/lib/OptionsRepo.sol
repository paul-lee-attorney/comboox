// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./Checkpoints.sol";
import "./CondsRepo.sol";
import "./SharesRepo.sol";
import "./SwapsRepo.sol";

import "../../books/bos/IBookOfShares.sol";

library OptionsRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.History;
    using CondsRepo for CondsRepo.Cond;
    using CondsRepo for bytes32;

    enum TypeOfOpt {
        CallPrice,          
        PutPrice,           
        CallRoe,            
        PutRoe,             
        CallPriceWithCnds,  
        PutPriceWithCnds,   
        CallRoeWithCnds,    
        PutRoeWithCnds     
    }

    enum StateOfOpt {
        Pending,    
        Issued,         
        Executed,
        Closed
    }

    struct Head {
        uint32 seqOfOpt;
        uint8 typeOfOpt;
        uint16 classOfShare;
        uint32 rate;            
        uint48 issueDate;
        uint48 triggerDate;     
        uint16 execDays;         
        uint16 closingDays;
        uint40 obligor;      
    }

    struct Body {
        uint48 closingDeadline;
        uint40 rightholder;
        uint64 paid;
        uint64 par;
        uint8 state;
        uint16 para;
        uint16 arg;
    }

    struct Option {
        Head head;
        CondsRepo.Cond cond;
        Body body;
    }

    struct Brief {
        uint16 seqOfBrf;
        uint32 seqOfSwap;
        uint32 rateOfSwap;
        uint64 paidOfConsider;
        uint64 paidOfTarget;
        uint40 obligor;
        uint8 state;
    }

    struct Record {
        EnumerableSet.UintSet obligors;
        // seqOfSwap => Brief
        mapping(uint256 => Brief) briefs;
        Checkpoints.History oracles;
    }

    struct Repo {
        mapping(uint256 => Option) options;
        mapping(uint256 => Record) records;
        EnumerableSet.Bytes32Set snList;
    }

    // ###############
    // ##   写接口   ##
    // ###############

    // ==== cofify / parser ====

    function snParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            seqOfOpt: uint32(_sn >> 224),
            typeOfOpt: uint8(_sn >> 216),
            classOfShare: uint16(_sn >> 200),
            rate: uint32(_sn >> 168),
            issueDate: uint48(_sn >> 120),
            triggerDate: uint48(_sn >> 72),
            execDays: uint16(_sn >> 56),
            closingDays: uint16(_sn >> 40),
            obligor: uint40(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.seqOfOpt,
                            head.typeOfOpt,
                            head.classOfShare,
                            head.rate,
                            head.issueDate,
                            head.triggerDate,
                            head.execDays,
                            head.closingDays,
                            head.obligor);
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function codifyBrief(Brief memory brf) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            brf.seqOfBrf,
                            brf.seqOfSwap,
                            brf.rateOfSwap,
                            brf.paidOfConsider,
                            brf.paidOfTarget,
                            brf.obligor,
                            brf.state);
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    // ==== Option ====

    function createOption(
        Repo storage repo,
        bytes32 snOfOpt,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) public returns (Head memory head) 
    {
        Option memory opt;

        opt.head = snParser(snOfOpt);
        opt.cond = snOfCond.snParser();

        opt.body.closingDeadline = opt.head.triggerDate + (uint48(opt.head.execDays) + uint48(opt.head.closingDays)) * 86400;
        opt.body.rightholder = uint40(rightholder);
        opt.body.paid = uint64(paid);
        opt.body.par = uint64(par);

        head = issueOption(repo, opt);
    }

    function issueOption(
        Repo storage repo,
        Option memory opt
    ) public returns(Head memory head) {
        opt.head.issueDate = uint48(block.timestamp);
        opt.body.state = uint8(StateOfOpt.Issued);
        head = regOption(repo, opt);
    }

    function regOption(
        Repo storage repo,
        Option memory opt
    ) public returns(Head memory head) {

        require(opt.head.rate > 0, "OR.IO: ZERO rate");

        require(opt.head.triggerDate > block.timestamp, "OR.IO: triggerDate not future");
        require(opt.head.execDays > 0, "OR.IO: ZERO execDays");
        require(opt.head.closingDays > 0, "OR.IO: ZERO closingDays");
        require(opt.head.obligor > 0, "OR.IO: ZERO obligor");

        require(opt.body.rightholder > 0, "OR.IO: ZERO rightholder");
        require(opt.body.paid > 0, "OR.IO: ZERO paid");
        require(opt.body.par >= opt.body.paid, "OR.IO: INSUFFICIENT par");

        opt.head.seqOfOpt = _increaseCounterOfOptions(repo);

        if (repo.snList.add(codifyHead(opt.head))) {
            repo.options[opt.head.seqOfOpt] = opt;
            repo.records[opt.head.seqOfOpt].obligors.add(opt.head.obligor);
            head = opt.head;
        }
    }

    // ==== Record ====

    function addObligorIntoOption(Record storage record, uint256 obligor)
        public returns(bool flag)
    {
        require (obligor > 0, "OR.AOIO: zero obligor");        
        flag = record.obligors.add(obligor);
    }

    function removeObligorFromOption(Record storage record, uint256 obligor)
        public returns(bool flag)
    {
        require (obligor > 0, "OR.ROFO: zero obligor");        
        flag = record.obligors.remove(obligor);
    }

    function addObligorsIntoOption(Record storage record, uint256[] memory obligors)
        public
    {
        uint256 len = obligors.length;
        while (len > 0) {
            record.obligors.add(obligors[len-1]);
            len--;
        }
    }

    // ==== ExecOption ====

    function execOption(
        Repo storage repo,
        uint256 seqOfOpt
    ) public {
        Option storage opt = repo.options[seqOfOpt]; 
        Record storage rcd = repo.records[seqOfOpt];

        require(
            opt.body.state == uint8(StateOfOpt.Issued),
            "OR.EO: wrong state of Opt"
        );
        require(
            block.timestamp >= opt.head.triggerDate,
            "OR.EO: NOT reached TriggerDate"
        );

        require(
            block.timestamp < opt.head.triggerDate + uint48(opt.head.execDays) * 86400,
            "OR.EO: NOT in exercise period"
        );

        if (opt.head.typeOfOpt > uint8(TypeOfOpt.PutRoe)) {
            Checkpoints.Checkpoint memory cp = rcd.oracles.latest();

            if (opt.cond.logicOpr == uint8(CondsRepo.LogOps.ZeroPoint)) { 
                require(opt.cond.checkSoleCond(cp.paid), 
                    "OR.EO: conds not satisfied");
            } else if (opt.cond.logicOpr <= uint8(CondsRepo.LogOps.NotEqual)) {
                require(opt.cond.checkCondsOfTwo(cp.paid, cp.par), 
                    "OR.EO: conds not satisfied");                
            } else if (opt.cond.logicOpr <= uint8(CondsRepo.LogOps.NeNe)) {
                require(opt.cond.checkCondsOfThree(cp.paid, cp.par, cp.cleanPaid), 
                    "OR.EO: conds not satisfied");   
            } else revert("OR.EO: logical operator overflow");
        }

        opt.body.closingDeadline = uint48(block.timestamp) + uint48(opt.head.closingDays) * 86400;
        opt.body.state = uint8(StateOfOpt.Executed);
    }

    // ==== Brief ====

    function createSwapOrder(
        Repo storage repo,
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget,
        IGeneralKeeper _gk    
    ) public view returns(SwapsRepo.Swap memory swap) {

        Option storage opt = repo.options[seqOfOpt];
        Record storage rcd = repo.records[seqOfOpt];

        require(opt.body.state == uint8(StateOfOpt.Executed), "OR.IS: wrong state");
        require(block.timestamp < opt.body.closingDeadline, "OR.IS: option expired");

        SharesRepo.Share memory consider = _gk.getBOS().getShare(seqOfConsider);
        SharesRepo.Share memory target = _gk.getBOS().getShare(seqOfTarget);
        
        require(rcd.obligors.contains(target.head.shareholder), "OR.IS: obligor not target shareholder");
        require(opt.body.rightholder == consider.head.shareholder, "OR.IS: rightholder not consider shareholder");

        swap.head = SwapsRepo.Head({
            seqOfSwap: 0,
            classOfTarget: target.head.class,
            classOfConsider: consider.head.class,
            createDate: uint48(block.timestamp),
            triggerDate: uint48(block.timestamp) + 120,
            closingDays: uint16((opt.body.closingDeadline + 43200 - block.timestamp) / 86400),
            obligor: opt.head.obligor,
            rateOfSwap: 0,
            para: 0
        });

        if (opt.head.typeOfOpt % 4 < 2) 
            swap.head.rateOfSwap = consider.head.priceOfPaid * 10000 / opt.head.rate;
        else {
            swap.head.rateOfSwap = consider.head.priceOfPaid * (365 + opt.head.rate) * 
                uint32(block.timestamp - consider.head.issueDate) * 100/ (864 * 365 * target.head.priceOfPaid);
        }

        if (opt.head.typeOfOpt % 2 == 1) {
            require(opt.head.classOfShare == consider.head.class, "OR.IS: wrong consider class");
            require (opt.body.paid >= rcd.briefs[0].paidOfConsider + paidOfConsider, 
                "OR.PS: paidOfConsider overflow");
        } else {
            require(opt.head.classOfShare == target.head.class, "OR.IS: wrong target class");
            require (opt.body.paid >= rcd.briefs[0].paidOfTarget + (paidOfConsider * swap.head.rateOfSwap / 10000), 
                "OR.PS: paidOfTarget overflow");            
        }

        swap.body.rightholder = opt.body.rightholder;
        swap.body.paidOfConsider = uint64(paidOfConsider);
    }

    function regSwapOrder(
        Repo storage repo,
        uint256 seqOfOpt,
        SwapsRepo.Swap memory swap
    ) public returns (Brief memory brf)
    {
        Record storage rcd = repo.records[seqOfOpt];

        brf = Brief({
            seqOfBrf: _increaseCounterOfBriefs(repo, seqOfOpt),
            seqOfSwap: swap.head.seqOfSwap,
            rateOfSwap: swap.head.rateOfSwap,
            paidOfConsider: swap.body.paidOfConsider,
            paidOfTarget: swap.body.paidOfTarget,
            obligor: swap.head.obligor,
            state: swap.body.state
        }); 

        rcd.briefs[brf.seqOfBrf] = brf;

        rcd.briefs[0].paidOfConsider += swap.body.paidOfConsider;
        rcd.briefs[0].paidOfTarget += swap.body.paidOfTarget;        
    }

    // ==== Counter ====

    function _increaseCounterOfOptions(Repo storage repo) private returns(uint32 seqOfOpt) {
        repo.options[0].head.seqOfOpt++;
        seqOfOpt = repo.options[0].head.seqOfOpt;
    } 

    function _increaseCounterOfBriefs(Repo storage repo, uint256 seqOfOpt) private returns(uint16 seqOfBrf) {
        repo.records[seqOfOpt].briefs[0].seqOfBrf++;
        seqOfBrf = repo.records[seqOfOpt].briefs[0].seqOfBrf;
    } 

    // ################
    // ##  查询接口   ##
    // ################

    // ==== Repo ====

    function counterOfOptions(Repo storage repo)
        public view returns (uint32)
    {
        return repo.options[0].head.seqOfOpt;
    }
    
    function getAllOptions(Repo storage repo) 
        public view returns (Option[] memory) 
    {
        uint256 len = counterOfOptions(repo);
        Option[] memory output = new Option[](len);
        
        while (len > 0) {
            output[len-1] = repo.options[len];
            len--;
        }
        return output;
    }

    // ==== Brief ====

    function counterOfBriefs(Repo storage repo, uint256 seqOfOpt)
        public view returns (uint32)
    {
        return repo.records[seqOfOpt].briefs[0].seqOfBrf;
    }

    function getAllBriefsOfOption(Repo storage repo, uint256 seqOfOpt)
        public view returns (Brief[] memory )
    {
        uint256 len = counterOfBriefs(repo, seqOfOpt);
        Brief[] memory briefs = new Brief[](len-1);

        while (len > 0) {
            briefs[len-1] = repo.records[seqOfOpt].briefs[len];
            len--;
        }
        return briefs;
    }

    function allBriefsClosed(Repo storage repo, uint256 seqOfOpt)
        public view returns (bool)
    {
        Record storage rcd = repo.records[seqOfOpt];

        uint256 len = counterOfBriefs(repo, seqOfOpt);
        while (len > 1) {
            if (rcd.briefs[len].state < uint8(SwapsRepo.StateOfSwap.Released))
                return false;
            len--;
        }

        return true;        
    }

}

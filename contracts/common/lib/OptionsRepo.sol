// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./SharesRepo.sol";
import "./Checkpoints.sol";
import "./CondsRepo.sol";
import "./PledgesRepo.sol";

library OptionsRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.History;
    using CondsRepo for CondsRepo.Cond;
    using CondsRepo for uint256;
    using PledgesRepo for PledgesRepo.Pledge;

    enum TypeOfOpt {
        CallPrice,          
        PutPrice,           
        CallRoe,            
        PutRoe,             
        CallIrr,            
        PutIrr,             
        CallPriceWithCnds,  
        PutPriceWithCnds,   
        CallRoeWithCnds,    
        PutRoeWithCnds,     
        CallIrrWithCnds,    
        PutIrrWithCnds      
    }

    enum StateOfOpt {
        Pending,    
        Issued,         
        Executed,   
        Ordered,    
        Pledged,    
        Locked,
        Closed,     
        Revoked,    
        Expired     
    }

    enum StateOfOdr {
        Pending,    
        Issued,         
        Pledged,    
        Closed,     
        Revoked
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
        uint8 state;
    }

    struct Body {
        uint48 closingDate;
        uint40 rightholder;
        uint40 obligor;      
        uint64 paid;
        uint64 par;
    }

    struct Option {
        Head head;
        CondsRepo.Cond cond;
        Body body;
        // bytes32 hashLock;
    }

    struct Order {
        uint32 seqOfOpt;
        uint16 seqOfOdr;
        uint32 seqOfShare;
        uint40 buyer;
        uint64 paid;
        uint64 par;
        uint8 state;
    }

    struct Record {
        EnumerableSet.UintSet obligors;
        // seqOfOdr => Order
        mapping(uint256 => Order) orders;
        // seqOfOdr => seqOfPld => Pld
        mapping(uint256 => mapping(uint256 => PledgesRepo.Pledge)) pledges;
        Checkpoints.History oracles;
    }

    struct Repo {
        mapping(uint256 => Option) options;
        mapping(uint256 => Record) records;
        EnumerableSet.UintSet snList;
    }

    // ###############
    // ##   写接口   ##
    // ###############

    // ==== cofify / parser ====

    function snParser(uint256 sn) public pure returns (Head memory head) {
        head = Head({
            seqOfOpt: uint32(sn >> 224),
            typeOfOpt: uint8(sn >> 216),
            classOfShare: uint16(sn >> 200),
            rate: uint32(sn >> 168),
            issueDate: uint48(sn >> 120),
            triggerDate: uint48(sn >> 72),
            execDays: uint16(sn >> 56),
            closingDays: uint16(sn >> 40),
            state: uint8(sn >> 32)
        });
    }

    function codifyHead(Head memory head) public pure returns (uint256 sn) {
        sn = (uint256(head.seqOfOpt) << 224) +
            (uint256(head.typeOfOpt) << 216) +
            (uint256(head.classOfShare) << 200) +
            (uint256(head.rate) << 168) +
            (uint256(head.issueDate) << 120) +
            (uint256(head.triggerDate) << 72) +
            (uint256(head.execDays) << 56) +
            (uint256(head.closingDays) << 40);
    }

    function orderSNParser(uint256 sn) public pure returns (Order memory order) {
        order = Order({
            seqOfOpt: uint32(sn >> 224),
            seqOfOdr: uint16(sn >> 208),
            seqOfShare: uint32(sn >> 176),
            buyer: uint40(sn >> 136),
            paid: uint64(sn >> 72),
            par: uint64(sn >> 8),
            state: uint8(sn)
        });
    }

    function codifyOrder(Order memory order) public pure returns(uint256 sn) {
        sn = (uint256(order.seqOfOpt) << 224) +
            (uint256(order.seqOfOdr) << 208) +
            (uint256(order.seqOfShare) << 176) +
            (uint256(order.buyer) << 136) +
            (uint256(order.paid) << 72) +
            (uint256(order.par) << 8); 
    }

    // ==== Option ====

    function createOption(
        Repo storage repo,
        uint256 sn,
        uint256 snOfCond,
        uint40 rightholder,
        uint40 obligor,
        uint64 paid,
        uint64 par
    ) public returns (uint32 seqOfOpt) 
    {
        Option memory opt;

        opt.head = snParser(sn);
        opt.cond = snOfCond.snParser();
        opt.body = Body({
            closingDate: opt.head.triggerDate + (uint48(opt.head.execDays) + uint48(opt.head.closingDays)) * 86400,
            rightholder: rightholder,
            obligor: obligor,
            paid: paid,
            par: par
        });

        seqOfOpt = issueOption(repo, opt);
    }

    function issueOption(
        Repo storage repo,
        Option memory opt
    ) public returns(uint32 seqOfOpt) {
        opt.head.issueDate = uint48(block.timestamp);
        opt.head.state = uint8(StateOfOpt.Issued);
        seqOfOpt = regOption(repo, opt);
    }

    function regOption(
        Repo storage repo,
        Option memory opt
    ) public returns(uint32 seqOfOpt) {

        require(opt.head.rate > 0, "OR.IO: ZERO rate");

        require(opt.head.triggerDate > block.timestamp, "OR.IO: triggerDate not order");
        // require(opt.head.execDays > 0,"OR.IO: ZERO execDays");
        require(opt.head.closingDays > 0, "OR.IO: ZERO closingDays");
        require(opt.body.obligor > 0, "OR.IO: ZERO obligor");

        require(opt.body.rightholder > 0, "OR.IO: ZERO rightholder");
        require(opt.body.paid > 0, "OR.IO: ZERO paid");
        require(opt.body.par >= opt.body.paid, "OR.IO: INSUFFICIENT par");

        seqOfOpt = _increaseCounterOfOptions(repo);
        opt.head.seqOfOpt = seqOfOpt;        

        if (repo.snList.add(codifyHead(opt.head))) {
            repo.options[seqOfOpt] = opt;
            repo.records[seqOfOpt].obligors.add(opt.body.obligor);
        }
    }

    // ==== Record ====

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
            opt.head.state == uint8(StateOfOpt.Issued),
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

        if (opt.head.typeOfOpt > uint8(TypeOfOpt.PutIrr)) {
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

        opt.body.closingDate = uint48(block.timestamp) + opt.head.closingDays * 86400;
        opt.head.state = uint8(StateOfOpt.Executed);
    }

    // ==== Orders ====

    function addOrder(
        Repo storage repo,
        uint256 snOfOdr
    ) public returns (bool flag) {
        Order memory order = orderSNParser(snOfOdr);

        Option storage opt = repo.options[order.seqOfOpt];
        Record storage rcd = repo.records[order.seqOfOpt];

        require(
            block.timestamp < opt.body.closingDate,
            "OR.AF: MISSED closingDate"
        );
        require(opt.head.state == uint8(StateOfOpt.Executed), 
            "OR.AF: option NOT executed");

        // if (opt.head.typeOfOpt % 2 == 1) {
        //     require(
        //         opt.body.rightholder == order.seller,
        //         "OR.AF: WRONG shareholder"
        //     );
        //     require (
        //         rcd.obligors.contains(order.buyer),
        //         "OR.AF: wrong order buyer"
        //     );
        // } else {
        //     require(
        //         rcd.obligors.contains(order.seller),
        //         "OR.AF: WRONG sharehoder"
        //     );
        //     require(
        //         opt.body.rightholder == order.buyer,
        //         "OR.AF: Wrong order buyer"
        //     );
        // }

        require(opt.body.paid >= rcd.orders[0].paid + order.paid, 
            "paidOfOrder overflow");
        require(opt.body.par >= rcd.orders[0].par + order.par, 
            "parOfOrder overflow");
        
        rcd.orders[0].paid += order.paid;
        rcd.orders[0].par += order.par;
        
        order.seqOfOdr = _increaseCounterOfOrders(rcd);

        rcd.orders[order.seqOfOdr] = order;

        if (opt.body.par == rcd.orders[0].par && 
            opt.body.paid == rcd.orders[0].paid) 
        {
            opt.head.state = uint8(StateOfOpt.Ordered);
        }
        
        flag = true;
    }

    function releaseOrder(
        Repo storage repo,
        uint256 seqOfOpt,
        uint256 seqOfOdr
    ) public returns (bool flag)
    {
        Option memory opt = repo.options[seqOfOpt];
        Order storage order = repo.records[seqOfOpt].orders[seqOfOdr];

        if (block.timestamp > opt.body.closingDate &&
            opt.head.state < uint8(StateOfOpt.Closed) &&
            order.state < uint8(StateOfOdr.Closed)) {

            order.state = uint8(StateOfOdr.Revoked);

            flag = true;
        }
    }

    // ==== Pledge ====

    function requestPledge(
        Repo storage repo,
        uint256 seqOfOpt,
        uint256 seqOfOdr,
        PledgesRepo.Pledge memory pledge
    ) public returns (bool flag) {
        Option storage opt = repo.options[seqOfOpt];
        Record storage rcd = repo.records[seqOfOpt];
        Order storage odr = repo.records[seqOfOpt].orders[seqOfOdr];

        require(opt.head.state == uint8(StateOfOpt.Executed), "OR.RP: WRONG stateOfOpt");
        // require(opt.head.state > uint8(StateOfOpt.Issued), "OR.RP: WRONG stateOfOpt");

        require(odr.state == uint8(StateOfOdr.Issued), "OR.RP: wrong stateOfOdr");

        if (opt.head.typeOfOpt % 2 == 1)
            require(
                rcd.obligors.contains(pledge.head.pledgor),
                "OR.RP: WRONG shareholder"
            );
        else
            require(
                opt.body.rightholder == pledge.head.pledgor,
                "OR.RP: WRONG sharehoder"
            );

        require(
            odr.paid * opt.head.rate / 100 >= rcd.pledges[seqOfOdr][0].body.paid + pledge.body.paid,
            "OR.RP: pledge paid OVERFLOW"
        );

        require(
            odr.par * opt.head.rate / 100 >= rcd.pledges[seqOfOdr][0].body.par + pledge.body.par,
            "OR.RP: pledge par OVERFLOW"
        );

        rcd.pledges[seqOfOdr][0].body.paid += pledge.body.paid;
        rcd.pledges[seqOfOdr][0].body.par += pledge.body.par;

        pledge.head.seqOfPldOnOdr = _increaseCounterOfPldsOnOrder(rcd, seqOfOdr);

        rcd.pledges[seqOfOdr][pledge.head.seqOfPldOnOdr] = pledge;

        if (rcd.orders[seqOfOdr].paid * opt.head.rate / 100 == rcd.pledges[seqOfOdr][0].body.paid &&
            rcd.orders[seqOfOdr].par * opt.head.rate / 100 == rcd.pledges[seqOfOdr][0].body.par)
        {
            rcd.orders[seqOfOdr].state = uint8(StateOfOdr.Pledged);
        }

        flag = true;
    }

    // ==== Option ====

    // function lockOption(
    //     Option storage opt,
    //     bytes32 hashLock
    // ) public {
    //     require(opt.head.state > uint8(StateOfOpt.Issued), 
    //         "OR.LO: WRONG state");
    //     require(opt.head.state != uint8(StateOfOpt.Locked), 
    //         "OR.LO: WRONG state");
    //     require(block.timestamp < opt.body.closingDate, 
    //         "OR.LO: Missed ClosingDate");
    //     if (opt.hashLock == bytes32(0))
    //     {
    //         opt.hashLock = hashLock;
    //         opt.head.state = uint8(StateOfOpt.Locked);
    //     }
    // }

    // function closeOption(
    //     Option storage opt,
    //     string memory hashKey
    // ) public {
    //     require(opt.head.state > uint8(StateOfOpt.Issued), 
    //         "OR.CO: WRONG state");
    //     require(opt.head.state < uint8(StateOfOpt.Closed), 
    //         "OR.CO: WRONG state");

    //     require(
    //         block.timestamp <= opt.body.closingDate,
    //         "OR.CO: MISSED closingDate"
    //     );

    //     if (opt.head.state == uint8(StateOfOpt.Locked))
    //     {
    //         require(
    //             opt.hashLock == keccak256(bytes(hashKey)),
    //             "OR.CO: WRONG key"
    //         );
    //     }

    //     opt.head.state = uint8(StateOfOpt.Closed);
    // }

    // function revokeOption(Option storage opt, string memory hashKey) public {
    //     require(opt.head.state < uint8(StateOfOpt.Closed), "OR.RO: WRONG state");
    //     require(block.timestamp > opt.body.closingDate, "OR.RO: closingDate NOT expired");

    //     if (opt.head.state == uint8(StateOfOpt.Locked))
    //     {
    //         require(
    //             opt.hashLock == keccak256(bytes(hashKey)),
    //             "OR.CO: WRONG key"
    //         );
    //     }

    //     opt.head.state = uint8(StateOfOpt.Revoked);
    // }

    function _increaseCounterOfOptions(Repo storage repo) private returns(uint32 seqOfOpt) {
        repo.options[0].head.seqOfOpt++;
        seqOfOpt = repo.options[0].head.seqOfOpt;
    } 

    function _increaseCounterOfOrders(Record storage rcd) private returns (uint16 seqOfOdr){
        rcd.orders[0].seqOfShare++;
        seqOfOdr = uint16(rcd.orders[0].seqOfShare);
    }

    function _increaseCounterOfPldsOnOrder(Record storage rcd, uint256 seqOfOdr) private returns (uint16 seqOfPldOnOdr) {
        rcd.pledges[seqOfOdr][0].head.seqOfPldOnOdr++;
        seqOfPldOnOdr = rcd.pledges[seqOfOdr][0].head.seqOfPldOnOdr;
    }

    // ################
    // ##  查询接口  ##
    // ################

    // ==== Repo ====


    function counterOfOptions(Repo storage repo)
        public view returns (uint32)
    {
        return repo.options[0].head.seqOfOpt;
    }
    
    function optionsOfRepo(Repo storage repo) 
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

    // ==== Record ====
    
    function counterOfOrders(Record storage rcd)
        public view returns (uint16 seqOfOdr)
    {
        seqOfOdr = uint16(rcd.orders[0].seqOfShare);
    }

    function ordersOfOption(Record storage rcd)
        public view returns (Order[] memory)
    {
        uint256 len = counterOfOrders(rcd);
        Order[] memory output = new Order[](len);

        while (len > 0) {
            output[len - 1] = rcd.orders[len];
            len--;
        }

        return output;
    }

    function counterOfPledges(Record storage rcd, uint256 seqOfOdr) 
        public view
        returns (uint16)
    {
        return rcd.pledges[seqOfOdr][0].head.seqOfPldOnOdr;
    }

    function pledgesOfOrder(Record storage rcd, uint256 seqOfOdr)
        public view returns (PledgesRepo.Pledge[] memory)
    {
        uint256 len = counterOfPledges(rcd, seqOfOdr);
        PledgesRepo.Pledge[] memory output = new PledgesRepo.Pledge[](len);

        while (len > 0) {
            output[len - 1] = rcd.pledges[seqOfOdr][len];
            len--;
        }

        return output;
    }

    // ==== Order ====
    function balanceOfOrder(Repo storage repo, uint256 seqOfOpt)
        public view returns(uint64 paid, uint64 par)
    {
        paid = repo.options[seqOfOpt].body.paid -
            repo.records[seqOfOpt].orders[0].paid;
        par = repo.options[seqOfOpt].body.par -
            repo.records[seqOfOpt].orders[0].par;
    }

    function balanceOfPledge(Repo storage repo, uint256 seqOfOpt)
        public view returns(uint64 paid, uint64 par)
    {
        paid = repo.options[seqOfOpt].body.paid -
            repo.records[seqOfOpt].orders[0].paid;
        par = repo.options[seqOfOpt].body.par -
            repo.records[seqOfOpt].orders[0].par;
    }
}

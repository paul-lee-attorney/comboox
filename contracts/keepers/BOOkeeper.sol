// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOOKeeper.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOPSetting.sol";
import "../common/ruting/BOSSetting.sol";

import "../common/lib/RulesParser.sol";
import "../common/lib/OptionsRepo.sol";
import "../common/lib/PledgesRepo.sol";
import "../common/lib/SharesRepo.sol";

contract BOOKeeper is IBOOKeeper, BOOSetting, BOSSetting, BOPSetting, AccessControl {
    using RulesParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(uint256 seqOfOpt, uint256 caller) {
        require(caller == _getBOO().getOption(seqOfOpt).body.rightholder, 
            "NOT rightholder");
        _;
    }

    modifier onlySeller(uint256 seqOfOpt, uint256 caller) {
        OptionsRepo.Option memory opt = _getBOO().getOption(seqOfOpt);

        if (opt.head.typeOfOpt % 2 == 1) {
            require(caller == opt.body.rightholder, "BOOK.mf.OS: NOT rightholder of PutOption");
        } else require(_getBOO().isObligor(seqOfOpt, caller), "BOOK.mf.OS: NOT obligor of CallOption");
        _;
    }

    modifier onlyBuyer(uint256 seqOfOpt, uint256 caller) {
        OptionsRepo.Option memory opt = _getBOO().getOption(seqOfOpt);

        if (opt.head.typeOfOpt % 2 == 1)
            require(_getBOO().isObligor(seqOfOpt, caller), "BOOK.mf.OB: NOT obligor of PutOption");
        else {
            require(caller == opt.body.rightholder, "BOOK.mf.OB: NOT rightholder of CallOption");
        }

        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

    function createOption(
        uint256 sn,
        uint256 snOfCond,
        uint40 rightholder,
        uint64 paid,
        uint64 par,
        uint40 caller
    ) external onlyDirectKeeper {
        _getBOO().createOption(sn, snOfCond, rightholder, caller, paid, par);
    }

    function joinOptionAsObligor(uint256 seqOfOpt, uint256 caller) external onlyDirectKeeper {
        _getBOO().addObligorIntoOption(seqOfOpt, caller);
    }

    function removeObligorFromOption(
        uint256 seqOfOpt,
        uint256 obligor,
        uint256 caller
    ) external onlyDirectKeeper onlyRightholder(seqOfOpt, caller) {
        _getBOO().removeObligorFromOption(seqOfOpt, obligor);
    }

    function updateOracle(
        uint256 seqOfOpt,
        uint64 d1,
        uint64 d2,
        uint64 d3
    ) external onlyDirectKeeper {
        _getBOO().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt, uint256 caller)
        external
        onlyDirectKeeper
        onlyRightholder(seqOfOpt, caller)
    {
        _getBOO().execOption(seqOfOpt);
    }

    function addOrder(
        uint32 seqOfOpt,
        uint32 seqOfShare,
        uint64 paid,
        uint64 par,
        uint40 buyer,
        uint40 caller
    ) external onlyDirectKeeper onlyRightholder(seqOfOpt, caller) {
        _getBOS().decreaseCleanAmt(seqOfShare, paid, par);

        SharesRepo.Share memory share = _getBOS().getShare(seqOfShare);

        OptionsRepo.Order memory order = OptionsRepo.Order({
            seqOfOpt: seqOfOpt,
            seq: 0,
            seller: share.head.shareholder,
            buyer: buyer,
            paid: paid,
            par: par,
            seqOfShare: share.head.seq,
            state: 0
        });

        _getBOO().addOrder(seqOfOpt, order);
    }

    function removeOrder(
        uint32 seqOfOpt,
        uint16 seqOfOdr,
        uint40 caller
    ) external onlyDirectKeeper returns(bool flag)
    {
        IBookOfOptions _boo = _getBOO();
        
        OptionsRepo.Option memory opt = _boo.getOption(seqOfOpt);
        OptionsRepo.Order memory order = _boo.getOrderOfOption(seqOfOpt, seqOfOdr);
        
    }

    function requestPledge(
        uint256 seqOfOpt,
        uint256 seqOfOdr,
        uint32 seqOfShare,
        uint64 paid,
        uint64 par,
        bytes32 hashLock,
        uint256 caller
    ) external onlyDirectKeeper onlySeller(seqOfOpt, caller) {

        OptionsRepo.Order memory order = _getBOO().getOrderOfOption(seqOfOpt, seqOfOdr);

        require (order.buyer == _getBOS().getHeadOfShare(seqOfShare).shareholder,
            "BOOK.RP: share is not owned by buyer of order");

        PledgesRepo.Pledge memory pld;
        
        pld.head = PledgesRepo.Head({
            seqOfShare: seqOfShare,
            seqOfPldOnShare: 0,
            seqOfPldOnOdr: 0,
            createDate: uint48(block.timestamp),
            triggerDate: _getBOO().getOption(seqOfOpt).body.closingDate, 
            pledgor: order.buyer,
            debtor: order.buyer,
            state: 0
        });

        pld.body = PledgesRepo.Body({
            expireDate: _getBOO().getOption(seqOfOpt).body.closingDate + 86400,
            creditor: order.seller,
            paid: paid,
            par: par
        });

        pld.hashLock = hashLock;

        pld.head = _getBOP().regPledge(pld);

        _getBOO().requestPledge(seqOfOpt, seqOfOdr, pld);
    }

    function lockOption(
        uint256 seqOfOpt,
        bytes32 hashLock,
        uint256 caller
    ) external onlyDirectKeeper onlySeller(seqOfOpt, caller) {
        _getBOO().lockOption(seqOfOpt, hashLock);
    }

    function _recoverCleanPaidOfPlds(PledgesRepo.Pledge[] memory plds) private {
        uint256 len = plds.length;

        while (len > 0) {
            _getBOS().increaseCleanAmt(
                plds[len - 1].head.seqOfShare,
                plds[len - 1].body.paid,
                plds[len - 1].body.par
            );
            len--;
        }
    }

    function _recoverCleanPaidOfOrders(OptionsRepo.Order[] memory fts) private {
        uint256 len = fts.length;

        while (len > 0) {
            _getBOS().increaseCleanAmt(
                fts[len - 1].seqOfShare,
                fts[len - 1].paid,
                fts[len - 1].par
            );
            len--;
        }
    }

    function closeOption(
        uint256 seqOfOpt,
        string memory hashKey,
        // uint32 closingDate,
        uint256 caller
    ) external onlyDirectKeeper onlyBuyer(seqOfOpt, caller) {
        OptionsRepo.Option memory opt = _getBOO().getOption(seqOfOpt);

        // uint32 price = sn.rateOfOpt();

        _getBOO().closeOption(seqOfOpt, hashKey);

        OptionsRepo.Order[] memory fts = _getBOO().ordersOfOption(seqOfOpt);

        _recoverCleanPaidOfOrders(fts);

        for (uint256 i = 0; i < fts.length; i++) {
            _getBOS().transferShare(
                fts[i].seqOfShare,
                fts[i].paid,
                fts[i].par,
                uint40(caller),
                opt.head.rate
            );
        }

        _recoverCleanPaidOfPlds(_getBOO().pledgesOfOption(seqOfOpt));
    }

    function revokeOption(uint256 seqOfOpt, uint256 caller, string memory hashKey)
        external
        onlyDirectKeeper
        onlyRightholder(seqOfOpt, caller)
    {
        OptionsRepo.Option memory opt = _getBOO().getOption(seqOfOpt);

        IBookOfOptions _boo = _getBOO();

        _boo.revokeOption(seqOfOpt, hashKey);

        if (opt.head.typeOfOpt % 2 != 0) _recoverCleanPaidOfOrders(_boo.ordersOfOption(seqOfOpt));
        else _recoverCleanPaidOfPlds(_boo.pledgesOfOption(seqOfOpt));
    }

    function releasePledge(
        uint256 snOfOdr, 
        uint256 snOfPld, 
        string memory hashKey, 
        uint256 caller
    ) external onlyDirectKeeper {
        OptionsRepo.Order memory order = OptionsRepo.orderSNParser(snOfOdr);                
        PledgesRepo.Pledge memory pld = _getBOP().getPledge(snOfPld);

        if (_getBOP().releasePledge(snOfPld, hashKey)) {
            _getBOO().releasePledge(order, pld.head);

        }


        pld = _getBOP().getPledge(pld.head.seqOfShare, pld.head.seqOfPldOnShare);

        

        IBookOfOptions _boo = _getBOO();

        OptionsRepo.Option memory opt = _boo.getOption(seqOfOpt);

        require(_boo.stateOfOption(seqOfOpt) == 6, "option NOT revoked");

        if (opt.head.typeOfOpt % 2 != 0) _recoverCleanPaidOfPlds(_boo.pledgesOfOption(seqOfOpt));
        else _recoverCleanPaidOfOrders(_boo.ordersOfOption(seqOfOpt));
    }
}

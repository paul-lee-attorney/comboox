// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOOKeeper.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";

import "../common/lib/RulesParser.sol";
import "../common/lib/OptionsRepo.sol";
import "../common/lib/PledgesRepo.sol";

contract BOOKeeper is IBOOKeeper, BOOSetting, BOSSetting, AccessControl {
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

    function issueOption(
        bytes32 sn,
        uint256 rightholder,
        uint64 paid,
        uint64 par,
        uint256 caller
    ) external onlyDirectKeeper {
        // uint40[] memory obligors = new uint40[](1);
        // obligors[0] = caller;

        _getBOO().issueOption(sn, rightholder, caller, paid, par);
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
        uint32 d1,
        uint32 d2
    ) external onlyDirectKeeper {
        _getBOO().updateOracle(seqOfOpt, d1, d2);
    }

    function execOption(uint256 seqOfOpt, uint256 caller)
        external
        onlyDirectKeeper
        onlyRightholder(seqOfOpt, caller)
    {
        _getBOO().execOption(seqOfOpt);
    }

    function addFuture(
        uint256 seqOfOpt,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint256 caller
    ) external onlyDirectKeeper onlyRightholder(seqOfOpt, caller) {
        _getBOS().decreaseCleanAmt(seqOfShare, paid, par);

        OptionsRepo.Option memory opt = _getBOO().getOption(seqOfOpt);

        IBookOfShares.Share memory share = _getBOS().getShare(seqOfShare);
        OptionsRepo.Future memory ft = OptionsRepo.Future({
            seqOfFuture: 0,
            seqOfShare: uint32(seqOfShare),
            buyer: (opt.head.typeOfOpt % 2 == 1) ? 
                opt.body.obligor :
                uint40(caller),
            paid: paid,
            par: par,
            state: 0
        });

        _getBOO().addFuture(seqOfOpt, share, ft);
    }

    function removeFuture(
        uint256 seqOfOpt,
        uint256 seqOfFt,
        uint256 caller
    ) external onlyDirectKeeper onlyRightholder(seqOfOpt, caller) {

        OptionsRepo.Future memory ft = _getBOO().getFutureOfOption(seqOfOpt, seqOfFt);

        _getBOO().removeFuture(seqOfOpt, seqOfFt);
        _getBOS().increaseCleanAmt(ft.seqOfShare, ft.paid, ft.par);
    }

    function requestPledge(
        uint256 seqOfOpt,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint256 caller
    ) external onlyDirectKeeper onlySeller(seqOfOpt, caller) {
        IBookOfShares _bos = _getBOS();

        _bos.decreaseCleanAmt(seqOfShare, paid, par);

        IBookOfShares.Share memory share = _bos.getShare(seqOfShare);

        _getBOO().requestPledge(seqOfOpt, share, paid, par);
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
                plds[len - 1].body.pledgedPaid,
                plds[len - 1].body.pledgedPar
            );
            len--;
        }
    }

    function _recoverCleanPaidOfFts(OptionsRepo.Future[] memory fts) private {
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

        OptionsRepo.Future[] memory fts = _getBOO().futuresOfOption(seqOfOpt);

        _recoverCleanPaidOfFts(fts);

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

    function revokeOption(uint256 seqOfOpt, uint256 caller)
        external
        onlyDirectKeeper
        onlyRightholder(seqOfOpt, caller)
    {
        OptionsRepo.Option memory opt = _getBOO().getOption(seqOfOpt);

        IBookOfOptions _boo = _getBOO();

        _boo.revokeOption(seqOfOpt);

        if (opt.head.typeOfOpt % 2 != 0) _recoverCleanPaidOfFts(_boo.futuresOfOption(seqOfOpt));
        else _recoverCleanPaidOfPlds(_boo.pledgesOfOption(seqOfOpt));
    }

    function releasePledges(uint256 seqOfOpt, uint256 caller)
        external
        onlyDirectKeeper
        onlyRightholder(seqOfOpt, caller)
    {
        IBookOfOptions _boo = _getBOO();

        OptionsRepo.Option memory opt = _boo.getOption(seqOfOpt);

        require(_boo.stateOfOption(seqOfOpt) == 6, "option NOT revoked");

        if (opt.head.typeOfOpt % 2 != 0) _recoverCleanPaidOfPlds(_boo.pledgesOfOption(seqOfOpt));
        else _recoverCleanPaidOfFts(_boo.futuresOfOption(seqOfOpt));
    }
}

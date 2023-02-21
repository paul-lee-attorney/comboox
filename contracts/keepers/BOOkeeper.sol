// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOOKeeper.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";

import "../common/lib/SNParser.sol";

contract BOOKeeper is IBOOKeeper, BOOSetting, BOSSetting, AccessControl {
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(bytes32 sn, uint40 caller) {
        (uint40 rightholder, , , , ) = _getBOO().getOption(sn);
        require(caller == rightholder, "NOT rightholder");
        _;
    }

    modifier onlySeller(bytes32 sn, uint40 caller) {
        if (sn.typeOfOpt() % 2 == 1) {
            (uint40 rightholder, , , , ) = _getBOO().getOption(sn);
            require(caller == rightholder, "msgSender NOT rightholder");
        } else require(_getBOO().isObligor(sn, caller), "msgSender NOT seller");
        _;
    }

    modifier onlyBuyer(bytes32 sn, uint40 caller) {
        if (sn.typeOfOpt() % 2 == 1)
            require(_getBOO().isObligor(sn, caller), "caller NOT obligor");
        else {
            (uint40 rightholder, , , , ) = _getBOO().getOption(sn);
            require(caller == rightholder, "caller NOT rightholder");
        }

        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

    function createOption(
        bytes32 sn,
        uint40 rightholder,
        uint64 paid,
        uint64 par,
        uint40 caller
    ) external onlyDirectKeeper {
        uint40[] memory obligors = new uint40[](1);
        obligors[0] = caller;

        _getBOO().createOption(sn, rightholder, obligors, paid, par);
    }

    function joinOptionAsObligor(bytes32 sn, uint40 caller) external onlyDirectKeeper {
        _getBOO().addObligorIntoOption(sn, caller);
    }

    function removeObligorFromOption(
        bytes32 sn,
        uint40 obligor,
        uint40 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _getBOO().removeObligorFromOption(sn, obligor);
    }

    function updateOracle(
        bytes32 sn,
        uint32 d1,
        uint32 d2
    ) external onlyDirectKeeper {
        _getBOO().updateOracle(sn, d1, d2);
    }

    function execOption(bytes32 sn, uint40 caller)
        external
        onlyDirectKeeper
        onlyRightholder(sn, caller)
    {
        _getBOO().execOption(sn);
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint40 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _getBOS().decreaseCleanPar(shareNumber.ssn(), paid);
        _getBOO().addFuture(sn, shareNumber, paid, paid);
    }

    function removeFuture(
        bytes32 sn,
        bytes32 ft,
        uint40 caller
    ) external onlyDirectKeeper onlyRightholder(sn, caller) {
        _getBOO().removeFuture(sn, ft);
        _getBOS().increaseCleanPar(ft.shortShareNumberOfFt(), ft.paidOfFt());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar,
        uint40 caller
    ) external onlyDirectKeeper onlySeller(sn, caller) {
        _getBOS().decreaseCleanPar(shareNumber.ssn(), paidPar);
        _getBOO().requestPledge(sn, shareNumber, paidPar);
    }

    function lockOption(
        bytes32 sn,
        bytes32 hashLock,
        uint40 caller
    ) external onlyDirectKeeper onlySeller(sn, caller) {
        _getBOO().lockOption(sn, hashLock);
    }

    function _recoverCleanPar(bytes32[] memory plds) private {
        uint256 len = plds.length;

        while (len != 0) {
            _getBOS().increaseCleanPar(
                plds[len - 1].shortShareNumberOfFt(),
                plds[len - 1].paidOfFt()
            );
            len--;
        }
    }

    function closeOption(
        bytes32 sn,
        string memory hashKey,
        // uint32 closingDate,
        uint40 caller
    ) external onlyDirectKeeper onlyBuyer(sn, caller) {
        uint32 price = sn.rateOfOpt();

        _getBOO().closeOption(sn, hashKey);

        bytes32[] memory fts = _getBOO().futures(sn);

        _recoverCleanPar(fts);

        for (uint256 i = 0; i < fts.length; i++) {
            _getBOS().transferShare(
                fts[i].shortShareNumberOfFt(),
                fts[i].paidOfFt(),
                fts[i].parOfFt(),
                caller,
                price
            );
        }

        _recoverCleanPar(_getBOO().pledges(sn));
    }

    function revokeOption(bytes32 sn, uint40 caller)
        external
        onlyDirectKeeper
        onlyRightholder(sn, caller)
    {
        _getBOO().revokeOption(sn);

        if (sn.typeOfOpt() != 0) _recoverCleanPar(_getBOO().futures(sn));
        else _recoverCleanPar(_getBOO().pledges(sn));
    }

    function releasePledges(bytes32 sn, uint40 caller)
        external
        onlyDirectKeeper
        onlyRightholder(sn, caller)
    {
        require(_getBOO().stateOfOption(sn) == 6, "option NOT revoked");

        if (sn.typeOfOpt() != 0) _recoverCleanPar(_getBOO().pledges(sn));
        else _recoverCleanPar(_getBOO().futures(sn));
    }
}

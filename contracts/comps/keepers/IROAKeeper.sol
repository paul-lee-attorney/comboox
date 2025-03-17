// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "../common/access/IDraftControl.sol";
import "../common/components/IFilesFolder.sol";
import "../common/components/ISigPage.sol";

import "../books/roa/IInvestmentAgreement.sol";
import "../books/roa/IRegisterOfAgreements.sol";
import "../books/roc/IShareholdersAgreement.sol";
import "../books/roc/terms/ILockUp.sol";



import "../../lib/DocsRepo.sol";
import "../../lib/RulesParser.sol";
import "../../lib/SharesRepo.sol";
import "../../lib/InvestorsRepo.sol";

interface IROAKeeper {

    event PayOffCIDeal(uint indexed caller, uint indexed valueOfDeal);

    // #################
    // ##   Write IO  ##
    // #################

    function createIA(uint256 version, address msgSender) external;

    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash,
        address msgSender
    ) external;

    function signIA(
        address ia,
        address msgSender,
        bytes32 sigHash
    ) external;

    // ==== Deal & IA ====

    function pushToCoffer(
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline,
        address msgSender
    ) external;

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external;

    function transferTargetShare(
        address ia,
        uint256 seqOfDeal,
        address msgSender
    ) external;

    function issueNewShare(address ia, uint256 seqOfDeal, address msgSender) external;

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        address msgSender
    ) external;

    function payOffApprovedDeal(
        address ia,
        uint seqOfDeal,
        uint msgValue,
        address msgSender
    ) external;    

    function payOffApprovedDealInUSD(
        address ia,
        uint seqOfDeal,
        uint valueOfDeal,
        uint caller
    ) external;    

}

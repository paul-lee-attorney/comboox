// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
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

pragma solidity ^0.8.24;

import "./IROAKeeper.sol";

import "../common/access/RoyaltyCharge.sol";
import "../../lib/TypesList.sol";
import "../../lib/LibOfROAK.sol";

contract ROAKeeper is IROAKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    using InterfacesHub for address;
    using LibOfROAK for uint;

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function createIA(uint version) external onlyGKProxy {
 
        uint caller = _msgSender(msg.sender, 58000);

        require(gk.getROM().isMember(caller), "not MEMBER");

        DocsRepo.Doc memory doc = rc.getRC().cloneDoc(
            TypesList.InvestmentAgreement,
            version
        );

        IAccessControl(doc.body).initKeepers(
            address(this), gk
        );

        gk.getROA().regFile(DocsRepo.codifyHead(doc.head), doc.body);

        IOwnable(doc.body).setNewOwner(msg.sender);
    }

    // ======== Circulate IA ========

    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);
        caller.circulateIA(ia, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        bytes32 sigHash
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);
        caller.signIA(ia, sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);
        caller.pushToCoffer(ia, seqOfDeal, hashLock, closingDeadline);
    }

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external onlyGKProxy {
        LibOfROAK.closeDeal(ia, seqOfDeal, hashKey);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);
        caller.issueNewShare(ia, seqOfDeal);
    }

    function transferTargetShare(
        address ia,
        uint256 seqOfDeal
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);
        caller.transferTargetShare(ia, seqOfDeal);
    }

    function terminateDeal(
        address ia,
        uint256 seqOfDeal
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);
        caller.terminateDeal(ia, seqOfDeal);
    }

    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal,
        address to
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);
        uint payee = _msgSender(to, 18000);
        caller.payOffApprovedDeal(auth, ia, seqOfDeal, to, payee);
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
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

import "../common/access/RoyaltyCharge.sol";

import "./IROCKeeper.sol";
import "../../lib/TypesList.sol";
import "../../lib/LibOfROCK.sol";

contract ROCKeeper is IROCKeeper, RoyaltyCharge {
    using InterfacesHub for address;
    using LibOfROCK for uint;
    
    // #############
    // ##   SHA   ##
    // #############

    function createSHA(uint version) external onlyGKProxy {

        uint caller = _msgSender(msg.sender, 18000);

        require(gk.getROM().isMember(caller), "not MEMBER");

        DocsRepo.Doc memory doc = rc.getRC().cloneDoc(
            TypesList.ShareholdersAgreement,
            version
        );

        IAccessControl(doc.body).initKeepers(
            address(this),gk
        );

        IShareholdersAgreement(doc.body).initDefaultRules();

        gk.getROC().regFile(DocsRepo.codifyHead(doc.head), doc.body);

        IOwnable(doc.body).setNewOwner(msg.sender);
    }

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);
        caller.circulateSHA(sha, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        bytes32 sigHash
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);
        caller.signSHA(sha, sigHash);
    }

    function activateSHA(address sha) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);
        caller.activateSHA(sha);
    }

    function acceptSHA(bytes32 sigHash) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);
        caller.acceptSHA(sigHash);
    }
}

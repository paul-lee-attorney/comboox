// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/SigsRepo.sol";

interface IRepoOfDocs {
    enum RODStates {
        ZeroPoint,
        Created,
        Circulated,
        Established,
        Proposed,
        Voted,
        Executed,
        Revoked
    }

    struct Head {
        uint8 docType;
        uint40 creator;
        uint48 createDate;
        uint48 shaExecDeadline;
        uint48 proposeDeadline;
        uint8 state;
    }

    struct Doc {
        Head head;
        bytes32 docUrl;
        bytes32 docHash;
        SigsRepo.Page sigPage;
    }

    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address indexed temp, uint256 typeOfDoc);

    event UpdateStateOfDoc(address indexed body, uint8 state);

    event RemoveDoc(address indexed body);

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body, uint8 typeOfDoc) external;

    function createDoc(uint8 docType, uint40 creator) external returns (address body);

    function removeDoc(address body) external;

    function circulateDoc(
        address body,
        bytes32 rule,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    function pushToNextState(address body) external;

    // ==== Drafting ====
    
    function setSigDeadline(uint48 deadline) external; 

    function setClosingDeadline(uint48 deadline) external;

    function addBlank(uint40 acct, uint16 seq) external;

    function removeBlank(uint40 acct, uint16 seq) external;

    // ==== Execution ====

    function signDeal(
        address body, 
        uint16 seq, 
        uint40 caller, 
        bytes32 sigHash
    ) external;

    function signDoc(address body, uint40 caller, bytes32 sigHash) external;

    function acceptDoc(address body, uint40 caller, bytes32 sigHash) external;

    //##################
    //##   read I/O   ##
    //##################

    function template(uint8 typeOfDoc) external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function qtyOfDocs() external view returns (uint256);

    function docsList() external view returns (address[] memory);

    function getHeadOfDoc(address body) external view
        returns (Head memory head);

    function getRefOfDoc(address body)
        external
        view
        returns (bytes32 docUrl, bytes32 docHash); 

    // ==== SigPage ====

    function established(address body) external view
        returns (bool);

    function parasOfPage(address body) 
        external 
        view 
        returns (SigsRepo.Signature memory); 

    function sigDeadline(address body)
        external
        view
        returns (uint48);

    function closingDeadline(address body)
        external
        view
        returns (uint48);

    function isParty(address body, uint40 acct)
        external
        view
        returns(bool);

    function isInitSigner(address body, uint40 acct) 
        external 
        view 
        returns (bool);

    function qtyOfParties(address body)
        external
        view
        returns (uint256);

    function partiesOfDoc(address body)
        external
        view
        returns (uint40[] memory);

    function sigOfDeal(address body, uint16 seq, uint40 acct) 
        external
        view
        returns (SigsRepo.Signature memory);

    function sigOfDoc(address body, uint40 acct) 
        external
        view
        returns (SigsRepo.Signature memory);

}

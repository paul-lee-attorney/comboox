// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/SigsRepo.sol";
import "./ISigPage.sol";

interface IRepoOfDocs {
    
    enum RODStates {
        ZeroPoint,  // 0
        Created,    // 1
        Circulated, // 2
        Established,// 3
        Proposed,   // 4
        Voted,      // 5
        Executed,   // 6
        Revoked     // 7
    }

    enum TypeOfDoc {
        SigPage,                // 0
        InvestmentAgreement,    // 1
        MockResults,            // 2
        FirstRefusalDeals,      // 3
        ShareHoldersAgreement,  // 4
        LockUp,                 // 5
        AntiDilution,           // 6
        DragAlong,              // 7
        TagAlong,               // 8
        Options                 // 9
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
        address sigPage;
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

    function createDoc(uint8 docType, uint40 creator) external returns (address body, address sigPage);

    function removeDoc(address body) external;

    function circulateDoc(
        address body,
        bytes32 rule,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    function setStateOfDoc(address body, uint8 state) external;

    //##################
    //##   read I/O   ##
    //##################

    function template(uint8 typeOfDoc) external view returns (address);

    function tempsList() external view returns (uint256[] memory);

    function tempReadyFor(uint8 typeOfDoc) external view returns (bool flag);

    function isRegistered(address body) external view returns (bool);

    function qtyOfDocs() external view returns (uint256);

    function docsList() external view returns (address[] memory);

    function getHeadOfDoc(address body) external view
        returns (Head memory head);

    function getRefOfDoc(address body)
        external
        view
        returns (bytes32 docUrl, bytes32 docHash); 

    function sigPageOfDoc(address body)
        external
        view
        returns (ISigPage sigPage); 

}

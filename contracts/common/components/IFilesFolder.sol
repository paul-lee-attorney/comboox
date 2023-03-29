// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/EnumerableSet.sol";
import "../lib/DocsRepo.sol";
import "../lib/RulesParser.sol";

interface IFilesFolder {
    
    enum StateOfFile {
        ZeroPoint,  // 0
        Created,    // 1
        Circulated, // 2
        Established,// 3
        Proposed,   // 4
        Voted,      // 5
        Executed,   // 6
        Revoked     // 7
    }

    struct Head {
        uint256 snOfDoc;
        uint48 shaExecDeadline;
        uint48 proposeDeadline;
        uint8 state;        
    }

    struct Ref {
        bytes32 docUrl;
        bytes32 docHash;
    }

    struct File {
        Head head;
        Ref ref;
    }

    struct Folder {
        mapping(address => File) files;
        EnumerableSet.AddressSet filesList;
    }

    //##############
    //##  Event   ##
    //##############

    event UpdateStateOfFile(address indexed body, uint8 state);

    //##################
    //##    写接口    ##
    //##################

    function createDoc(uint16 typeOfDoc, uint16 version, uint40 creator) external returns (address body);

    function circulateDoc(
        address body,
        RulesParser.VotingRule memory rule,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    function setStateOfFile(address body, uint8 state) external;

    //##################
    //##   read I/O   ##
    //##################

    function isRegistered(address body) external view returns (bool);

    function qtyOfFiles() external view returns (uint256);

    function filesList() external view returns (address[] memory);

    function getHeadOfFile(address body) external view
        returns (Head memory head);

    function getRefOfFile(address body)
        external view returns (Ref memory ref); 

}

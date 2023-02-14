// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IRepoOfDocs {
    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address indexed temp, uint256 typeOfDoc);

    event UpdateStateOfDoc(address indexed body, uint8 state);

    event RemoveDoc(address indexed body);

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body, uint256 typeOfDoc) external;

    function createDoc(uint256 docType, uint256 creator)
        external
        returns (address body);

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

    function signDeal(address body, uint40 caller, uint16 seq, bytes32 sigHash)
        external;

    function signDoc(address body, uint40 caller, bytes32 sigHash) external;

    function acceptDoc(address body, bytes32 sigHash, uint40 caller) external; 

    //##################
    //##    读接口    ##
    //##################

    function template(uint8 typeOfDoc) external view returns (address);

    function isRegistered(address body) external view returns (bool);

    function passedExecPeriod(address body) external view returns (bool);

    function isCirculated(address body) external view returns (bool);

    function qtyOfDocs() external view returns (uint256);

    function docsList() external view returns (address[] memory);

    function getDoc(address body)
        external
        view
        returns (
            uint8 docType,
            uint40 creator,
            uint48 createDate,
            bytes32 docUrl,
            bytes32 docHash
        );

    function currentState(address body) external view returns (uint8);

    function shaExecDeadlineOf(address body) external view returns (uint48);

    function proposeDeadlineOf(address body) external view returns (uint48);

    //####################
    //##    查询接口    ##
    //####################

    function established(address body) external view returns (bool);

    function sigDeadline(address body) external view returns (uint48);

    function closingDeadline(address body) external view returns (uint48);

    function isParty(address body, uint40 acct) external view returns (bool);

    function isInitSigner(address body, uint40 acct) external view returns (bool);

    function partiesOfDoc(address body) external view returns (uint40[] memory);

    function qtyOfParties(address body) external view returns (uint256);

    function sigCounter(address body) external view returns (uint16);

    function sigOfDeal(address body, uint40 acct, uint16 ssn)
        external
        view
        returns (
            uint64 blocknumber,
            uint48 sigDate,
            bytes32 sigHash
        );

    function sigOfDoc(address body, uint40 acct) 
        external 
        view 
        returns (
            uint64 blocknumber,
            uint48 sigDate,
            bytes32 sigHash
        );

}

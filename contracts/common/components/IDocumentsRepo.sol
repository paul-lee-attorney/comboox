// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IDocumentsRepo {
    //##############
    //##  Event   ##
    //##############

    event SetTemplate(address temp, uint8 typeOfDoc);

    event UpdateStateOfDoc(address indexed body, uint8 state);

    event RemoveDoc(address indexed body);

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body, uint8 typeOfDoc) external;

    function createDoc(uint8 docType, uint40 creator)
        external
        returns (address body);

    function removeDoc(address body) external;

    function circulateDoc(
        address body,
        bytes32 rule,
        bytes32 docHash
    ) external;

    function pushToNextState(address body) external;

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
            bytes32 docHash
        );

    function currentState(address body) external view returns (uint8);

    function shaExecDeadlineBNOf(address body) external view returns (uint64);

    function proposeDeadlineBNOf(address body) external view returns (uint64);
}

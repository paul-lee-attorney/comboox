// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/MotionsRepo.sol";

import "../../common/components/IMeetingMinutes.sol";

interface IBookOfMotions is IMeetingMinutes {
    //##################
    //##    events    ##
    //##################

    event NominateDirector(
        uint256 indexed motionId,
        uint40 candidate,
        uint40 nominator
    );

    event ProposeDoc(uint256 indexed motionId, address doc, uint40 submitter);

    event SetRegNumberHash(bytes32 numHash);

    //##################
    //##    写接口    ##
    //##################

    function createCorpSeal() external;

    function createBoardSeal(address bod) external;

    function setRegNumberHash(bytes32 numHash) external;

    function nominateDirector(uint40 candidate, uint40 nominator) external;

    function proposeDoc(address doc, uint8 typeOfDoc, uint40 submitter) external;

    function requestToBuy(address ia, bytes32 sn)
        external
        view
        returns (uint64 paid, uint64 par);

    //##################
    //##    读接口    ##
    //##################

    function regNumHash() external view returns (bytes32);

    function verifyRegNum(string memory regNum) external view returns (bool);
}

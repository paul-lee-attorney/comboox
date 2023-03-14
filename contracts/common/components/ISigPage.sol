// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../ruting/IRODSetting.sol";

import "../lib/SigsRepo.sol";

interface ISigPage {

    event SetSigDeadline (bool initPage, uint48 SigDeadline);

    function setSigDeadline(
        bool initPage,
        uint48 sigDeadline
    ) external;

    // function addParty(uint256 acct) external;

    function signDoc(bool initPage, uint256 caller, bytes32 sigHash) external;    

    function regSig(uint256 seqOfDeal, uint256 signer, uint48 sigDate, bytes32 sigHash)
        external returns(bool flag);

    // function signDeal(uint256 seqOfDeal, uint256 caller, bytes32 sigHash) external;

    //##################
    //##   read I/O   ##
    //##################

    function getParasOfPage(bool initPage) 
        external 
        view 
        returns (SigsRepo.Signature memory);

    function established() external view
        returns (bool flag);

    function isBuyer(bool initPage, uint256 acct)
        external
        view
        returns(bool flag);

    function isSeller(bool initPage, uint256 acct)
        external
        view
        returns(bool flag);

    function isParty(bool initPage, uint256 acct)
        external
        view
        returns(bool flag);

    function isSigner(bool initPage, uint256 acct)
        external 
        view 
        returns (bool flag);

    function getBuyers(bool initPage)
        external
        view
        returns (uint256[] memory buyers);

    function getSellers(bool initPage)
        external
        view
        returns (uint256[] memory sellers);

    function getSigOfParty(bool initParty, uint256 acct) 
        external
        view
        returns (uint256[] memory seqOfDeals, SigsRepo.Signature memory sig);

    function getSigsOfPage(bool initPage) 
        external view
        returns (SigsRepo.Signature[] memory sigsOfBuyer, SigsRepo.Signature[] memory sigsOfSeller);
}

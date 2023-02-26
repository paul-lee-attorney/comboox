// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../ruting/IRODSetting.sol";

import "../lib/SigsRepo.sol";

interface ISigPage {

    event SetParasOfDoc (uint48 SigDeadline, uint48 ClosingDeadline);

    event SignDeal (uint16 seq, uint40 signer, bytes32 sigHash);

    function setBodyOfSigs(address body) external;

    function setParasOfDoc(
        uint48 sigDeadline, 
        uint48 closingDeadline
    ) external;

    function addBlank(uint16 seq, uint40 acct) external;

    function removeBlank(uint16 seq, uint40 acct) external;

    function addParty(uint40 acct) external;

    // ==== Execution ====

    function signDeal(uint16 seq, uint40 signer, bytes32 sigHash) external;

    function signDoc(uint40 caller, bytes32 sigHash) external;

    function acceptDoc(uint40 caller, bytes32 sigHash) external;

    //##################
    //##   read I/O   ##
    //##################

    function established() external view
        returns (bool);

    function isParty(uint40 acct)
        external
        view
        returns(bool);

    function isInitSigner(uint40 acct) 
        external 
        view 
        returns (bool);

    function qtyOfParties()
        external
        view
        returns (uint256);

    function partiesOfDoc()
        external
        view
        returns (uint40[] memory);

    function sigOfDeal(uint16 seq, uint40 acct) 
        external
        view
        returns (SigsRepo.Signature memory);

    function sigOfDoc(uint40 acct) 
        external
        view
        returns (SigsRepo.Signature memory);
    
    function parasOfPage() 
        external 
        view 
        returns (SigsRepo.Signature memory);

}

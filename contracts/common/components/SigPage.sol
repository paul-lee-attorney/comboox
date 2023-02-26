// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ISigPage.sol";

import "../access/AccessControl.sol";

import "../lib/SigsRepo.sol";
import "../lib/EnumerableSet.sol";

contract SigPage is ISigPage, AccessControl {
    using SigsRepo for SigsRepo.Page;
    using EnumerableSet for EnumerableSet.UintSet;

    SigsRepo.Page private _sigPage;

    modifier onlyBody {
        require(uint256(uint160(msg.sender)) == uint256(_sigPage.signatures[0].sigHash), 
            "SP.OB: caller is not body");
        _;
    }

    modifier bodyOrKeeper {
        require(
            uint256(uint160(msg.sender)) == uint256(_sigPage.signatures[0].sigHash) ||
            _gk.isKeeper(msg.sender),
            "SP.mf.BOK: neither body nor keeper"
        );
        _;
    }


    //####################
    //##    设置接口     ##
    //####################

    function setBodyOfSigs(
        address body
    ) external onlyBody {
        require (_sigPage.signatures[0].sigHash != bytes32(0), "SP.SBOSP: body already set");
        _sigPage.setBodyOfSigs(body);
    }

    function setParasOfDoc(
        uint48 sigDeadline, 
        uint48 closingDeadline
        ) external onlyAttorney
    {
        _sigPage.setParasOfDoc(sigDeadline, closingDeadline);
        emit SetParasOfDoc(sigDeadline, closingDeadline);
    }

    function addBlank(uint16 seq, uint40 acct) external bodyOrKeeper{
        _sigPage.addBlank(seq, acct);
    }

    function removeBlank(uint16 seq, uint40 acct) external onlyBody {
        _sigPage.removeBlank(seq, acct);
    }

    function addParty(uint40 acct) external onlyAttorney {
        _sigPage.addBlank(0, acct);
    }

    // ==== Execution ====

    function signDeal(uint16 seq, uint40 signer, bytes32 sigHash)
        public onlyKeeper
    {
        if (_sigPage.signDeal(seq, signer, sigHash))
            emit SignDeal(seq, signer, sigHash);
    }

    function signDoc(uint40 caller, bytes32 sigHash)
        external
        onlyDirectKeeper
    {
        signDeal(0, caller, sigHash);
    }

    function acceptDoc(uint40 caller, bytes32 sigHash) 
        external 
        onlyDirectKeeper
    {
        require(_sigPage.established(),
            "SP.AD: Doc not established");
        
        signDeal(0, caller, sigHash);
    }

    //##################
    //##   read I/O   ##
    //##################

    function established() external view
        returns (bool) 
    {
        return _sigPage.established();
    }

    function isParty(uint40 acct)
        public
        view
        returns(bool)
    {
        return _sigPage.parties.contains(acct);
    }

    function isInitSigner(uint40 acct)
        external 
        view 
        returns (bool) 
    {
        return isParty(acct) && _sigPage.signatures[acct].signer == acct;
    }

    function qtyOfParties()
        external
        view
        returns (uint256)
    {
        return _sigPage.parties.length();
    }

    function partiesOfDoc()
        external
        view
        returns (uint40[] memory)
    {
        return _sigPage.parties.valuesToUint40();
    }

    function sigOfDeal(uint16 seq, uint40 acct) 
        external
        view
        returns (SigsRepo.Signature memory)
    {
        return _sigPage.sigOfDeal(seq, acct);
    }

    function sigOfDoc(uint40 acct) 
        external
        view
        returns (SigsRepo.Signature memory)
    {
        return _sigPage.sigOfDeal(0, acct);
    }
    
    function parasOfPage() 
        external 
        view
        returns (SigsRepo.Signature memory) 
    {
        return _sigPage.signatures[0];
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ISigPage.sol";

import "../access/AccessControl.sol";

contract SigPage is ISigPage, AccessControl {
    using SigsRepo for SigsRepo.Page;
    using EnumerableSet for EnumerableSet.UintSet;
    using ArrayUtils for uint256[];

    SigsRepo.Page[2] internal _sigPages;

    //####################
    //##    设置接口     ##
    //####################

    function setSigDeadline(bool initPage, uint48 sigDeadline) external onlyAttorney
    {
        if (initPage) _sigPages[0].setSigDeadline(sigDeadline);
        else _sigPages[1].setSigDeadline(sigDeadline);

        emit SetSigDeadline(initPage, sigDeadline);
    }

    function regSig(uint256 seqOfDeal, uint256 signer, uint48 sigDate, bytes32 sigHash)
        external onlyKeeper returns (bool flag)
    {
        flag = _sigPages[1].regSig(seqOfDeal, signer, sigDate, sigHash);
    }

    function addBlank(bool beBuyer, uint256 seqOfDeal, uint256 acct)
        external onlyKeeper
    {
        _sigPages[1].addBlank(beBuyer, seqOfDeal, acct);
    }

    function signDoc(bool initPage, uint256 caller, bytes32 sigHash)
        external onlyKeeper
    {
        if (initPage) {
            _sigPages[0].signDoc(caller, sigHash);
        } else {
            _sigPages[1].signDoc(caller, sigHash);
        }
    }

    //##################
    //##   read I/O   ##
    //##################

    function getParasOfPage(bool initPage) external view
        returns (SigsRepo.Signature memory) 
    {
        return initPage ? _sigPages[0].blanks[0].sig :
            _sigPages[1].blanks[0].sig;
    }
    
    function established() external view
        returns (bool flag) 
    {
        flag =  _sigPages[1].buyers.length() > 0 ?
                    _sigPages[1].established() && _sigPages[0].established() :
                    _sigPages[0].established();
    }

    function isBuyer(bool initPage, uint256 acct)
        public view returns(bool flag)
    {
        flag = initPage ? _sigPages[0].buyers.contains(acct) :
            _sigPages[1].buyers.contains(acct);
    }

    function isSeller(bool initPage, uint256 acct)
        public view returns(bool flag)
    {
        flag = initPage ? _sigPages[0].sellers.contains(acct) :
            _sigPages[1].sellers.contains(acct);
    }

    function isParty(bool initPage, uint256 acct)
        public view returns(bool flag)
    {
        flag = isBuyer(initPage, acct) || isSeller(initPage, acct);
    }

    function isSigner(bool initPage, uint256 acct)
        external view returns (bool flag) 
    {
        flag = initPage ? _sigPages[0].isSigner(acct) :
            _sigPages[1].isSigner(acct);
    }

    function getBuyers(bool initPage)
        public view returns (uint256[] memory buyers)
    {
        buyers = initPage ? _sigPages[0].buyers.values() :
            _sigPages[0].buyers.values();
    }

    function getSellers(bool initPage)
        public view returns (uint256[] memory sellers)
    {
        sellers = initPage ? _sigPages[0].sellers.values():
            _sigPages[1].sellers.values();
    }

    function getParties() external view
        returns (uint256[] memory parties)
    {
        uint256[] memory buyers = getBuyers(true);
        buyers.merge(getBuyers(false));

        uint256[] memory sellers = getSellers(true);
        sellers.merge(getSellers(false));
        
        parties = buyers.merge(sellers);
    }

    function isParty(uint256 acct) external view returns (bool flag) {
        flag = _sigPages[0].buyers.contains(acct) ||
            _sigPages[0].sellers.contains(acct) ||
            _sigPages[1].buyers.contains(acct) ||
            _sigPages[1].sellers.contains(acct);
    }

    function getSigOfParty(bool initPage, uint256 acct) 
        external view
        returns (uint256[] memory seqOfDeals, SigsRepo.Signature memory sig)
    {
        if (initPage) {
            return _sigPages[0].sigOfParty(acct);
        } else {
            return _sigPages[1].sigOfParty(acct);
        }
    }
    
    function getSigsOfPage(bool initPage) 
        external view
        returns (
            SigsRepo.Signature[] memory sigsOfBuyer, 
            SigsRepo.Signature[] memory sigsOfSeller
        ) 
    {
        if (initPage) {
            return _sigPages[0].sigsOfPage();
        } else {
            return _sigPages[1].sigsOfPage();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library SigsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Signature {
        uint40 signer;
        uint48 sigDate;
        uint64 blocknumber;
        bytes32 sigHash;
    }

    struct Blank{
        EnumerableSet.UintSet seqOfDeals;
        Signature sig;
    }

    // blanks[0].sig {
    //     signer: sigCounter;
    //     sigDate: sigDeadline;
    //     blocknumber: blankCounter;
    //     sigHash: established;
    // }

    struct Page {
        // party => Blank
        mapping(uint256 => Blank) blanks;
        EnumerableSet.UintSet buyers;
        EnumerableSet.UintSet sellers;
    }

    //###################
    //##    设置接口    ##
    //###################

    function setSigDeadline(
        Page storage p,
        uint48 sigDeadline
    ) public {
        
        require(sigDeadline > block.timestamp, 
                "SR.SD: not future time");

        require(!established(p), "SR.SD: doc already established");

        p.blanks[0].sig.sigDate = sigDeadline;
    }

    function addBlank(
        Page storage p,
        bool beBuyer,
        uint256 seq,
        uint256 acct
    ) public {
        require (seq > 0, "SR.AB: zero seq");
        require (acct > 0, "SR.AB: zero acct");

        
        if (beBuyer) {
            require(!p.sellers.contains(acct), "SR.AB: seller intends to buy");
            p.buyers.add(acct);
        } else {
            require(!p.buyers.contains(acct), "SR.AB: buyer intends to sell");
            p.sellers.add(acct);
        }

        if (p.blanks[acct].seqOfDeals.add(seq))
            p.blanks[0].sig.blocknumber++;
    }

    function removeBlank(
        Page storage p,
        uint256 seq,
        uint256 acct
    ) public {
        if (p.buyers.contains(acct) || p.sellers.contains(acct)) {
            if (p.blanks[acct].seqOfDeals.remove(seq))
                p.blanks[0].sig.blocknumber--;

            if (p.blanks[acct].seqOfDeals.length() == 0) {
                delete p.blanks[acct]; 
                p.buyers.remove(acct) || p.sellers.remove(acct);
            }
        }
    }

    function signDoc(Page storage p, uint256 acct, bytes32 sigHash) 
        public returns (bool flag)
    {
        require(p.blanks[0].sig.sigDate >= block.timestamp,
            "SR.SD: missed sigDeadline");

        require(!established(p),
            "SR.SD: Doc already established");

        if ((p.buyers.contains(acct) || p.sellers.contains(acct)) &&
            p.blanks[acct].sig.sigDate == 0) {

            // uint40 numOfBlanks = uint40(p.blanks[acct].seqOfDeals.length() - 
            //     p.blanks[acct].signedDeals.length());

            // if (numOfBlanks > 0) {
            p.blanks[acct].sig = Signature({
                signer: uint40(acct),
                sigDate: uint48(block.timestamp),
                blocknumber: uint64(block.number),
                sigHash: sigHash
            });

            p.blanks[0].sig.signer += uint40(p.blanks[acct].seqOfDeals.length()); 

            if (p.blanks[0].sig.blocknumber == p.blanks[0].sig.signer)
                p.blanks[0].sig.sigHash = bytes32("true");

            flag = true;   
            // }
        }
    }

    function regSig(Page storage p, uint256 seqOfDeal, uint256 acct, uint48 sigDate, bytes32 sigHash)
        public returns (bool flag)
    {
        require(p.blanks[0].sig.sigDate >= block.timestamp,
            "SR.SD: missed sigDeadline");

        require(!established(p),
            "SR.SD: Doc already established");

        if ((p.buyers.contains(acct) ||
            p.sellers.contains(acct)) && 
            p.blanks[acct].seqOfDeals.add(seqOfDeal))
        {
            p.blanks[acct].sig = Signature({
                signer: uint40(acct),
                sigDate: sigDate,
                blocknumber: uint64(block.number),
                sigHash: sigHash
            });

            p.blanks[0].sig.signer++;

            if (p.blanks[0].sig.blocknumber == p.blanks[0].sig.signer)
                p.blanks[0].sig.sigHash = bytes32("true");

            flag = true;
        }

    }

    // function signDeal(
    //     Page storage p,
    //     uint256 seqOfDeal,
    //     uint256 acct,
    //     bytes32 sigHash
    // ) public returns (bool flag)
    // {

    //     require(p.blanks[0].sig.sigDate >= block.timestamp,
    //         "SR.SD: missed sigDeadline");

    //     require(!established(p),
    //         "SR.SD: Doc already established");

    //     if (p.parties.contains(acct) && 
    //         p.blanks[acct].seqOfDeals.contains(seqOfDeal) &&
    //         p.blanks[acct].signedDeals.add(seqOfDeal))
    //     {
    //         p.blanks[acct].sig = Signature({
    //             signer: uint40(acct),
    //             sigDate: uint48(block.timestamp),
    //             blocknumber: uint64(block.number),
    //             sigHash: sigHash
    //         });

    //         p.blanks[0].sig.signer++;

    //         if (p.blanks[0].sig.blocknumber == p.blanks[0].sig.signer)
    //             p.blanks[0].sig.sigHash = bytes32("true");

    //         flag = true;
    //     }

    // }

    //####################
    //##    查询接口     ##
    //####################

    // function isSeller(Page storage p, uint256 acct)
    //     public view returns(bool flag) 
    // {
    //     flag = p.sellers.contains(acct);
    // }

    // function isBuyer(Page storage p, uint256 acct)
    //     public view returns(bool flag) 
    // {
    //     flag = p.buyers.contains(acct);
    // }

    // function isParty(Page storage p, uint256 acct) 
    //     public view returns (bool flag) 
    // {
    //     flag = isBuyer(p, acct) || isSeller(p, acct);
    // }

    function isSigner(Page storage p, uint256 acct) 
        public view returns (bool flag) 
    {
        flag = acct & p.blanks[acct].sig.sigDate > 0;
    }

    // function counterOfSigs(Page storage page) 
    //     public view 
    //     returns(uint40) 
    // {
    //     return page.blanks[0].sig.signer;
    // }

    function established(Page storage p)
        public view
        returns (bool flag)
    {
        flag = p.blanks[0].sig.sigHash > bytes32(0);
    }

    function sigOfParty(
        Page storage p,
        uint256 acct
    )
        public view
        returns (uint256[] memory seqOfDeals, Signature memory sig)
    {
        seqOfDeals = p.blanks[acct].seqOfDeals.values();
        sig = p.blanks[acct].sig;
    }

    function sigsOfPage(Page storage p) 
        public view
        returns (Signature[] memory sigsOfBuyer, Signature[]memory sigsOfSeller)
    {
        sigsOfBuyer = sigsOfSide(p, p.buyers);
        sigsOfSeller = sigsOfSide(p, p.sellers);
    }

    function sigsOfSide(Page storage p, EnumerableSet.UintSet storage partiesOfSide) 
        public view
        returns (Signature[] memory)
    {
        uint256[] memory parties = partiesOfSide.values();
        uint256 len = parties.length;

        Signature[] memory sigs = new Signature[](len);

        while (len > 0) {
            sigs[len-1] = p.blanks[parties[len-1]].sig;
            len--;
        }

        return sigs;
    }


}

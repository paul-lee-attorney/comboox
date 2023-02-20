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
        uint16 seq;
        uint40 signer;
        uint48 sigDate;
        uint64 blocknumber;
        bytes32 sigHash;
    }

    // signatures[0] {
    //     seq: blankCounter;
    //     signer: sigCounter;
    //     sigDate: sigDeadline;
    //     blocknumber: closingDeadline;
    //     sigHash: established;
    // }

    struct Page {
        // seq & party => Signature
        mapping(uint256 => Signature) signatures;
        EnumerableSet.UintSet parties;
    }

    //####################
    //##    modifier    ##
    //####################

    modifier onlyFutureTime(uint48 date) {
        require(
            date > block.timestamp,
            "SR.OFT: NOT future"
        );
        _;
    }

    //###################
    //##    设置接口    ##
    //###################

    function getSig(Page storage p, uint256 seq, uint256 acct) 
        public view returns(Signature storage sig)
    {
        require(acct > 0, "SR.CSI: zero acct");
        return p.signatures[(seq << 40) + acct]; 
    }

    function setSigDeadline(Page storage p, uint48 deadline)
        public
        onlyFutureTime(deadline)
    {
        p.signatures[0].sigDate = deadline;
    }

    function setClosingDeadline(Page storage p, uint48 deadline)
        public
        onlyFutureTime(deadline)
    {
        p.signatures[0].blocknumber = deadline;
    }

    function addBlank(
        Page storage p,
        uint16 seq,
        uint40 acct
    ) public {
        Signature storage sig = getSig(p, seq, acct);

        if (sig.signer == 0) {

            sig.seq = seq;
            sig.signer = acct;

            p.parties.add(acct);

            p.signatures[0].seq++;

            if (p.signatures[0].sigHash != bytes32(0))
                p.signatures[0].sigHash = bytes32(0);
        }
    }

    function removeBlank(
        Page storage p,
        uint16 seq,
        uint40 acct
    ) public {
        Signature storage sig = getSig(p, seq, acct);

        if (sig.signer == acct && sig.sigDate == 0) {
            sig.signer = 0;
            sig.seq = 0;            

            p.parties.remove(acct);

            p.signatures[0].seq--;
        }
    }

    function signDeal(
        Page storage p,
        uint16 seq,
        uint40 acct,
        bytes32 sigHash
    ) public {
        Signature storage sig = getSig(p, seq, acct);
        
        if (sig.signer == acct && sig.sigDate == 0) {

            sig.seq = seq;
            sig.signer = acct;
            sig.sigDate = uint48(block.timestamp);
            sig.blocknumber = uint64(block.number);
            sig.sigHash = sigHash;

            p.signatures[0].signer++;

            if (p.signatures[0].seq == p.signatures[0].signer) {
                p.signatures[0].sigHash = bytes32("T");
            }
        }
    }

    //####################
    //##    查询接口     ##
    //####################

    // function isParty(Page storage p, uint40 acct) public view returns (bool) {
    //     return p.parties.contains(acct);
    // }

    // function qtyOfParties(Page storage p) public view returns (uint256) {
    //     return p.parties.length();
    // }

    // function partiesOfDoc(Page storage p)
    //     public
    //     view
    //     returns (uint256[] memory)
    // {
    //     return p.parties.values();
    // }

    function sigOfDeal(
        Page storage p,
        uint16 seq,
        uint40 acct
    )
        public
        view
        returns (Signature memory )
    {
        return getSig(p, seq, acct);
    }

    function parasOfPage(Page storage p)
        public view
        returns (Signature memory)
    {
        return p.signatures[0];
    }

    // ==== parasOfPage ====

    function established(Page storage p) public view
        returns (bool) 
    {
        return p.signatures[0].sigHash == bytes32("T");
    }
}

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
    //     sigHash: docBody;
    // }

    struct Page {
        // seq & party => Signature
        mapping(uint256 => Signature) signatures;
        EnumerableSet.UintSet parties;
    }

    //###################
    //##    设置接口    ##
    //###################

    function getSigId(uint256 seq, uint256 acct) 
        public pure returns(uint256 sigId)
    {
        require(acct > 0, "SR.GSI: zero acct");
        sigId = (seq << 40) + acct;
    }

    function setBodyOfSigs(
        Page storage p,
        address body
    ) public {
        p.signatures[0].sigHash = bytes32(uint256(uint160(body)));
    }

    function setParasOfDoc(
        Page storage p,
        uint48 sigDeadline, 
        uint48 closingDeadline
    ) public {
        
        require(sigDeadline > block.timestamp && 
            closingDeadline > sigDeadline, 
            "SR.SD: not logical time");

        require(!established(p), "SR.SD: doc already established");

        p.signatures[0].sigDate = sigDeadline;
        p.signatures[0].blocknumber = closingDeadline;
    }

    function addBlank(
        Page storage p,
        uint16 seq,
        uint40 acct
    ) public {
        Signature storage sig = p.signatures[getSigId(seq, acct)];

        if (sig.signer == 0) {
            sig.seq = seq;
            sig.signer = acct;

            p.signatures[0].seq++;

            p.parties.add(acct);
        }        
    }

    function removeBlank(
        Page storage p,
        uint16 seq,
        uint40 acct
    ) public {
        uint256 sigId = getSigId(seq, acct);

        if (p.signatures[sigId].sigDate == 0) {
            delete p.signatures[sigId];
            p.signatures[0].seq--;

            p.parties.remove(acct);
        }
    }

    function signDeal(
        Page storage p,
        uint16 seq,
        uint40 acct,
        bytes32 sigHash
    ) public returns (bool flag)
    {
        uint256 sigId = getSigId(seq, acct);

        Signature storage sig = p.signatures[sigId];
        
        if (sig.seq == seq &&
            sig.signer == acct && 
            sig.sigDate == 0) 
        {

            sig.sigDate = uint48(block.timestamp);
            sig.blocknumber = uint64(block.number);
            sig.sigHash = sigHash;

            p.signatures[0].signer++;

            flag = true;
        }
    }

    //####################
    //##    查询接口     ##
    //####################

    function sigOfDeal(
        Page storage p,
        uint16 seq,
        uint40 acct
    )
        public view
        returns (Signature memory )
    {
        return p.signatures[getSigId(seq, acct)];
    }

    function established(Page storage p)
        public view
        returns (bool flag)
    {
        flag = (p.signatures[0].seq > 0 && 
            p.signatures[0].seq == p.signatures[0].signer);
    }
}

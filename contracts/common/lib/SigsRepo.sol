// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/EnumerableSet.sol";

library SigsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Signature {
        uint40 signer;
        uint64 blocknumber;
        uint48 sigDate;
        bytes32 sigHash;
    }

    // signatures[0][0] {
    //     signer: sigCounter;
    //     blocknumber: sigDeadline;
    //     sigDate: closingDeadline;
    //     sigHash: established;
    // }

    struct Page {
        // userNo => seq => Signature
        mapping(uint256 => mapping(uint256 => Signature)) signatures;
        uint16 blankCounter;
        EnumerableSet.UintSet parties;
    }

    //####################
    //##    modifier    ##
    //####################

    // modifier onlyParty(Page storage p, uint40 caller) {
    //     require(isParty(p, caller), "SP.onlyParty: caller NOT a party");
    //     _;
    // }

    modifier onlyFutureTime(uint48 date) {
        require(
            date > block.timestamp + 15 minutes,
            "SP.onlyFutureTime: NOT FUTURE time"
        );
        _;
    }

    //####################
    //##    设置接口    ##
    //####################

    function setSigDeadline(Page storage p, uint48 deadline)
        public
        onlyFutureTime(deadline)
    {
        p.signatures[0][0].blocknumber = deadline;
    }

    function setClosingDeadline(Page storage p, uint48 deadline)
        public
        onlyFutureTime(deadline)
    {
        p.signatures[0][0].sigDate = deadline;
    }

    function addBlank(
        Page storage p,
        uint40 acct,
        uint16 seq
    ) public returns (bool flag) {
        if (p.signatures[0][0].sigHash != bytes32(0))
            p.signatures[0][0].sigHash = bytes32(0);

        if (!blankExist(p, acct, seq)) {
            p.signatures[acct][seq].signer = acct;

            p.parties.add(acct);

            p.blankCounter++;

            flag = true;
        }
    }

    function removeBlank(
        Page storage p,
        uint40 acct,
        uint16 ssn
    ) public returns (bool flag) {
        if (blankExist(p, acct, ssn) && !dealIsSigned(p, acct, ssn)) {
            delete p.signatures[acct][ssn];
            p.parties.remove(acct);

            p.blankCounter--;

            flag = true;
        }
    }

    function signDeal(
        Page storage p,
        uint40 caller,
        uint16 ssn,
        bytes32 sigHash
    ) public {
        if (blankExist(p, caller, ssn) && !dealIsSigned(p, caller, ssn)) {
            p.signatures[caller][ssn] = Signature({
                signer: caller,
                blocknumber: uint64(block.number),
                sigDate: uint48(block.timestamp),
                sigHash: sigHash
            });

            p.signatures[0][0].signer++;

            if (p.blankCounter == uint16(p.signatures[0][0].signer)) {
                p.signatures[0][0].sigHash = bytes32("true");
            }
        }
    }

    //####################
    //##    查询接口    ##
    //####################

    function blankExist(
        Page storage p,
        uint40 acct,
        uint16 ssn
    ) public view returns (bool) {
        return p.signatures[acct][ssn].signer == acct;
    }

    function dealIsSigned(
        Page storage p,
        uint40 acct,
        uint16 ssn
    ) public view returns (bool) {
        return p.signatures[acct][ssn].sigDate != 0;
    }

    function established(Page storage p) public view returns (bool) {
        return p.signatures[0][0].sigHash == bytes32("true");
    }

    function sigDeadline(Page storage p) public view returns (uint48) {
        return uint48(p.signatures[0][0].blocknumber);
    }

    function closingDeadline(Page storage p) public view returns (uint48) {
        return p.signatures[0][0].sigDate;
    }

    function isParty(Page storage p, uint40 acct) public view returns (bool) {
        return p.parties.contains(acct);
    }

    function isInitSigner(Page storage p, uint40 acct)
        public
        view
        returns (bool)
    {
        return blankExist(p, acct, 0);
    }

    function partiesOfDoc(Page storage p)
        public
        view
        returns (uint40[] memory)
    {
        return p.parties.valuesToUint40();
    }

    function qtyOfParties(Page storage p) public view returns (uint256) {
        return p.parties.length();
    }

    function blankCounterOfDoc(Page storage p) public view returns (uint16) {
        return p.blankCounter;
    }

    function sigCounter(Page storage p) public view returns (uint16) {
        return uint16(p.signatures[0][0].signer);
    }

    function sigOfDeal(
        Page storage p,
        uint40 acct,
        uint16 ssn
    )
        public
        view
        returns (
            uint64 blocknumber,
            uint48 sigDate,
            bytes32 sigHash
        )
    {
        // require(dealIsSigned(p, acct, ssn), "SP.sigDateOfDeal: deal not signed");

        Signature storage sig = p.signatures[acct][ssn];

        blocknumber = sig.blocknumber;
        sigDate = sig.sigDate;
        sigHash = sig.sigHash;
    }

    // function dealSigVerify(
    //     Page storage p,
    //     uint40 acct,
    //     uint16 ssn,
    //     string memory src
    // ) public view returns (bool) {
    //     // require(dealIsSigned(p, acct, ssn), "SP.sigDateOfDeal: deal not signed");
    //     return p.signatures[acct][ssn].sigHash == keccak256(bytes(src));
    // }
}

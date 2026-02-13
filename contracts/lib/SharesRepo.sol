// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "../openzeppelin/utils/structs/EnumerableSet.sol";

/// @title SharesRepo
/// @notice Repository for share classes and share records.
library SharesRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Share header fields.
    struct Head {
        uint16 class; 
        uint32 seqOfShare; 
        uint32 preSeq; 
        uint48 issueDate; 
        uint40 shareholder; 
        uint32 priceOfPaid; 
        uint32 priceOfPar; 
        uint16 votingWeight; 
        uint8 argu;
    }

    /// @notice Share body fields.
    struct Body {
        uint48 payInDeadline; 
        uint64 paid;
        uint64 par; 
        uint64 cleanPaid; 
        uint16 distrWeight;
    }

    /// @notice Full share record.
    struct Share {
        Head head;
        Body body;
    }

    /// @notice Share class with info and share list.
    struct Class{
        Share info;
        EnumerableSet.UintSet seqList;
    }

    /// @notice Repository of classes and shares.
    struct Repo {
        // seqOfClass => Class
        mapping(uint256 => Class) classes;
        // seqOfShare => Share
        mapping(uint => Share) shares;
    }

    //####################
    //##    Modifier    ##
    //####################

    /// @notice Ensure share exists.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    modifier shareExist(
        Repo storage repo,
        uint seqOfShare
    ) {
        require(isShare(repo, seqOfShare),
            "SR.shareExist: not");
        _;
    }

    //#################
    //##    Write    ##
    //#################

    /// @notice Parse share head from bytes32.
    /// @param sn Packed share head.
    function snParser(bytes32 sn) public pure returns(Head memory head)
    {
        uint _sn = uint(sn);
        
        head = Head({
            class: uint16(_sn >> 240),
            seqOfShare: uint32(_sn >> 208),
            preSeq: uint32(_sn >> 176),
            issueDate: uint48(_sn >> 128),
            shareholder: uint40(_sn >> 88),
            priceOfPaid: uint32(_sn >> 56),
            priceOfPar: uint32(_sn >> 24),
            votingWeight: uint16(_sn >> 8),
            argu: uint8(_sn)
        });
    }

    /// @notice Pack share head into bytes32.
    /// @param head Share head.
    function codifyHead(Head memory head) public pure returns (bytes32 sn)
    {
        bytes memory _sn = 
            abi.encodePacked(
                head.class, 
                head.seqOfShare, 
                head.preSeq, 
                head.issueDate, 
                head.shareholder, 
                head.priceOfPaid, 
                head.priceOfPar, 
                head.votingWeight, 
                head.argu
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }

    }

    // ==== issue/regist share ====

    /// @notice Build a share from packed head and body values.
    /// @param sharenumber Packed share head.
    /// @param payInDeadline Pay-in deadline timestamp.
    /// @param paid Paid amount.
    /// @param par Par amount.
    /// @param distrWeight Distribution weight.
    function createShare(
        bytes32 sharenumber, 
        uint payInDeadline, 
        uint paid, 
        uint par,
        uint distrWeight
    ) public pure returns (Share memory share) {

        share.head = snParser(sharenumber);

        share.body = Body({
            payInDeadline: uint48(payInDeadline),
            paid: uint64(paid),
            par: uint64(par),
            cleanPaid: uint64(paid),
            distrWeight: uint16(distrWeight)
        });
    }

    /// @notice Decode premium snapshot to share body.
    /// @param premium Encoded premium value.
    function codifyPremium(uint premium) public pure returns(Body memory body) {
        body = Body({
            payInDeadline: uint48(premium >> 208),
            paid: uint64(premium >> 144),
            par: uint64(premium >> 80),
            cleanPaid: uint64(premium >> 16),
            distrWeight: uint16(premium)
        });
    }

    function _addPremium(
        Repo storage repo,
        uint priceOfPaid,
        uint paid
    ) private {

        if (priceOfPaid > 10000 && paid > 0) {

            uint premium = getPremium(repo);
 
            premium += ((priceOfPaid - 10000) * paid / 10000);

            repo.shares[0].body = codifyPremium(premium);
        }

    }

    /// @notice Add a share and update class equity.
    /// @param repo Storage repo.
    /// @param share Share record.
    function addShare(Repo storage repo, Share memory share)
        public returns(Share memory newShare) 
    {
        newShare = regShare(repo, share);

        _addPremium(repo, newShare.head.priceOfPaid, newShare.body.paid);

        Share storage info = repo.classes[newShare.head.class].info;

        if (info.head.issueDate == 0) {
            info.head = newShare.head;
            info.body.distrWeight = newShare.body.distrWeight;
        }

        increaseEquityOfClass(repo, true, share.head.class, 
            share.body.paid, share.body.par, 0);
    }

    /// @notice Register share in storage.
    /// @param repo Storage repo.
    /// @param share Share record.
    function regShare(Repo storage repo, Share memory share)
        public returns(Share memory)
    {
        require(share.head.class > 0, "SR.regShare: zero class");
        require(share.body.par > 0, "SR.regShare: zero par");
        require(share.body.par >= share.body.paid, "SR.regShare: paid overflow");
        require(share.head.issueDate <= block.timestamp, "SR.regShare: future issueDate");
        require(share.head.issueDate <= share.body.payInDeadline, "SR.regShare: issueDate later than payInDeadline");
        require(share.head.shareholder > 0, "SR.regShare: zero shareholder");
        require(share.head.votingWeight > 0, "SR.regShare: zero votingWeight");

        if (share.head.class > counterOfClasses(repo))
            share.head.class = _increaseCounterOfClasses(repo);

        Class storage class = repo.classes[share.head.class];

        if (!class.seqList.contains(share.head.seqOfShare)) {
            share.head.seqOfShare = _increaseCounterOfShares(repo);
                        
            if (share.head.issueDate == 0)
                share.head.issueDate = uint48(block.timestamp);

            class.seqList.add(share.head.seqOfShare);
            repo.classes[0].seqList.add(share.head.seqOfShare);
        }

        repo.shares[share.head.seqOfShare] = share;

        return share;
    }

    // ==== counters ====

    function _increaseCounterOfShares(
        Repo storage repo
    ) private returns(uint32) {

        Head storage h = repo.shares[0].head;

        do {
            unchecked {
                h.seqOfShare++;                
            }
        } while (isShare(repo, h.seqOfShare) || 
            h.seqOfShare == 0);

        return h.seqOfShare;
    }

    function _increaseCounterOfClasses(Repo storage repo) 
        private returns(uint16)
    {
        repo.shares[0].head.class++;
        return repo.shares[0].head.class;
    }

    // ==== amountChange ====

    /// @notice Increase paid-in capital for a share.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    /// @param amt Paid amount.
    function payInCapital(
        Repo storage repo,
        uint seqOfShare,
        uint amt
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint64 deltaPaid = uint64(amt);

        require(deltaPaid > 0, "SR.payInCap: zero amt");

        require(block.timestamp <= share.body.payInDeadline, 
            "SR.payInCap: missed deadline");

        require(share.body.paid + deltaPaid <= share.body.par, 
            "SR.payInCap: amt overflow");

        share.body.paid += deltaPaid;
        share.body.cleanPaid += deltaPaid;

        _addPremium(repo, share.head.priceOfPaid, share.body.paid);

        increaseEquityOfClass(repo, true, share.head.class, deltaPaid, 0, 0);
    }

    /// @notice Decrease share amounts or delete share.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid delta.
    /// @param par Par delta.
    function subAmtFromShare(
        Repo storage repo,
        uint seqOfShare,
        uint paid, 
        uint par
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];
        Class storage class = repo.classes[share.head.class];

        uint64 deltaPaid = uint64(paid);
        uint64 deltaPar = uint64(par);

        // require(deltaPar > 0, "SR.subAmt: zero par");
        require(share.body.cleanPaid >= deltaPaid, "SR.subAmt: insufficient cleanPaid");

        if (deltaPar == share.body.par) {            
            class.seqList.remove(seqOfShare);
            repo.classes[0].seqList.remove(seqOfShare);
            delete repo.shares[seqOfShare];
        } else {
            share.body.paid -= deltaPaid;
            share.body.par -= deltaPar;
            share.body.cleanPaid -= deltaPaid;

            require(share.body.par >= share.body.paid,
                "SR.subAmt: result paid overflow");
        }
    }

    /// @notice Adjust clean paid amount.
    /// @param repo Storage repo.
    /// @param isIncrease True to increase, false to decrease.
    /// @param seqOfShare Share sequence.
    /// @param paid Delta amount.
    function increaseCleanPaid(
        Repo storage repo,
        bool isIncrease,
        uint seqOfShare,
        uint paid
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint64 deltaClean = uint64(paid);

        require(deltaClean > 0, "SR.incrClean: zero amt");

        if (isIncrease && share.body.cleanPaid + deltaClean <= share.body.paid) 
            share.body.cleanPaid += deltaClean;
        else if(!isIncrease && share.body.cleanPaid >= deltaClean)
            share.body.cleanPaid -= deltaClean;
        else revert("SR.incrClean: clean overflow");
    }

    // ---- EquityOfClass ----

    /// @notice Update equity totals for a class.
    /// @param repo Storage repo.
    /// @param isIncrease True to increase, false to decrease.
    /// @param classOfShare Share class.
    /// @param deltaPaid Paid delta.
    /// @param deltaPar Par delta.
    /// @param deltaCleanPaid Clean paid delta.
    function increaseEquityOfClass(
        Repo storage repo,
        bool isIncrease,
        uint classOfShare,
        uint deltaPaid,
        uint deltaPar,
        uint deltaCleanPaid
    ) public {

        Body storage equity = repo.classes[classOfShare].info.body;

        if (isIncrease) {
            equity.paid += uint64(deltaPaid);
            equity.par += uint64(deltaPar);
            equity.cleanPaid += uint64(deltaCleanPaid);
        } else {
            equity.paid -= uint64(deltaPaid);
            equity.par -= uint64(deltaPar);
            equity.cleanPaid -= uint64(deltaCleanPaid);            
        }
    }

    /// @notice Update paid price for a share.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    /// @param newPrice New price.
    function updatePriceOfPaid(
        Repo storage repo,
        uint seqOfShare,
        uint newPrice
    ) public shareExist(repo, seqOfShare) {
        Share storage share = repo.shares[seqOfShare];
        share.head.priceOfPaid = uint32(newPrice);
    }

    /// @notice Update pay-in deadline for a share.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    /// @param deadline New deadline timestamp.
    function updatePayInDeadline(
        Repo storage repo,
        uint seqOfShare,
        uint deadline
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint48 newLine = uint48(deadline);

        require (block.timestamp < newLine, 
            "SR.updatePayInDeadline: not future");

        share.body.payInDeadline = newLine;
    }

    /// @notice Restore repo from snapshots.
    /// @param repo Storage repo.
    /// @param shares Share list.
    /// @param classInfos Class info list.
    function restoreRepo(
        Repo storage repo, 
        Share[] memory shares,
        Share[] memory classInfos
    ) public {
        uint len = shares.length;
        while (len > 1) {
            Share memory share = shares[len - 1];
            repo.shares[share.head.seqOfShare] = share;

            repo.classes[share.head.class].seqList.add(share.head.seqOfShare);
            repo.classes[0].seqList.add(share.head.seqOfShare);

            len --;
        }

        repo.shares[0] = shares[0];

        len = classInfos.length;
        while (len > 0) {
            Share memory info = classInfos[len - 1];
            repo.classes[info.head.class].info = info;

            len--;
        }
    }

    //####################
    //##    Read I/O    ##
    //####################

    // ---- Counter ----

    /// @notice Get share counter.
    /// @param repo Storage repo.
    function counterOfShares(
        Repo storage repo
    ) public view returns(uint32) {
        return repo.shares[0].head.seqOfShare;
    }

    /// @notice Get class counter.
    /// @param repo Storage repo.
    function counterOfClasses(
        Repo storage repo
    ) public view returns(uint16) {
        return repo.shares[0].head.class;
    }

    // ---- Share ----

    /// @notice Check whether share exists.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    function isShare(
        Repo storage repo, 
        uint seqOfShare
    ) public view returns(bool) {
        return repo.shares[seqOfShare].head.issueDate > 0;
    }

    /// @notice Get share by sequence.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    function getShare(
        Repo storage repo, 
        uint seqOfShare
    ) public view shareExist(repo, seqOfShare) returns (
        Share memory
    ) {
        return repo.shares[seqOfShare];
    }

    /// @notice Get total share count.
    /// @param repo Storage repo.
    function getQtyOfShares(
        Repo storage repo
    ) public view returns(uint) {
        return repo.classes[0].seqList.length();
    }

    /// @notice Get share sequence list.
    /// @param repo Storage repo.
    function getSeqListOfShares(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.classes[0].seqList.values();
    }

    /// @notice Get list of all shares.
    /// @param repo Storage repo.
    function getSharesList(
        Repo storage repo
    ) public view returns(Share[] memory) {
        uint[] memory seqList = repo.classes[0].seqList.values();
        return _getShares(repo, seqList);
    }

    /// @notice Get zero share record.
    /// @param repo Storage repo.
    function getShareZero(Repo storage repo) 
        public view returns(Share memory share) {
            share = repo.shares[0];
    }

    // ---- Class ----    

    /// @notice Get share count in class.
    /// @param repo Storage repo.
    /// @param classOfShare Share class.
    function getQtyOfSharesInClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (uint) {
        return repo.classes[classOfShare].seqList.length();
    }

    /// @notice Get share sequence list in class.
    /// @param repo Storage repo.
    /// @param classOfShare Share class.
    function getSeqListOfClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (uint[] memory) {
        return repo.classes[classOfShare].seqList.values();
    }

    /// @notice Get class info share.
    /// @param repo Storage repo.
    /// @param classOfShare Share class.
    function getInfoOfClass(
        Repo storage repo,
        uint classOfShare
    ) public view returns (Share memory) {
        return repo.classes[classOfShare].info;
    }

    /// @notice Get shares of a class.
    /// @param repo Storage repo.
    /// @param classOfShare Share class.
    function getSharesOfClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (Share[] memory) {
        uint[] memory seqList = 
            repo.classes[classOfShare].seqList.values();
        return _getShares(repo, seqList);
    }

    function _getShares(
        Repo storage repo,
        uint[] memory seqList
    ) private view returns(Share[] memory list) {

        uint len = seqList.length;
        list = new Share[](len);

        while(len > 0) {
            list[len - 1] = repo.shares[seqList[len - 1]];
            len--;
        }
    }

    /// @notice Get encoded premium snapshot.
    /// @param repo Storage repo.
    function getPremium(Repo storage repo) public view returns(uint premium) {
        Body memory body = repo.shares[0].body;

        premium =   (uint(body.payInDeadline) << 208) +
                    (uint(body.paid) << 144) +
                    (uint(body.par) << 80) +
                    (uint(body.cleanPaid) << 16) +
                    body.distrWeight;
    }

}

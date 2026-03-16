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

import "../../openzeppelin/utils/structs/EnumerableSet.sol";
import "./MotionsRepo.sol";
import "./SharesRepo.sol";

import "../../comps/common/components/IMeetingMinutes.sol";
import "../../comps/books/ros/IRegisterOfShares.sol";


/// @title DealsRepo
/// @notice Repository for investment agreements and deal lifecycle.
library DealsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    // _deals[0].head {
    //     seqOfDeal: counterOfClosedDeal;
    //     preSeq: counterOfDeal;
    //     typeOfDeal: typeOfIA;
    // }    

    /// @notice Deal types.
    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        PreEmptive,
        TagAlong,
        DragAlong,
        FirstRefusal,
        FreeGift
    }

    /// @notice Composite IA type based on deal mix.
    enum TypeOfIA {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STint,
        SText_STint,
        CI_SText_STint,
        CI_SText
    }

    /// @notice Deal lifecycle state.
    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }

    /// @notice Deal head fields.
    struct Head {
        uint8 typeOfDeal;
        uint16 seqOfDeal;
        uint16 preSeq;
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 seller;
        uint32 priceOfPaid;
        uint32 priceOfPar;
        uint48 closingDeadline;
        uint16 votingWeight;
    }

    /// @notice Deal body fields.
    struct Body {
        uint40 buyer;
        uint40 groupOfBuyer;
        uint64 paid;
        uint64 par;
        uint8 state;
        uint16 para;
        uint16 distrWeight;
        bool flag;
    }

    /// @notice Full deal record.
    struct Deal {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    /// @notice Repository of deals and swaps.
    struct Repo {
        // seqOfDeal => Deal
        mapping(uint256 => Deal) deals;
        //seqOfDeal => seqOfShare => bool
        mapping(uint => mapping(uint => bool)) priceDiffRequested;
        EnumerableSet.UintSet seqList;
    }

    //##################
    //##    Error     ##
    //##################

    error DealsRepo_WrongState(bytes32 reason);

    error DealsRepo_ZeroValue(bytes32 reason);

    error DealsRepo_Overflow(bytes32 reason);

    error DealsRepo_WrongInput(bytes32 reason);

    error DealsRepo_WrongParty(bytes32 reason);

    //##################
    //##   Modifier   ##
    //##################

    /// @notice Ensure deal is cleared.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    modifier onlyCleared(Repo storage repo, uint256 seqOfDeal) {
        if (
            repo.deals[seqOfDeal].body.state != uint8(StateOfDeal.Cleared)
        ) {
            revert DealsRepo_WrongState(bytes32("DR_DealNotCleared"));
        }
        _;
    }

    /// @notice Ensure deal exists.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    modifier dealExist(Repo storage repo, uint seqOfDeal) {
        if (!isDeal(repo, seqOfDeal)) {
            revert DealsRepo_WrongState(bytes32("DR_NoSuchDeal"));
        }
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    /// @notice Parse deal head from bytes32.
    /// @param sn Packed head bytes32.
    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            typeOfDeal: uint8(_sn >> 248),
            seqOfDeal: uint16(_sn >> 232),
            preSeq: uint16(_sn >> 216),
            classOfShare: uint16(_sn >> 200),
            seqOfShare: uint32(_sn >> 168),
            seller: uint40(_sn >> 128),
            priceOfPaid: uint32(_sn >> 96),
            priceOfPar: uint32(_sn >> 64),
            closingDeadline: uint48(_sn >> 16),
            votingWeight: uint16(_sn) 
        });

    } 

    /// @notice Pack deal head into bytes32.
    /// @param head Deal head.
    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfDeal,
                            head.seqOfDeal,
                            head.preSeq,
                            head.classOfShare,
                            head.seqOfShare,
                            head.seller,
                            head.priceOfPaid,
                            head.priceOfPaid,
                            head.closingDeadline,
                            head.votingWeight);        
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    /// @notice Add a deal from packed head.
    /// @param repo Storage repo.
    /// @param sn Packed head bytes32.
    /// @param buyer Buyer user number.
    /// @param groupOfBuyer Buyer group number.
    /// @param paid Paid amount.
    /// @param par Par amount.
    /// @param distrWeight Distribution weight.
    function addDeal(
        Repo storage repo,
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par,
        uint distrWeight
    ) public returns (uint16 seqOfDeal)  {

        Deal memory deal;

        deal.head = snParser(sn);

        deal.body.buyer = uint40(buyer);
        deal.body.groupOfBuyer = uint40(groupOfBuyer);
        deal.body.paid = uint64(paid);
        deal.body.par = uint64(par);
        deal.body.distrWeight = uint16(distrWeight);

        seqOfDeal = regDeal(repo, deal);
    }

    /// @notice Register a deal in storage.
    /// @param repo Storage repo.
    /// @param deal Deal record.
    function regDeal(Repo storage repo, Deal memory deal) 
        public returns(uint16 seqOfDeal) 
    {
        if (deal.body.par == 0) {
            revert DealsRepo_ZeroValue(bytes32("DR_ZeroPar"));
        }

        if (deal.body.par < deal.body.paid) {
            revert DealsRepo_Overflow(bytes32("DR_PaidExceedsPar"));
        }

        deal.head.seqOfDeal = _increaseCounterOfDeal(repo);
        repo.seqList.add(deal.head.seqOfDeal);

        repo.deals[deal.head.seqOfDeal] = Deal({
            head: deal.head,
            body: deal.body,
            hashLock: bytes32(0)
        });
        seqOfDeal = deal.head.seqOfDeal;
    }

    function _increaseCounterOfDeal(Repo storage repo) private returns(uint16 seqOfDeal){
        repo.deals[0].head.preSeq++;
        seqOfDeal = repo.deals[0].head.preSeq;
    }

    /// @notice Delete a deal by sequence.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    function delDeal(Repo storage repo, uint256 seqOfDeal) public returns (bool flag) {
        if (repo.seqList.remove(seqOfDeal)) {
            delete repo.deals[seqOfDeal];
            repo.deals[0].head.preSeq--;
            flag = true;
        }
    }

    /// @notice Lock a deal subject.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    function lockDealSubject(Repo storage repo, uint256 seqOfDeal) public returns (bool flag) {
        if (repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Drafting)) {
            repo.deals[seqOfDeal].body.state = uint8(StateOfDeal.Locked);
            flag = true;
        }
    }

    /// @notice Release a deal subject back to drafting.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    function releaseDealSubject(Repo storage repo, uint256 seqOfDeal) public returns (bool flag)
    {
        uint8 state = repo.deals[seqOfDeal].body.state;

        if ( state < uint8(StateOfDeal.Closed) ) {

            repo.deals[seqOfDeal].body.state = uint8(StateOfDeal.Drafting);
            flag = true;

        } else if (state == uint8(StateOfDeal.Terminated)) {

            flag = true;            
        }
    }

    /// @notice Clear a deal with hash lock and deadline.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    /// @param hashLock Hash lock key.
    /// @param closingDeadline Closing deadline timestamp.
    function clearDealCP(
        Repo storage repo,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline
    ) public {
        Deal storage deal = repo.deals[seqOfDeal];

        if (deal.body.state != uint8(StateOfDeal.Locked)) {
            revert DealsRepo_WrongState(bytes32("DR_DealNotLocked"));
        }

        deal.body.state = uint8(StateOfDeal.Cleared);
        deal.hashLock = hashLock;

        if (closingDeadline > 0) {
            if (block.timestamp < closingDeadline) 
                deal.head.closingDeadline = uint48(closingDeadline);
            else revert DealsRepo_WrongState(bytes32("DR_DeadlineNotFuture"));
        }
    }

    /// @notice Close a deal using hash preimage.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    /// @param hashKey Preimage string.
    function closeDeal(Repo storage repo, uint256 seqOfDeal, string memory hashKey)
        public onlyCleared(repo, seqOfDeal) returns (bool flag)
    {
        if (repo.deals[seqOfDeal].hashLock != keccak256(bytes(hashKey))) {
            revert DealsRepo_WrongInput(bytes32("DR_HashKeyNotCorrect"));
        }

        return _closeDeal(repo, seqOfDeal);
    }

    /// @notice Close a locked deal directly.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    function directCloseDeal(Repo storage repo, uint seqOfDeal) 
        public returns (bool flag) 
    {
        if (repo.deals[seqOfDeal].body.state != uint8(StateOfDeal.Locked)) {
            revert DealsRepo_WrongState(bytes32("DR_DealNotLocked"));
        }
        
        return _closeDeal(repo, seqOfDeal);
    }

    function _closeDeal(Repo storage repo, uint seqOfDeal)
        private returns(bool flag) 
    {
    
        Deal storage deal = repo.deals[seqOfDeal];

        if (block.timestamp >= deal.head.closingDeadline) {
            revert DealsRepo_WrongState(bytes32("DR_MissedDeadline"));
        }

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);

        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    /// @notice Terminate a locked/cleared deal.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    function terminateDeal(Repo storage repo, uint256 seqOfDeal) public returns(bool flag){
        Body storage body = repo.deals[seqOfDeal].body;

        if (body.state != uint8(StateOfDeal.Locked) && body.state != uint8(StateOfDeal.Cleared)) {
            revert DealsRepo_WrongState(bytes32("DR_DealNotLockedOrCleared"));
        }

        body.state = uint8(StateOfDeal.Terminated);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    /// @notice Accept a free gift deal.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    function takeGift(Repo storage repo, uint256 seqOfDeal)
        public returns (bool flag)
    {
        Deal storage deal = repo.deals[seqOfDeal];

        if (deal.head.typeOfDeal != uint8(TypeOfDeal.FreeGift)) {
            revert DealsRepo_WrongState(bytes32("DR_NotGiftDeal"));
        }

        if (repo.deals[deal.head.preSeq].body.state != uint8(StateOfDeal.Closed)) {
            revert DealsRepo_WrongState(bytes32("DR_CapitalIncreaseNotClosed"));
        }

        if (deal.body.state != uint8(StateOfDeal.Locked)) {
            revert DealsRepo_WrongState(bytes32("DR_DealNotLocked"));
        }

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function _increaseCounterOfClosedDeal(Repo storage repo) private {
        repo.deals[0].head.seqOfDeal++;
    }

    /// @notice Calculate composite IA type.
    /// @param repo Storage repo.
    function calTypeOfIA(Repo storage repo) public {
        uint[3] memory types;

        uint[] memory seqList = repo.seqList.values();
        uint len = seqList.length;
        
        while (len > 0) {
            uint typeOfDeal = repo.deals[seqList[len-1]].head.typeOfDeal;
            len--;

            if (typeOfDeal == 1) {
                if (types[0] == 0) types[0] = 1;
                continue;
            } else if (typeOfDeal == 2) {
                if (types[1] == 0) types[1] = 2;
                continue;
            } else if (typeOfDeal == 3) {
                if (types[2] == 0) types[2] = 3;
                continue;
            }
        }

        uint8 sum = uint8(types[0] + types[1] + types[2]);
        repo.deals[0].head.typeOfDeal = (sum == 3)
                ? (types[2] == 0)
                    ? 7
                    : 3
                : sum;
    }

    /// @notice Close an approved deal by buyer payment.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    /// @param caller Buyer user number.
    function payOffApprovedDeal(
        Repo storage repo,
        uint seqOfDeal,
        uint caller
    ) public returns (bool flag){

        Deal storage deal = repo.deals[seqOfDeal];

        if (deal.head.typeOfDeal == uint8(TypeOfDeal.FreeGift)) {
            revert DealsRepo_WrongState(bytes32("DR_FreeGift"));
        }

        if (caller != deal.body.buyer) {
            revert DealsRepo_WrongParty(bytes32("DR_NotBuyer"));
        }

        if (deal.body.state != uint8(StateOfDeal.Locked) &&
            deal.body.state != uint8(StateOfDeal.Cleared)) {
            revert DealsRepo_WrongState(bytes32("DR_DealNotLockedOrCleared"));
        }

        if (block.timestamp >= deal.head.closingDeadline) {
            revert DealsRepo_WrongState(bytes32("DR_MissedClosingDeadline"));
        }

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);

        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    /// @notice Request price difference for a share.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfShare Share sequence.
    function requestPriceDiff(
        Repo storage repo,
        uint seqOfDeal,
        uint seqOfShare
    ) public dealExist(repo, seqOfDeal) {
        if (repo.priceDiffRequested[seqOfDeal][seqOfShare]) {
            revert DealsRepo_WrongState(bytes32("DR_RedundantRequests"));
        }
        repo.priceDiffRequested[seqOfDeal][seqOfShare] = true;      
    }

    //  ##########################
    //  ##       Read I/O       ##
    //  ##########################

    /// @notice Get composite IA type.
    /// @notice Get composite IA type.
    /// @param repo Storage repo.
    function getTypeOfIA(Repo storage repo) external view returns (uint8) {
        return repo.deals[0].head.typeOfDeal;
    }

    /// @notice Get deal counter.
    /// @notice Get deal counter.
    /// @param repo Storage repo.
    function counterOfDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.preSeq;
    }

    /// @notice Get closed deal counter.
    /// @notice Get closed deal counter.
    /// @param repo Storage repo.
    function counterOfClosedDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.seqOfDeal;
    }

    /// @notice Check whether a deal exists.
    /// @notice Check whether a deal exists.
    /// @param repo Storage repo.
    /// @param seqOfDeal Deal sequence.
    function isDeal(Repo storage repo, uint256 seqOfDeal) public view returns (bool) {
        return repo.seqList.contains(seqOfDeal);
    }
    
    /// @notice Get deal by sequence.
    /// @notice Get deal by sequence.
    /// @param repo Storage repo.
    /// @param seq Deal sequence.
    function getDeal(Repo storage repo, uint256 seq) 
        external view dealExist(repo, seq) returns (Deal memory)
    {
        return repo.deals[seq];
    }

    /// @notice Get deal sequence list.
    /// @notice Get deal sequence list.
    /// @param repo Storage repo.
    function getSeqList(Repo storage repo) external view returns (uint[] memory) {
        return repo.seqList.values();
    } 
}

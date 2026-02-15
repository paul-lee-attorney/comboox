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

/// @title PledgesRepo
/// @notice Repository for share pledge records and lifecycle.
library PledgesRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Pledge lifecycle state.
    enum StateOfPld {
        Pending,
        Issued,
        Locked,
        Released,
        Executed,
        Revoked
    }

    /// @notice Pledge header fields.
    struct Head {
        uint32 seqOfShare;
        uint16 seqOfPld;
        uint48 createDate;
        uint16 daysToMaturity;
        uint16 guaranteeDays;
        uint40 creditor;
        uint40 debtor;
        uint40 pledgor;
        uint8 state;
    }

    /// @notice Pledge body fields.
    struct Body {
        uint64 paid;
        uint64 par;
        uint64 guaranteedAmt;
        uint16 preSeq;
        uint16 execDays;
        uint16 para;
        uint16 argu;
    }

    /// @notice Full pledge record.
    struct Pledge {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    /// @notice Repository of pledges by share and sequence.
    struct Repo{
        // seqOfShare => seqOfPld => Pledge
        mapping(uint256 => mapping(uint256 => Pledge)) pledges;
        EnumerableSet.Bytes32Set snList;
    }

    //################
    //##   Error    ##
    //################

    error PLDR_WrongInput(bytes32 reason);

    error PLDR_WrongState(bytes32 reason);

    error PLDR_Overflow(bytes32 reason);

    error PLDR_WrongParty(bytes32 reason);

    //##################
    //##  Write I/O  ##
    //##################

    /// @notice Parse pledge head from bytes32.
    /// @param sn Packed pledge head.
    function snParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        
        head = Head({
            seqOfShare: uint32(_sn >> 224),
            seqOfPld: uint16(_sn >> 208),
            createDate: uint48(_sn >> 160),
            daysToMaturity: uint16(_sn >> 144),
            guaranteeDays: uint16(_sn >> 128),
            creditor: uint40(_sn >> 88),
            debtor: uint40(_sn >> 48),
            pledgor: uint40(_sn >> 8),
            state: uint8(_sn)
        });
    } 

    /// @notice Pack pledge head into bytes32.
    /// @param head Pledge head.
    function codifyHead(Head memory head) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.seqOfShare,
                            head.seqOfPld,
                            head.createDate,
                            head.daysToMaturity,
                            head.guaranteeDays,
                            head.creditor,
                            head.pledgor,
                            head.debtor,
                            head.state);        
        assembly {
            sn := mload(add(_sn, 0x20))
        }

    } 

        /// @notice Create and issue a pledge from packed head.
        /// @param repo Storage repo.
        /// @param snOfPld Packed pledge head.
        /// @param paid Paid amount.
        /// @param par Par amount.
        /// @param guaranteedAmt Guaranteed amount.
        /// @param execDays Execution days.
        function createPledge(
            Repo storage repo, 
            bytes32 snOfPld, 
            uint paid,
            uint par,
            uint guaranteedAmt,
            uint execDays
    ) public returns (Head memory head) 
    {
        head = snParser(snOfPld);
        head = issuePledge(repo, head, paid, par, guaranteedAmt, execDays);
    }

    /// @notice Issue a pledge with provided head/body.
    /// @param repo Storage repo.
    /// @param head Pledge head.
    /// @param paid Paid amount.
    /// @param par Par amount.
    /// @param guaranteedAmt Guaranteed amount.
    /// @param execDays Execution days.
    function issuePledge(
        Repo storage repo,
        Head memory head,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) public returns(Head memory regHead) {

        if (guaranteedAmt == 0) revert PLDR_WrongInput("PLDR_ZeroGuaranteedAmt");
        if (par == 0) revert PLDR_WrongInput("PLDR_ZeroPar");
        if (par < paid) revert PLDR_WrongInput("PLDR_PaidExceedsPar");

        Pledge memory pld;

        pld.head = head;

        pld.head.createDate = uint48(block.timestamp);
        pld.head.state = uint8(StateOfPld.Issued);

        pld.body = Body({
            paid: uint64(paid),
            par: uint64(par),
            guaranteedAmt: uint64(guaranteedAmt),
            preSeq:0,
            execDays: uint16(execDays),
            para:0,
            argu:0
        });

        regHead = regPledge(repo, pld);
    }

    /// @notice Register pledge into storage.
    /// @param repo Storage repo.
    /// @param pld Pledge record.
    function regPledge(
        Repo storage repo,
        Pledge memory pld
    ) public returns(Head memory){

        if (pld.head.seqOfShare == 0) 
            revert PLDR_WrongInput("PLDR_ZeroSeqOfShare");
    
        pld.head.seqOfPld = _increaseCounterOfPld(repo, pld.head.seqOfShare);

        repo.pledges[pld.head.seqOfShare][pld.head.seqOfPld] = pld;
        repo.snList.add(codifyHead(pld.head));

        return pld.head;
    }

    // ==== Update Pledge ====

    /// @notice Split a pledge and optionally transfer to buyer.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param buyer Buyer user number.
    /// @param amt Split amount.
    /// @param caller Caller user number.
    function splitPledge(
        Repo storage repo,
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint caller
    ) public returns(Pledge memory newPld) {

        Pledge storage pld = repo.pledges[seqOfShare][seqOfPld];

        if (caller != pld.head.creditor) 
            revert PLDR_WrongParty("PLDR_NotCreditor");

        if (isExpired(pld)) 
            revert PLDR_WrongState("PLDR_PledgeExpired");

        if (pld.head.state != uint8(StateOfPld.Issued) &&
            pld.head.state != uint8(StateOfPld.Locked)
        ) {
            revert PLDR_WrongState("PLDR_PldNotIssuedOrLocked");
        }
        
        if (amt == 0) revert PLDR_WrongInput("PLDR_ZeroAmt");

        newPld = pld;

        if (amt < pld.body.guaranteedAmt) {
            // uint64 ratio = uint64(amt) * 10000 / newPld.body.guaranteedAmt;

            newPld.body.paid = uint64(pld.body.paid * amt / newPld.body.guaranteedAmt);
            newPld.body.par = uint64(pld.body.par * amt / newPld.body.guaranteedAmt);
            newPld.body.guaranteedAmt = uint64(amt);

            pld.body.paid -= newPld.body.paid;
            pld.body.par -= newPld.body.par;
            pld.body.guaranteedAmt -= newPld.body.guaranteedAmt;

        } else if (amt == pld.body.guaranteedAmt) {

            pld.head.state = uint8(StateOfPld.Released);

        } else revert("PR.splitPld: amt overflow");

        if (buyer > 0) {
            newPld.body.preSeq = pld.head.seqOfPld;

            newPld.head.creditor = uint40(buyer);
            newPld.head = regPledge(repo, newPld);
        }
    }

    /// @notice Extend guarantee days.
    /// @param pld Pledge record.
    /// @param extDays Extra days.
    /// @param caller Caller user number.
    function extendPledge(
        Pledge storage pld,
        uint extDays,
        uint caller
    ) public {
        if (caller != pld.head.pledgor) 
            revert PLDR_WrongParty("PLDR_NotPledgor");

        if (pld.head.state != uint8(StateOfPld.Issued) &&
            pld.head.state != uint8(StateOfPld.Locked)) 
            revert PLDR_WrongState("PLDR_PldNotIssuedOrLocked");

        if (isExpired(pld)) 
            revert PLDR_WrongState("PLDR_PldExpired");

        pld.head.guaranteeDays += uint16(extDays);
    }

    // ==== Lock & Release ====

    /// @notice Lock pledge with hash lock.
    /// @param pld Pledge record.
    /// @param hashLock Hash lock key.
    /// @param caller Caller user number.
    function lockPledge(
        Pledge storage pld,
        bytes32 hashLock,
        uint caller
    ) public {
        if (caller != pld.head.creditor) 
            revert PLDR_WrongParty("PLDR_NotCreditor");

        if (isExpired(pld)) 
            revert PLDR_WrongState("PLDR_PldExpired");

        if (hashLock == bytes32(0)) 
            revert PLDR_WrongInput("PLDR_ZeroHashLock");

        if (pld.head.state == uint8(StateOfPld.Issued)){
            pld.head.state = uint8(StateOfPld.Locked);
            pld.hashLock = hashLock;
        } else revert PLDR_WrongState("PLDR_PldNotIssued");
    }

    /// @notice Release pledge with hash key.
    /// @param pld Pledge record.
    /// @param hashKey Preimage string.
    function releasePledge(
        Pledge storage pld,
        string memory hashKey
    ) public {
        if (pld.head.state != uint8(StateOfPld.Locked)) 
            revert PLDR_WrongState("PLDR_PldNotLocked");

        if (pld.hashLock == keccak256(bytes(hashKey))) {
            pld.head.state = uint8(StateOfPld.Released);
        } else revert PLDR_WrongInput("PLDR_WrongKey");
    }

    /// @notice Execute a triggered pledge.
    /// @param pld Pledge record.
    /// @param caller Caller user number.
    function execPledge(Pledge storage pld, uint caller) public {

        if (caller != pld.head.creditor) 
            revert PLDR_WrongParty("PLDR_NotCreditor");

        if (!isTriggerd(pld)) 
            revert PLDR_WrongState("PLDR_PldNotTriggered");

        if (isExpired(pld)) 
            revert PLDR_WrongState("PLDR_PldExpired");

        if (pld.head.state == uint8(StateOfPld.Issued) ||
            pld.head.state == uint8(StateOfPld.Locked))
        {
            pld.head.state = uint8(StateOfPld.Executed);
        } else revert PLDR_WrongState("PLDR_PldNotIssuedOrLocked");
    }

    /// @notice Revoke an expired pledge.
    /// @param pld Pledge record.
    /// @param caller Caller user number.
    function revokePledge(Pledge storage pld, uint caller) public {
        if (caller != pld.head.pledgor) 
            revert PLDR_WrongParty("PLDR_NotPledgor");

        if (!isExpired(pld)) 
            revert PLDR_WrongState("PLDR_PldNotExpired");

        if (pld.head.state == uint8(StateOfPld.Issued) || 
            pld.head.state == uint8(StateOfPld.Locked)) 
        {
            pld.head.state = uint8(StateOfPld.Revoked);
        } else revert PLDR_WrongState("PLDR_PldNotIssuedOrLocked");
    }

    // ==== Counter ====

    function _increaseCounterOfPld(Repo storage repo, uint256 seqOfShare) 
        private returns (uint16 seqOfPld) 
    {
        repo.pledges[seqOfShare][0].head.seqOfPld++;
        seqOfPld = repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    //#################
    //##    Read     ##
    //#################

    /// @notice Check if pledge is triggered by maturity.
    /// @param pld Pledge record.
    function isTriggerd(Pledge storage pld) public view returns(bool) {
        uint64 triggerDate = pld.head.createDate + uint48(pld.head.daysToMaturity) * 86400;
        return block.timestamp >= triggerDate;
    }

    /// @notice Check if pledge is expired after guarantee days.
    /// @param pld Pledge record.
    function isExpired(Pledge storage pld) public view returns(bool) {
        uint64 expireDate = pld.head.createDate + uint48(pld.head.daysToMaturity + pld.head.guaranteeDays) * 86400;
        return block.timestamp >= expireDate;
    }

    /// @notice Get pledge counter for share.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    function counterOfPld(Repo storage repo, uint256 seqOfShare) 
        public view returns (uint16) 
    {
        return repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    /// @notice Check if pledge exists.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPledge Pledge sequence.
    function isPledge(Repo storage repo, uint seqOfShare, uint seqOfPledge) 
        public view returns (bool)
    {
        return repo.pledges[seqOfShare][seqOfPledge].head.createDate > 0;
    }

    /// @notice Get list of pledge head hashes.
    /// @param repo Storage repo.
    function getSNList(Repo storage repo) public view returns (bytes32[] memory list)
    {
        list = repo.snList.values();
    }

    /// @notice Get pledge by share and sequence.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    function getPledge(Repo storage repo, uint256 seqOfShare, uint seqOfPld) 
        public view returns (Pledge memory)
    {
        return repo.pledges[seqOfShare][seqOfPld];
    } 

    /// @notice Get all pledges for a share.
    /// @param repo Storage repo.
    /// @param seqOfShare Share sequence.
    function getPledgesOfShare(Repo storage repo, uint256 seqOfShare) 
        public view returns (Pledge[] memory) 
    {
        uint256 len = counterOfPld(repo, seqOfShare);

        Pledge[] memory output = new Pledge[](len);

        while (len > 0) {
            output[len - 1] = repo.pledges[seqOfShare][len];
            len--;
        }

        return output;
    }

    /// @notice Get all pledges across shares.
    /// @param repo Storage repo.
    function getAllPledges(Repo storage repo) 
        public view returns (Pledge[] memory)
    {
        bytes32[] memory snList = getSNList(repo);
        uint len = snList.length;
        Pledge[] memory ls = new Pledge[](len);

        while( len > 0 ) {
            Head memory head = snParser(snList[len - 1]);
            ls[len - 1] = repo.pledges[head.seqOfShare][head.seqOfPld];
            len--;
        }

        return ls;
    }
}

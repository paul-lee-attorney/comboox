// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library PledgesRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum StateOfPld {
        Pending,
        Issued,
        Locked,
        Released,
        Executed,
        Revoked
    }

    struct Head {
        uint32 seqOfShare;
        uint16 seqOfPld;
        uint48 createDate;
        uint48 triggerDate;
        uint40 pledgor;
        uint40 debtor;
        uint32 data;
    }

    struct Body {
        uint40 creditor; //质权人、债权人
        uint16 guaranteeDays;
        uint64 paid;
        uint64 par;
        uint64 guaranteedAmt;
        uint8 state;
    }

    //Pledge 质权
    struct Pledge {
        Head head; //质押编号
        Body body;
        bytes32 hashLock;
    }

    struct Repo{
        // seqOfShare => seqOfPld => Pledge
        mapping(uint256 => mapping(uint256 => Pledge)) pledges;
        EnumerableSet.Bytes32Set snList;
    }

    //##################
    //##    写接口    ##
    //##################

    function snParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        
        head = Head({
            seqOfShare: uint32(_sn >> 224),
            seqOfPld: uint16(_sn >> 208),
            createDate: uint48(_sn >> 160),
            triggerDate: uint48(_sn >> 112),
            pledgor: uint40(_sn >> 72),
            debtor: uint40(_sn >> 32),
            data: uint32(_sn)
        });
    } 

    function codifyHead(Head memory head) public pure returns (bytes32 sn) {
        // sn = uint256(head.seqOfShare) << 224 +
        //     uint256(head.seqOfPld) << 208 + 
        //     uint256(head.createDate) << 160 +
        //     uint256(head.triggerDate) << 112 +
        //     uint256(head.pledgor) << 72 +
        //     uint256(head.debtor) << 32 +
        //     head.data;

        bytes memory _sn = abi.encodePacked(
                            head.seqOfShare,
                            head.seqOfPld,
                            head.createDate,
                            head.triggerDate,
                            head.pledgor,
                            head.debtor,
                            head.data);        
        assembly {
            sn := mload(add(_sn, 0x20))
        }

    } 

    function createPledge(
            Repo storage repo, 
            bytes32 snOfPld, 
            uint creditor,
            uint guaranteeDays, 
            uint paid,
            uint par,
            uint guaranteedAmt
    ) public returns (Head memory head) 
    {
        head = snParser(snOfPld);
        head = issuePledge(repo, head, creditor, guaranteeDays, paid, par, guaranteedAmt);
    }

    function issuePledge(
        Repo storage repo,
        Head memory head,
        uint creditor,
        uint guaranteeDays,
        uint paid,
        uint par,
        uint guaranteedAmt
    ) public returns(Head memory regHead) {
        Pledge memory pld;

        head.createDate = uint48(block.timestamp);

        pld.head = head;

        pld.body = Body({
            creditor: uint40(creditor),
            guaranteeDays: uint16(guaranteeDays),
            paid: uint64(paid),
            par: uint64(par),
            guaranteedAmt: uint64(guaranteedAmt),
            state: uint8(StateOfPld.Issued)
        });

        regHead = regPledge(repo, pld);
    }

    function regPledge(
        Repo storage repo,
        Pledge memory pld
    ) public returns(Head memory){

        uint64 expireDate = pld.head.triggerDate + uint48(pld.body.guaranteeDays) * 86400;

        require(block.timestamp < expireDate, "PR.DAOP: pledge expired");
        require(pld.body.state < uint8(StateOfPld.Locked), "PR.DAOP: wrong state");
    
        pld.head.seqOfPld = _increaseCounterOfPld(repo, pld.head.seqOfShare);

        repo.pledges[pld.head.seqOfShare][pld.head.seqOfPld] = pld;
        repo.snList.add(codifyHead(pld.head));

        return pld.head;
    }

    // ==== Update Pledge ====

    function splitPledge(
        Repo storage repo,
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt
    ) public returns(Pledge memory newPld) {

        Pledge storage pld = repo.pledges[seqOfShare][seqOfPld];

        uint64 expireDate = pld.head.triggerDate + uint48(pld.body.guaranteeDays) * 86400;

        require(block.timestamp < expireDate, "PR.SP: pledge expired");
        require(pld.body.state < uint8(StateOfPld.Released), "PR.SP: wrong state");
        require(amt <= pld.body.guaranteedAmt, "PR.SP: insufficient guaranteedAmt");
        require(amt > 0, "PR.SP: zero amt");

        newPld = pld;

        uint64 ratio = uint64(amt) * 10000 / newPld.body.guaranteedAmt;

        newPld.body.paid = newPld.body.paid * ratio / 10000;
        newPld.body.par = newPld.body.par * ratio / 10000;
        newPld.body.guaranteedAmt = uint64(amt);

        if (buyer > 0) {
            newPld.body.creditor = uint40(buyer);
            newPld.head = regPledge(repo, newPld);
        }

        if (amt == pld.body.guaranteedAmt) {        
            pld.body.paid = 0;
            pld.body.par = 0;
            pld.body.guaranteedAmt = 0;
            pld.body.state = uint8(StateOfPld.Revoked);
        } else if (amt < pld.body.guaranteedAmt){
            pld.body.paid -= newPld.body.paid;
            pld.body.par -= newPld.body.par;
            pld.body.guaranteedAmt -= newPld.body.guaranteedAmt;
        }
    }

    function extendPledge(
        Pledge storage pld,
        uint extDays
    ) public {
        require(pld.body.state < uint8(StateOfPld.Released), "PR.EP: wrong state");
        require(block.timestamp < pld.head.triggerDate + uint48(pld.body.guaranteeDays) * 86400, 
            "PR.UP: pledge expired");
        pld.body.guaranteeDays += uint16(extDays);
    }

    // ==== Lock & Release ====

    function lockPledge(
        Pledge storage pld,
        bytes32 hashLock
    ) public returns (bool flag){
        require (block.timestamp < pld.head.triggerDate + uint48(pld.body.guaranteeDays) * 86400, 
            "PR.RP: pledge expired");
        require (hashLock != bytes32(0), "PR.LP: zero hashLock");

        if (pld.body.state == uint8(StateOfPld.Issued)){
            pld.body.state = uint8(StateOfPld.Locked);
            pld.hashLock = hashLock;
            flag = true;
        }
    }

    function releasePledge(
        Pledge storage pld,
        string memory hashKey
    ) public returns (bool flag){
        require (pld.body.state == uint8(StateOfPld.Locked), "PR.RP: wrong state");
        if (pld.hashLock == keccak256(bytes(hashKey))) {
            pld.body.state = uint8(StateOfPld.Released);
            flag = true;
        }
    }

    function execPledge(Pledge storage pld) public returns(bool flag)
    {
        require(block.timestamp >= pld.head.triggerDate,"PR.EP: pledge not triggered");
        require(block.timestamp < pld.head.triggerDate + uint48(pld.body.guaranteeDays) * 86400,
            "PR.EP: pledge expired");

        if (pld.body.state == uint8(StateOfPld.Issued) ||
            pld.body.state == uint8(StateOfPld.Locked))
        {
            pld.body.state = uint8(StateOfPld.Executed);
            flag = true;
        }        
    }

    function revokePledge(Pledge storage pld) public returns(bool flag) {
        require(block.timestamp > pld.head.triggerDate + uint48(pld.body.guaranteeDays) * 86400,
            "PR.EP: pledge not expired");

        if (pld.body.state == uint8(StateOfPld.Issued) || 
            pld.body.state == uint8(StateOfPld.Locked)) 
        {
            pld.body.state = uint8(StateOfPld.Revoked);
            flag = true;
        }
    }

    // ==== Counter ====

    function _increaseCounterOfPld(Repo storage repo, uint256 seqOfShare) 
        private returns (uint16 seqOfPld) 
    {
        repo.pledges[seqOfShare][0].head.seqOfPld++;
        seqOfPld = repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    //#################
    //##    读接口    ##
    //#################

    function counterOfPld(Repo storage repo, uint256 seqOfShare) 
        public view 
        returns (uint16) 
    {
        return repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    function getSNList(Repo storage repo) public view returns (bytes32[] memory list)
    {
        list = repo.snList.values();
    }

    function getPledge(Repo storage repo, uint256 seqOfShare, uint seqOfPld) 
        public view returns (Pledge memory)
    {
        return repo.pledges[seqOfShare][seqOfPld];
    } 

    function getPledgesOfShare(Repo storage repo, uint256 seqOfShare) 
        public view returns (Pledge[] memory) 
    {
        uint256 len = counterOfPld(repo, seqOfShare);

        require(len > 0, "BOP.POS: no pledges found");

        Pledge[] memory output = new Pledge[](len);

        while (len > 0) {
            output[len - 1] = repo.pledges[seqOfShare][len];
            len--;
        }

        return output;
    }
}

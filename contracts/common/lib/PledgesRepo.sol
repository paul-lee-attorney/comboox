// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library PledgesRepo {

    struct Head {
        uint32 seqOfShare;
        uint32 seqOfPledge;
        uint48 createDate;
        uint48 expireDate;
        uint40 pledgor;
        uint40 debtor;
    }

    struct Body {
        uint40 creditor; //质权人、债权人
        uint64 pledgedPaid;
        uint64 pledgedPar; 
        uint64 guaranteedAmt;         
    }

    //Pledge 质权
    struct Pledge {
        Head head; //质押编号
        Body body;
    }

    struct Repo{
        // seqOfShare => seqOfPledge => Pledge
        mapping(uint256 => mapping(uint256 => Pledge)) pledges;
    }

    //##################
    //##    写接口    ##
    //##################

    function snParser(bytes32 sn) public pure returns (Head memory head) {
        head = Head({
            seqOfShare: uint32(bytes4(sn)),
            seqOfPledge: uint16(bytes2(sn<<32)),
            createDate: uint48(bytes6(sn<<48)),
            expireDate: uint48(bytes6(sn<<96)),
            pledgor: uint40(bytes5(sn<<144)),
            debtor: uint40(bytes5(sn<<184))
        });
    } 

    function createPledge(
        Repo storage repo,
        Head memory head,
        uint256 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) public returns(Head memory) {
        Pledge memory pld;

        head.createDate = uint48(block.timestamp);
        head.expireDate = uint48(block.timestamp) +
            monOfGuarantee * 2592000;

        pld.head = head;

        pld.body = Body({
            creditor: uint40(creditor),
            pledgedPaid: pledgedPaid,
            pledgedPar: pledgedPar,
            guaranteedAmt: guaranteedAmt
        });

        regPledge(repo, pld);

        return pld.head;
    }

    function regPledge(
        Repo storage repo,
        Pledge memory pld
    ) public returns(Head memory){
        _increaseCounterOfPledges(repo, pld.head.seqOfShare);
        pld.head.seqOfPledge = counterOfPledges(repo, pld.head.seqOfShare);

        repo.pledges[pld.head.seqOfShare][pld.head.seqOfPledge] = pld;

        return pld.head;
    }

    function updatePledge(
        Pledge storage pld,
        uint256 creditor,
        uint48 expireDate,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) public {
        pld.head.expireDate = expireDate;

        pld.body = Body({
            creditor : uint40(creditor),
            pledgedPaid: pledgedPaid,
            pledgedPar : pledgedPar,
            guaranteedAmt : guaranteedAmt
        });
    }

    //##################
    //##    读接口    ##
    //##################

    function _increaseCounterOfPledges(Repo storage repo, uint256 seqOfShare) private {
        repo.pledges[seqOfShare][0].head.seqOfPledge++;
    }

    function counterOfPledges(Repo storage repo, uint256 seqOfShare) 
        public view 
        returns (uint32) 
    {
        return repo.pledges[seqOfShare][0].head.seqOfPledge;
    }

    function pledgesOfShare(Repo storage repo, uint256 seqOfShare) 
        public view 
        returns (Pledge[] memory) 
    {
        uint256 len = counterOfPledges(repo, seqOfShare);

        require(len > 0, "BOP.POS: no pledges found");

        Pledge[] memory output = new Pledge[](len);

        while (len > 0) {
            output[len - 1] = repo.pledges[seqOfShare][len];
            len--;
        }

        return output;
    }
}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";

import "../../common/access/AccessControl.sol";

import "./IBookOfPledges.sol";

contract BookOfPledges is IBookOfPledges, AccessControl {
    using SNFactory for bytes;
    using SNParser for bytes32;

    //Pledge 质权
    struct Pledge {
        bytes32 sn; //质押编号
        uint40 creditor; //质权人、债权人
        uint64 expireBN;
        uint64 pledgedPar; // 出质票面额（数量）
        uint64 guaranteedAmt; //担保金额
    }

    // struct snInfo {
    //     uint32 ssnOfShare; 4
    //     uint16 sequence; 2
    //     uint48 createDate; 6
    //     uint40 pledgor; 5
    //     uint40 debtor; 5
    // }

    // _pledges[ssn][0].creditor : counterOfPledge

    // ssn => seq => Pledge
    mapping(uint256 => mapping(uint256 => Pledge)) private _pledges;

    //##################
    //##   Modifier   ##
    //##################

    modifier pledgeExist(bytes32 sn) {
        require(isPledge(sn), "BOP.pledgeExist: pledge NOT exist");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        bytes32 sn,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDK {
        uint32 ssn = sn.ssnOfPld();
        uint16 seq = _increaseCounterOfPledges(ssn);

        sn = _updateSN(sn, seq);

        uint64 expireBN = uint64(block.number) +
            monOfGuarantee *
            720 *
            _rc.blocksPerHour();

        _pledges[ssn][seq] = Pledge({
            sn: sn,
            creditor: creditor,
            expireBN: expireBN,
            pledgedPar: pledgedPar,
            guaranteedAmt: guaranteedAmt
        });

        emit CreatePledge(
            sn,
            creditor,
            monOfGuarantee,
            pledgedPar,
            guaranteedAmt
        );
    }

    function _updateSN(bytes32 sn, uint16 seq) private view returns (bytes32) {
        bytes memory _sn = abi.encodePacked(sn);

        _sn = _sn.seqToSN(4, seq);
        _sn = _sn.dateToSN(6, uint48(block.timestamp));

        return _sn.bytesToBytes32();
    }

    function _increaseCounterOfPledges(uint32 ssn) private returns (uint16) {
        _pledges[ssn][0].creditor++;
        return uint16(_pledges[ssn][0].creditor);
    }

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint64 expireBN,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDK pledgeExist(sn) {
        require(
            expireBN > block.number || expireBN == 0,
            "BOP.updatePledge: expireBN is passed"
        );

        Pledge storage pld = _pledges[sn.ssnOfPld()][sn.seqOfPld()];

        pld.creditor = creditor;
        pld.expireBN = expireBN;
        pld.pledgedPar = pledgedPar;
        pld.guaranteedAmt = guaranteedAmt;

        emit UpdatePledge(sn, creditor, expireBN, pledgedPar, guaranteedAmt);
    }

    //##################
    //##    读接口    ##
    //##################

    function pledgesOf(uint32 ssn) external view returns (bytes32[] memory) {
        uint16 seq = uint16(_pledges[ssn][0].creditor);

        require(seq > 0, "BOP.pledgesOf: no pledges found");

        bytes32[] memory output = new bytes32[](seq);

        while (seq > 0) {
            output[seq - 1] = _pledges[ssn][seq].sn;
            seq--;
        }

        return output;
    }

    function counterOfPledges(uint32 ssn) external view returns (uint16) {
        return uint16(_pledges[ssn][0].creditor);
    }

    function isPledge(bytes32 sn) public view returns (bool) {
        uint32 ssn = sn.ssnOfPld();
        uint32 seq = sn.seqOfPld();

        return _pledges[ssn][seq].sn == sn;
    }

    function getPledge(bytes32 sn)
        external
        view
        pledgeExist(sn)
        returns (
            uint40 creditor,
            uint64 expireBN,
            uint64 pledgedPar,
            uint64 guaranteedAmt
        )
    {
        Pledge storage pld = _pledges[sn.ssnOfPld()][sn.seqOfPld()];

        creditor = pld.creditor;
        expireBN = pld.expireBN;
        pledgedPar = pld.pledgedPar;
        guaranteedAmt = pld.guaranteedAmt;
    }
}

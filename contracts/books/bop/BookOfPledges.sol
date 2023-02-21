// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfPledges.sol";

import "../../common/access/AccessControl.sol";

import "../../common/lib/SNFactory.sol";
import "../../common/lib/SNParser.sol";

contract BookOfPledges is IBookOfPledges, AccessControl {
    using SNFactory for bytes;
    using SNParser for bytes32;

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
    ) external onlyDirectKeeper {
        uint32 ssn = sn.ssnOfPld();
        uint16 seq = _increaseCounterOfPledges(ssn);

        sn = _updateSN(sn, seq);

        uint48 expireDate = uint48(block.timestamp) +
            monOfGuarantee * 2592000;

        _pledges[ssn][seq] = Pledge({
            sn: sn,
            creditor: creditor,
            expireDate: expireDate,
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
        uint48 expireDate,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external onlyDirectKeeper pledgeExist(sn) {
        require(
            expireDate > block.timestamp || expireDate == 0,
            "BOP.updatePledge: expireDate is passed"
        );

        Pledge storage pld = _pledges[sn.ssnOfPld()][sn.seqOfPld()];

        pld.creditor = creditor;
        pld.expireDate = expireDate;
        pld.pledgedPar = pledgedPar;
        pld.guaranteedAmt = guaranteedAmt;

        emit UpdatePledge(sn, creditor, expireDate, pledgedPar, guaranteedAmt);
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
            Pledge memory pld
        )
    {
        pld = _pledges[sn.ssnOfPld()][sn.seqOfPld()];
    }
}

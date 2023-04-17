// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library CondsRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum LogOps {
        ZeroPoint,
        And,
        Or,
        AndOr,
        OrAnd,
        Equal,
        NotEqual,
        AndAndAnd,
        OrOrOr,
        AndOrOr,
        OrAndOr,
        OrOrAnd,
        AndAndOr,
        AndOrAnd,
        OrAndAnd,
        EqualEqual,
        EqualNe,
        NeEqual,
        NeNe
    }

    enum ComOps {
        ZeroPoint,
        Equal,
        NotEqual,
        Bigger,
        Smaller,
        BiggerOrEqual,
        SmallerOrEqual
    }

    struct Cond {
        uint32 seqOfCond;
        uint8 logicOpr;    
        uint8 compOpr1;    
        uint64 para1;           
        uint8 compOpr2;    
        uint64 para2;           
        uint8 compOpr3;    
        uint64 para3;                               
    }

    struct Repo {
        mapping(uint256 => Cond) conds;
        EnumerableSet.Bytes32Set snList;
    }

    // ###############
    // ##   写接口   ##
    // ###############

    // ==== codify / parser ====

    function snParser(bytes32 sn) public pure returns(Cond memory cond)
    {
        uint _sn = uint(sn);

        cond = Cond({
            seqOfCond: uint32(_sn >> 224),
            logicOpr: uint8(_sn >> 216),
            compOpr1: uint8(_sn >> 208),    
            para1: uint64(_sn >> 144),          
            compOpr2: uint8(_sn >> 136),    
            para2: uint64(_sn >> 72),           
            compOpr3: uint8(_sn >> 64),    
            para3: uint64(_sn)                               
        });
    }

    function codifyCond(Cond memory cond) public pure returns(bytes32 sn)
    {
        bytes memory _sn = abi.encodePacked(
                            cond.seqOfCond,
                            cond.logicOpr,
                            cond.compOpr1,
                            cond.para1,
                            cond.compOpr2,
                            cond.para2,
                            cond.compOpr3,
                            cond.para3);

        assembly {
            sn := mload(add(_sn, 0x20))
        }                
    }

    // ==== create / reg ====
    function createCond(Repo storage repo, bytes32 sn) public returns(uint32 seqOfCond)
    {
        seqOfCond = regCond(repo, snParser(sn));
    }

    function regCond(Repo storage repo, Cond memory cond) public returns(uint32 seqOfCond)
    {
        cond.seqOfCond = _increaseCounterOfConds(repo);
        repo.conds[cond.seqOfCond] = cond;
        repo.snList.add(codifyCond(cond));
        seqOfCond = cond.seqOfCond;
    }

    function _increaseCounterOfConds(Repo storage repo) private returns(uint32 seqOfCond)
    {
        repo.conds[0].seqOfCond++;
        seqOfCond = repo.conds[0].seqOfCond;
    }

    function removeCond(Repo storage repo, uint256 seqOfCond) public returns(bool flag)
    {
        if (repo.snList.remove(codifyCond(repo.conds[seqOfCond])))
        {
            delete repo.conds[seqOfCond];
            flag = true;
        }
    }
    
    // ##################
    // ##   Read I/O   ##
    // ##################

    function counterOfConds(Repo storage repo) public view returns(uint32 seqOfCond) {
        seqOfCond = repo.conds[0].seqOfCond;
    }

    function getConds(Repo storage repo) public view returns(Cond[] memory)
    {
        uint256 len = repo.snList.length();
        Cond[] memory output = new Cond[](len);

        while (len > 0) {
            output[len -1] = repo.conds[len];
            len--;
        }

        return output;
    }

    function checkCond(
        uint compOpr,
        uint para,
        uint data
    ) public pure returns (bool flag) {
        if (compOpr == uint8(ComOps.Equal)) flag = data == para;
        else if (compOpr == uint8(ComOps.NotEqual)) flag = data != para;
        else if (compOpr == uint8(ComOps.Bigger)) flag = data > para;
        else if (compOpr == uint8(ComOps.Smaller)) flag = data < para;
        else if (compOpr == uint8(ComOps.BiggerOrEqual)) flag = data >= para;
        else if (compOpr == uint8(ComOps.SmallerOrEqual)) flag = data <= para;
        else revert ("CR.CSC: compOpr overflow");
    }

    function checkSoleCond(
        Cond memory cond,
        uint data
    ) public pure returns (bool flag) {
        flag = checkCond(cond.compOpr1, cond.para1, data);
    }

    function checkCondsOfTwo(
        Cond memory cond,
        uint data1,
        uint data2
    ) public pure returns (bool flag) {
        bool flag1;
        bool flag2;

        flag1 = checkCond(cond.compOpr1, cond.para1, data1);
        flag2 = checkCond(cond.compOpr2, cond.para2, data2);

        if (cond.logicOpr == uint8(LogOps.And)) flag = flag1 && flag2;
        else if (cond.logicOpr == uint8(LogOps.Or)) flag = flag1 || flag2;
        else if (cond.logicOpr == uint8(LogOps.AndOr)) flag = flag1;
        else if (cond.logicOpr == uint8(LogOps.OrAnd)) flag = flag2;
        else if (cond.logicOpr == uint8(LogOps.Equal)) flag = flag1 == flag2;
        else if (cond.logicOpr == uint8(LogOps.NotEqual)) flag = flag1 != flag2;
        else revert("CR.CCO2: logicOpr overflow");
    }

    function checkCondsOfThree(
        Cond memory cond,
        uint data1,
        uint data2,
        uint data3
    ) public pure returns (bool flag) {
        bool flag1;
        bool flag2;
        bool flag3;

        flag1 = checkCond(cond.compOpr1, cond.para1, data1);
        flag2 = checkCond(cond.compOpr2, cond.para2, data2);
        flag3 = checkCond(cond.compOpr3, cond.para3, data3);

        if (cond.logicOpr == uint8(LogOps.AndAndAnd)) flag = flag1 && flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.OrOrOr)) flag = flag1 || flag2 || flag3;
        else if (cond.logicOpr == uint8(LogOps.AndOrOr)) flag = flag1;
        else if (cond.logicOpr == uint8(LogOps.OrAndOr)) flag = flag2;
        else if (cond.logicOpr == uint8(LogOps.OrOrAnd)) flag = flag3;
        else if (cond.logicOpr == uint8(LogOps.AndAndOr)) flag = flag1 && flag2;
        else if (cond.logicOpr == uint8(LogOps.AndOrAnd)) flag = flag1 && flag3;
        else if (cond.logicOpr == uint8(LogOps.OrAndAnd)) flag = flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.EqualEqual)) flag = flag1 == flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.EqualNe)) flag = flag1 == flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.EqualNe)) flag = flag1 != flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.NeNe)) flag = flag1 != flag2 != flag3;
        else revert("CR.CCO3: logicOpr overflow");
    }
}

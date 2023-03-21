// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library CondsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

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
        uint32 seq;
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
        EnumerableSet.UintSet snList;
    }

    // ###############
    // ##   写接口   ##
    // ###############

    // ==== codify / parser ====

    function snParser(uint256 sn) public pure returns(Cond memory cond)
    {
        cond = Cond({
            seq: uint32(sn >> 224),
            logicOpr: uint8(sn >> 216),
            compOpr1: uint8(sn >> 208),
            para1: uint64(sn >> 144),
            compOpr2: uint8(sn >> 136),
            para2: uint64(sn >> 72),
            compOpr3: uint8(sn >> 64),
            para3: uint64(sn)
        });
    }

    function codifyCond(Cond memory cond) public pure returns(uint256 sn)
    {
        sn = (uint256(cond.seq) << 224) +
            (uint256(cond.logicOpr) << 216) +
            (uint256(cond.compOpr1) << 208) +
            (uint256(cond.para1) << 144) +
            (uint256(cond.compOpr2) << 136) +
            (uint256(cond.para2) << 72) +
            (uint256(cond.compOpr3) << 64) +
            (uint256(cond.para3));
    }

    // ==== create / reg ====
    function createCond(Repo storage repo, uint256 sn) public returns(uint32 seq)
    {
        seq = regCond(repo, snParser(sn));
    }

    function regCond(Repo storage repo, Cond memory cond) public returns(uint32 seq)
    {
        cond.seq = _increaseCounterOfConds(repo);
        repo.conds[cond.seq] = cond;
        repo.snList.add(codifyCond(cond));
        seq = cond.seq;
    }

    function _increaseCounterOfConds(Repo storage repo) private returns(uint32 seq)
    {
        repo.conds[0].seq++;
        seq = repo.conds[0].seq;
    }

    function removeCond(Repo storage repo, uint256 seq) public returns(bool flag)
    {
        if (repo.snList.remove(codifyCond(repo.conds[seq])))
        {
            delete repo.conds[seq];
            flag = true;
        }
    }
    
    // ##################
    // ##   Read I/O   ##
    // ##################

    function counterOfConds(Repo storage repo) public view returns(uint32 seq) {
        seq = repo.conds[0].seq;
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
        uint8 compOpr,
        uint64 para,
        uint64 data
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
        uint64 data
    ) public pure returns (bool flag) {
        flag = checkCond(cond.compOpr1, cond.para1, data);
    }

    function checkCondsOfTwo(
        Cond memory cond,
        uint64 data1,
        uint64 data2
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
        uint64 data1,
        uint64 data2,
        uint64 data3
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

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

/// @title CondsRepo
/// @notice Library for condition encoding and evaluation.
library CondsRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Logical operator codes.
    enum LogOps {
        ZeroPoint,  // 0
        And,           
        Or,         
        Equal,
        NotEqual,   // 4
        AndAnd,  
        OrOr,
        AndOr,
        OrAnd,
        EqEq,
        NeNe,
        EqNe,
        NeEq,
        AndEq,
        EqAnd,
        OrEq,
        EqOr,
        AndNe,
        NeAnd,
        OrNe,
        NeOr        
    }

    /// @notice Comparison operator codes.
    enum ComOps {
        ZeroPoint,
        Equal,
        NotEqual,
        Bigger,
        Smaller,
        BiggerOrEqual,
        SmallerOrEqual
    }

    /// @notice Encoded condition.
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

    /// @notice Repository of conditions.
    struct Repo {
        mapping(uint256 => Cond) conds;
        EnumerableSet.Bytes32Set seqList;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    // ==== codify / parser ====

    /// @notice Parse encoded condition.
    /// @param sn Encoded condition bytes32.
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

    /// @notice Encode condition into bytes32.
    /// @param cond Condition struct.
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
    /// @notice Create and register a condition.
    /// @param repo Storage repo.
    /// @param sn Encoded condition bytes32.
    function createCond(Repo storage repo, bytes32 sn) public returns(uint32 seqOfCond)
    {
        seqOfCond = regCond(repo, snParser(sn));
    }

    /// @notice Register a condition struct.
    /// @param repo Storage repo.
    /// @param cond Condition struct.
    function regCond(Repo storage repo, Cond memory cond) public returns(uint32 seqOfCond)
    {
        cond.seqOfCond = _increaseCounterOfConds(repo);
        repo.conds[cond.seqOfCond] = cond;
        repo.seqList.add(codifyCond(cond));
        seqOfCond = cond.seqOfCond;
    }

    /// @dev Increase condition counter.
    function _increaseCounterOfConds(Repo storage repo) private returns(uint32)
    {
        repo.conds[0].seqOfCond++;
        return repo.conds[0].seqOfCond;
    }

    /// @notice Remove a condition by sequence number.
    /// @param repo Storage repo.
    /// @param seqOfCond Condition sequence number (> 0).
    function removeCond(Repo storage repo, uint256 seqOfCond) public returns(bool flag)
    {
        if (repo.seqList.remove(codifyCond(repo.conds[seqOfCond])))
        {
            delete repo.conds[seqOfCond];
            flag = true;
        }
    }
    
    // ##################
    // ##   Write I/O  ##
    // ##################

    /// @notice Get number of conditions.
    /// @param repo Storage repo.
    function counterOfConds(Repo storage repo) public view returns(uint32 seqOfCond) {
        seqOfCond = repo.conds[0].seqOfCond;
    }

    /// @notice Get all conditions.
    /// @param repo Storage repo.
    function getConds(Repo storage repo) public view returns(Cond[] memory)
    {
        uint256 len = repo.seqList.length();
        Cond[] memory output = new Cond[](len);

        while (len > 0) {
            output[len -1] = repo.conds[len];
            len--;
        }

        return output;
    }

    /// @notice Evaluate a comparison.
    /// @param compOpr Comparison operator (see ComOps).
    /// @param para Comparison parameter.
    /// @param data Data to compare.
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

    /// @notice Evaluate a single condition.
    function checkSoleCond(
        Cond memory cond,
        uint data
    ) public pure returns (bool flag) {
        flag = checkCond(cond.compOpr1, cond.para1, data);
    }

    /// @notice Evaluate a condition with two inputs.
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
        else if (cond.logicOpr == uint8(LogOps.Equal)) flag = flag1 == flag2;
        else if (cond.logicOpr == uint8(LogOps.NotEqual)) flag = flag1 != flag2;
        else revert("CR.CCO2: logicOpr overflow");
    }

    /// @notice Evaluate a condition with three inputs.
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

        if (cond.logicOpr == uint8(LogOps.AndAnd)) flag = flag1 && flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.OrOr)) flag = flag1 || flag2 || flag3;
        else if (cond.logicOpr == uint8(LogOps.AndOr)) flag = flag1 && flag2 || flag3;
        else if (cond.logicOpr == uint8(LogOps.OrAnd)) flag = flag1 || flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.EqEq)) flag = flag1 == flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.NeNe)) flag = flag1 != flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.EqNe)) flag = flag1 == flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.NeEq)) flag = flag1 != flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.AndEq)) flag = flag1 && flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.EqAnd)) flag = flag1 == flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.OrEq)) flag = flag1 || flag2 == flag3;
        else if (cond.logicOpr == uint8(LogOps.EqOr)) flag = flag1 == flag2 || flag3;
        else if (cond.logicOpr == uint8(LogOps.AndNe)) flag = flag1 && flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.NeAnd)) flag = flag1 != flag2 && flag3;
        else if (cond.logicOpr == uint8(LogOps.OrNe)) flag = flag1 || flag2 != flag3;
        else if (cond.logicOpr == uint8(LogOps.NeOr)) flag = flag1 != flag2 || flag3;
        else revert("CR.CCO3: logicOpr overflow");
    }
}

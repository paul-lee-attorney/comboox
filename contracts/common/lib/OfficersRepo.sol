// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library OfficersRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    enum TitleOfOfficers {
        ZeroPoint,
        Chairman,
        ViceChairman,
        ManagingDirector,
        Director,
        CEO,
        CFO,
        COO,
        CTO,
        President,
        VicePresident,
        Supervisor,
        SeniorManager,
        Manager,
        ViceManager      
    }

    struct Position {
        uint16 title;
        uint16 seqOfPos;
        uint40 acct;
        uint40 nominator;
        uint48 startDate;
        uint48 endDate;
        uint16 seqOfVR;
        uint16 para;
        uint16 argu;
    }

    struct Repo {
        // seqOfPos => Position
        mapping(uint256 => Position)  positions;
        EnumerableSet.Bytes32Set snList; // snOfPos List

        // acct => seqOfPos
        mapping(uint256 => EnumerableSet.UintSet) posInHand;
        EnumerableSet.UintSet officers; // acct List

        EnumerableSet.UintSet board;
    }

    //#################
    //##   Modifier  ##
    //#################

    modifier isVacant(Repo storage repo, uint256 seqOfPos) {
        require(!isOccupied(repo, seqOfPos), 
            "OR.mf.IV: position occupied");
        _;
    }

    //#################
    //##    Write    ##
    //#################

    // ==== snParser ====

    function snParser(bytes32 sn) public pure returns (Position memory position) {
        uint _sn = uint(sn);

        position = Position({
            title: uint16(_sn >> 240),
            seqOfPos: uint16(_sn >> 224),
            acct: uint40(_sn >> 184),
            nominator: uint40(_sn >> 144),
            startDate: uint48(_sn >> 96),
            endDate: uint48(_sn >> 48),
            seqOfVR: uint16(_sn >> 32),
            para: uint16(_sn >> 16),
            argu: uint16(_sn)
        });
    }

    function codifyPosition(Position memory position) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encode(
                            position.title,
                            position.seqOfPos,
                            position.acct,
                            position.nominator,
                            position.startDate,
                            position.endDate,
                            position.seqOfVR,
                            position.para,
                            position.argu);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }                
    }

    // ======== Setting ========

    function createPosition (Repo storage repo, bytes32 snOfPos) 
        public 
    {
        Position memory pos = snParser(snOfPos);
        addPosition(repo, pos);
    }

    function addPosition(
        Repo storage repo,
        Position memory pos
    ) public {
        require (pos.title > 0, "OR.RP: zero title");
        require (pos.seqOfPos > 0, "OR.RP: zero seqOfPositions");
        require (pos.nominator > 0, "OR.RP: zero nominator");
        require (pos.endDate > pos.startDate, "OR.RP: endDate too small");
        require (pos.endDate > uint48(block.timestamp), "OR.RP: endDate not future");

        Position storage p = repo.positions[pos.seqOfPos];
        
        require (p.title == 0 || p.title == pos.title,
            "OR.AP: remove pos for change title");

        repo.positions[pos.seqOfPos] = pos;
        repo.snList.add(codifyPosition(pos));
    }

    function removePosition(Repo storage repo, uint256 seqOfPos) 
        public isVacant(repo, seqOfPos) returns (bool flag)
    {
        Position memory pos = repo.positions[seqOfPos];

        if (repo.snList.remove(codifyPosition(pos))) {
            delete repo.positions[seqOfPos];
            flag = true;
        }
    }

    function takePosition (
        Repo storage repo,
        uint256 seqOfPos,
        uint acct
    ) public returns (bytes32 ) {
        require (seqOfPos > 0, "OR.TP: zero seqOfPos");
        require (acct > 0, "OR.TP: zero acct");
        
        Position storage pos = repo.positions[seqOfPos];

        pos.acct = uint40(acct);
        pos.startDate = uint48(block.timestamp);

        repo.officers.add(acct);
        repo.posInHand[pos.acct].add(pos.seqOfPos);

        if (pos.title <= uint8(TitleOfOfficers.Director)) {
            repo.board.add(acct);
        }

        return codifyPosition(pos);
    }

    function quitPosition(
        Repo storage repo, 
        uint256 seqOfPos,
        uint acct
    ) public returns (bool flag)
    {
        Position memory pos = repo.positions[seqOfPos];

        require(acct == pos.acct, 
            "OR.QP: not the officer");

        flag = vacatePosition(repo, seqOfPos);
    }

    function vacatePosition (
        Repo storage repo,
        uint seqOfPos
    ) public returns (bool flag)
    {
        Position storage pos = repo.positions[seqOfPos];

        uint acct = pos.acct;
        require (acct > 0, "OR.vacatePosition: empty pos");

        if (repo.posInHand[acct].remove(seqOfPos)) {
            pos.acct = 0;

            if (repo.posInHand[acct].length() == 0) 
                repo.officers.remove(acct);

            if (pos.title <= uint8(TitleOfOfficers.Director))
                repo.board.remove(acct);

            flag = true;
        }        
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Positions ====

    function posExist(Repo storage repo, uint256 seqOfPos) public view returns (bool flag) {
        flag = repo.positions[seqOfPos].endDate > block.timestamp;
    } 

    function isOccupied(Repo storage repo, uint256 seqOfPos) public view returns (bool flag) {
        flag = repo.positions[seqOfPos].acct > 0;
    }

    function getPosList(Repo storage repo) public view returns(bytes32[] memory list) {
        list = repo.snList.values();
    }

    function getPosition(Repo storage repo, uint256 seqOfPos) public view returns (Position memory pos) {
        pos = repo.positions[seqOfPos];
    }

    function getFullPosInfo(Repo storage repo) public view returns(Position[] memory) {
        bytes32[] memory pl = repo.snList.values();
        uint256 len = pl.length;
        Position[] memory ls = new Position[](len);

        while (len > 0) {
            Position memory pos = snParser(pl[len-1]);

            ls[len-1] = repo.positions[pos.seqOfPos];
            len--;
        }

        return ls;
    }

    // ==== Officers ====

    function isOfficer(Repo storage repo, uint256 acct) public view returns (bool flag) {
        flag = repo.officers.contains(acct);
    }

    function hasPosition(Repo storage repo, uint256 acct, uint256 seqOfPos) public view returns (bool flag) {
        flag = repo.posInHand[acct].contains(seqOfPos);
    }

    function getPosInHand(Repo storage repo, uint256 acct) public view returns (uint256[] memory ls) {
        ls = repo.posInHand[acct].values();
    }

    function getOfficer(Repo storage repo, uint256 acct)
        public view returns(Position[] memory output)
    {
        if (isOfficer(repo, acct)) {
            uint256[] memory ls = repo.posInHand[acct].values();
            uint256 len = ls.length;
            output = new Position[](len);

            while(len > 0) {
                output[len - 1] = repo.positions[ls[len - 1]];
                len--;
            }
        }
    }

    function getOffList(Repo storage repo) public view returns (uint256[] memory ls) {
        ls = repo.officers.values();
    }

    function getNumOfOfficers(Repo storage repo) public view returns (uint256 num) {
        num = repo.officers.length();
    }

    // ==== Director ====

    function isDirector(Repo storage repo, uint256 acct) 
        public view returns (bool flag) 
    {
        flag = repo.board.contains(acct);
    }

    function getNumOfDirectors(Repo storage repo) public view 
        returns (uint256 num) 
    {
        num = repo.board.length();
    }

    function getDirectorsList(Repo storage repo) public view 
        returns (uint256[] memory ls) 
    {
        ls = repo.board.values();
    }

    // ==== seatsCalcuator ====

    function getBoardSeatsQuota(Repo storage repo, uint256 acct) public view 
        returns (uint256 quota)
    {
        bytes32[] memory pl = repo.snList.values();
        uint256 len = pl.length;
        while (len > 0) {
            Position memory pos = snParser(pl[len-1]);
            if (pos.title <= uint8(TitleOfOfficers.Director) &&
                pos.nominator == acct) 
            {
                quota++;
            }
            len--;
        }       
    }

    function getBoardSeatsOccupied(Repo storage repo, uint acct) public view 
        returns (uint256 num)
    {
        uint256[] memory dl = repo.board.values();
        uint256 lenOfDL = dl.length;

        while (lenOfDL > 0) {
            uint256[] memory pl = repo.posInHand[dl[lenOfDL-1]].values();
            uint256 lenOfPL = pl.length;

            while(lenOfPL > 0) {
                Position memory pos = repo.positions[pl[lenOfPL-1]];
                if ( pos.title <= uint8(TitleOfOfficers.Director)) { 
                    if (pos.nominator == acct) num++;
                    break;
                }
                lenOfPL--;
            }

            lenOfDL--;
        }
    }
}

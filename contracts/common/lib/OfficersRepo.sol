// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./RulesParser.sol";

library OfficersRepo {
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
        uint16 arg;
    }

    struct Repo {
        // seqOfPos => Position
        mapping(uint256 => Position)  positions;
        EnumerableSet.UintSet posList; // seqOfPosList

        // acct => seqOfPos
        mapping(uint256 => EnumerableSet.UintSet) posInHand;
        EnumerableSet.UintSet officers; // acctList

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

    function snParser(uint256 sn) public pure returns (Position memory position) {
        position = Position({
            title: uint16(sn >> 240),
            seqOfPos: uint16(sn >> 224),
            acct: uint40(sn >> 184),
            nominator: uint40(sn >> 144),
            startDate: uint48(sn >> 96),
            endDate: uint48(sn >> 48),
            seqOfVR: uint16(sn >> 32),
            para: uint16(sn >> 16),
            arg: uint16(sn)
        });
    }

    function codifyPosition(Position memory position) public pure returns (uint256 sn) {
        sn = (uint256(position.title) << 240) +
            (uint256(position.seqOfPos) << 224) +
            (uint256(position.acct) << 184) +
            (uint256(position.nominator) << 144) +
            (uint256(position.startDate) << 96) +
            (uint256(position.endDate) << 48) +
            (uint256(position.seqOfVR) << 32) +
            (uint256(position.para) << 16) +
            position.arg;
    }

    // ======== Setting ========

    function createPosition (Repo storage repo, uint256 snOfPos) 
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
        repo.posList.add(pos.seqOfPos);
    }

    function removePosition(Repo storage repo, uint256 seqOfPos) 
        public isVacant(repo, seqOfPos) returns (bool flag)
    {
        if (repo.posList.remove(seqOfPos)) {
            delete repo.positions[seqOfPos];
            flag = true;
        }
    }

    function takePosition (
        Repo storage repo,
        uint256 seqOfPos,
        uint40 acct
    ) public returns (uint256 ) {
        require (seqOfPos > 0, "OR.TP: zero seqOfPos");
        require (acct > 0, "OR.TP: zero acct");
        
        Position storage pos = repo.positions[seqOfPos];

        pos.acct = acct;
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
        uint40 acct
    ) public returns (bool flag)
    {
        Position memory pos = repo.positions[seqOfPos];

        if (repo.posInHand[acct].remove(seqOfPos)) {
            repo.positions[seqOfPos].acct = 0;

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
        flag = repo.posList.contains(seqOfPos);
    } 

    function isOccupied(Repo storage repo, uint256 seqOfPos) public view returns (bool flag) {
        flag = repo.positions[seqOfPos].acct > 0;
    }

    function getPosList(Repo storage repo) public view returns(uint256[] memory list) {
        list = repo.posList.values();
    }

    function getPosition(Repo storage repo, uint256 seqOfPos) public view returns (Position memory pos) {
        pos = repo.positions[seqOfPos];
    }

    function getFullPosInfo(Repo storage repo) public view returns(Position[] memory) {
        uint256[] memory pl = repo.posList.values();
        uint256 len = pl.length;
        Position[] memory ls = new Position[](len);

        while (len > 0) {
            ls[len-1] = repo.positions[pl[len-1]];
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
        uint256[] memory pl = repo.posList.values();
        uint256 len = pl.length;
        while (len > 0) {
            Position memory pos = repo.positions[pl[len-1]];
            if (pos.title <= uint8(TitleOfOfficers.Director) &&
                pos.nominator == acct) 
            {
                quota++;
            }
            len--;
        }       
    }

    function getBoardSeatsOccupied(Repo storage repo, uint40 acct) public view 
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

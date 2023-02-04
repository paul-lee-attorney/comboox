// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfDirectors.sol";

import "../../common/components/MeetingMinutes.sol";

import "../../common/lib/EnumerableSet.sol";

contract BookOfDirectors is IBookOfDirectors, MeetingMinutes {
    using EnumerableSet for EnumerableSet.UintSet;

    enum TitleOfDirectors {
        ZeroPoint,
        Chairman,
        ViceChairman,
        Director
    }

    struct Director {
        uint8 title; // 1-Chairman; 2-ViceChairman; 3-Director;
        uint40 acct;
        uint40 appointer;
        uint64 startBN;
        uint64 endBN;
    }

    /*
    _dirctors[0] {
        title: maxQtyOfDirectors;
        acct: ViceChair;
        appointer: Chairman;
        startBN: (pending);
        endBN: (pending);
    }
*/

    // userNo => Director
    mapping(uint256 => Director) private _directors;

    EnumerableSet.UintSet private _board;

    //####################
    //##    modifier    ##
    //####################

    modifier directorExist(uint40 acct) {
        require(isDirector(acct), "BOD.directorExist: not a director");
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    // ======== Directors ========

    function setMaxQtyOfDirectors(uint8 max)
        external
        onlyKeeper(uint8(TitleOfKeepers.BOHKeeper))
    {
        _directors[0].title = max;
        emit SetMaxQtyOfDirectors(max);
    }

    function appointDirector(
        uint40 candidate,
        uint8 title,
        uint40 appointer
    ) external onlyDK {
        _addDirector(candidate, title, appointer);
    }

    function _addDirector(
        uint40 candidate,
        uint8 title,
        uint40 appointer
    ) private {
        if (!isDirector(candidate))
            require(
                qtyOfDirectors() < maxQtyOfDirectors(),
                "BOD.addDirector: number of directors overflow"
            );

        uint64 startBN = uint64(block.number);

        uint64 endBN = startBN +
            _getSHA().tenureOfBoard() *
            8760 *
            _rc.blocksPerHour();

        _directors[candidate] = Director({
            title: title,
            acct: candidate,
            appointer: appointer,
            startBN: startBN,
            endBN: endBN
        });

        if (title == uint8(TitleOfDirectors.Chairman)) {
            if (_directors[0].appointer == 0)
                _directors[0].appointer = candidate;
            else revert("BOD.addDirector: Chairman's position is occupied");
        } else if (title == uint8(TitleOfDirectors.ViceChairman)) {
            if (_directors[0].acct == 0) _directors[0].acct = candidate;
            else revert("BOD.addDirector: ViceChairman's position is occupied");
        }

        if (_board.add(candidate))
            emit AddDirector(title, candidate, appointer, startBN, endBN);
    }

    function takePosition(uint40 candidate, uint40 nominator) external onlyDK {
        _addDirector(candidate, uint8(TitleOfDirectors.Director), nominator);
    }

    function removeDirector(uint40 acct) external onlyDK {
        if (isDirector(acct)) {
            if (_directors[acct].title == uint8(TitleOfDirectors.Chairman)) {
                _directors[0].appointer = 0;
            } else if (
                _directors[acct].title == uint8(TitleOfDirectors.ViceChairman)
            ) {
                _directors[0].acct = 0;
            }

            delete _directors[acct];

            _board.remove(acct);

            emit RemoveDirector(acct);
        }
    }

    //##################
    //##    读接口    ##
    //##################

    function maxQtyOfDirectors() public view returns (uint8) {
        return _directors[0].title;
    }

    function qtyOfDirectors() public view returns (uint256) {
        return _board.length();
    }

    function appointmentCounter(uint40 appointer)
        external
        view
        returns (uint8 qty)
    {
        uint40[] memory list = _board.valuesToUint40();
        uint256 len = list.length;

        while (len != 0) {
            if (_directors[len - 1].appointer == appointer) qty++;
            len--;
        }
    }

    function isDirector(uint40 acct) public view returns (bool flag) {
        return _board.contains(acct);
    }

    function inTenure(uint40 acct)
        external
        view
        directorExist(acct)
        returns (bool)
    {
        return (_directors[acct].endBN >= block.number &&
            _directors[acct].startBN <= block.number);
    }

    function whoIs(uint8 title) external view returns (uint40) {
        if (title == uint8(TitleOfDirectors.Chairman))
            return _directors[0].appointer;
        else if (title == uint8(TitleOfDirectors.ViceChairman))
            return _directors[0].acct;
        else revert("BOD.whoIs: value of title overflow");
    }

    function titleOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint8)
    {
        return _directors[acct].title;
    }

    function appointerOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint40)
    {
        return _directors[acct].appointer;
    }

    function startBNOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint64)
    {
        return _directors[acct].startBN;
    }

    function endBNOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint64)
    {
        return _directors[acct].endBN;
    }

    function directors() external view returns (uint40[] memory) {
        return _board.valuesToUint40();
    }
}

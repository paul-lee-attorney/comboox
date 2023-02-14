// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfDirectors.sol";

import "../../common/components/MeetingMinutes.sol";

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/SNParser.sol";

contract BookOfDirectors is IBookOfDirectors, MeetingMinutes {
    using EnumerableSet for EnumerableSet.UintSet;
    using SNParser for bytes32;

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
        uint48 startDate;
        uint48 endDate;
    }

    /*
    _dirctors[0] {
        title: maxQtyOfDirectors;
        acct: ViceChair;
        appointer: Chairman;
        startDate: (pending);
        endDate: (pending);
    }
*/

    // userNo => Director
    mapping(uint256 => Director) private _directors;

    EnumerableSet.UintSet private _board;

    // userNo => numOfDirectors
    mapping(uint256 => uint256) private _appointmentCounter;

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
        onlyKeeper
    {
        _directors[0].title = max;
        emit SetMaxQtyOfDirectors(max);
    }

    function appointDirector(
        bytes32 rule,
        uint40 candidate,
        uint8 title,
        uint40 appointer
    ) external onlyDirectKeeper {
        _addDirector(rule, candidate, title, appointer);
    }

    function _addDirector(
        bytes32 rule,
        uint40 candidate,
        uint8 title,
        uint40 appointer
    ) private {
        if (!isDirector(candidate))
            require(
                qtyOfDirectors() < maxQtyOfDirectors(),
                "BOD.addDirector: number of directors overflow"
            );

        uint48 startDate = uint48(block.timestamp);

        bytes32 governingRule = _getSHA().getRule(0);

        uint48 endDate = startDate +
            governingRule.tenureOfBoard() * 31536000;

        _directors[candidate] = Director({
            title: title,
            acct: candidate,
            appointer: appointer,
            startDate: startDate,
            endDate: endDate
        });

        if (title == uint8(TitleOfDirectors.Chairman)) {
            if (_directors[0].appointer == 0)
                _directors[0].appointer = candidate;
            else revert("BOD.addDirector: Chairman's position is occupied");
        } else if (title == uint8(TitleOfDirectors.ViceChairman)) {
            if (_directors[0].acct == 0) _directors[0].acct = candidate;
            else revert("BOD.addDirector: ViceChairman's position is occupied");
        }

        if (_board.add(candidate)) {
            require(rule.qtyOfBoardSeats() < _appointmentCounter[appointer], "BOD.addDirector: Board seets used up");

            emit AddDirector(title, candidate, appointer, startDate, endDate);
            _appointmentCounter[appointer]++;
        }
    }

    function takePosition(bytes32 rule, uint40 candidate, uint40 nominator) external onlyDirectKeeper {
        _addDirector(rule, candidate, uint8(TitleOfDirectors.Director), nominator);
    }

    function removeDirector(uint40 acct) external onlyDirectKeeper {
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
        return (_directors[acct].endDate >= block.timestamp &&
            _directors[acct].startDate <= block.timestamp);
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

    function startDateOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint48)
    {
        return _directors[acct].startDate;
    }

    function endDateOfDirector(uint40 acct)
        external
        view
        directorExist(acct)
        returns (uint48)
    {
        return _directors[acct].endDate;
    }

    function directors() external view returns (uint40[] memory) {
        return _board.valuesToUint40();
    }
}

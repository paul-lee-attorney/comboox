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

/*  _dirctors[0] {
        title: maxQtyOfDirectors;
        acct: ViceChair;
        appointer: Chairman;
        startDate: (pending);
        endDate: (pending);
    }
*/

    // userNo => Officer
    mapping(uint256 => Officer) private _officers;

    EnumerableSet.UintSet private _board;

    // userNo => numOfDirectors
    mapping(uint256 => uint32) private _appointmentCounter;

    //##################
    //##    写接口    ##
    //##################

    // ======== Directors ========

    function setMaxQtyOfDirectors(uint8 max)
        external
        onlyKeeper
    {
        _officers[0].title = max;
        emit SetMaxQtyOfDirectors(max);
    }

    function _addDirector(
        bytes32 bsRule,
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

        require(bsRule.qtyOfBoardSeats() < _appointmentCounter[appointer], 
            "BOD.addDirector: Board seets used up");

        _officers[candidate] = Officer({
            title: title,
            acct: candidate,
            appointer: appointer,
            startDate: startDate,
            endDate: endDate
        });

        if (title == uint8(TitleOfDirectors.Chairman)) {
            if (_officers[0].appointer == 0)
                _officers[0].appointer = candidate;
            else revert("BOD.addDirector: Chairman's position is occupied");
        } else if (title == uint8(TitleOfDirectors.ViceChairman)) {
            if (_officers[0].acct == 0) _officers[0].acct = candidate;
            else revert("BOD.addDirector: ViceChairman's position is occupied");
        }

        if (_board.add(candidate)) {
            emit AddDirector(candidate, title, appointer, startDate, endDate);

            _appointmentCounter[appointer]++;
        }
    }

    function takePosition(
        bytes32 bsRule, 
        uint8 title, 
        uint40 candidate, 
        uint40 nominator
    ) external onlyDirectKeeper {
        _addDirector(bsRule, candidate, title, nominator);
    }

    function removeDirector(uint40 acct) external onlyDirectKeeper {
        if (isDirector(acct)) {
            if (_officers[acct].title == uint8(TitleOfDirectors.Chairman)) {
                _officers[0].appointer = 0;
            } else if (
                _officers[acct].title == uint8(TitleOfDirectors.ViceChairman)
            ) {
                _officers[0].acct = 0;
            }

            delete _officers[acct];

            _board.remove(acct);

            emit RemoveDirector(acct);
        }
    }

    // ==== Officer ====

    function appointOfficer(
        uint16 seqOfVR,
        uint8 title,
        uint40 nominator,
        uint40 candidate
    ) external onlyDirectKeeper {
        require(isDirector(candidate) || !isOfficer(candidate), 
            "BODK.AO: officer needs to quit first");

        bytes32 vrRule = _getSHA().getRule(seqOfVR);
        require((vrRule.ratioAmountOfVR() == 0) && 
            (vrRule.ratioHeadOfVR() == 0), "BOD.AO: nomination needs to vote");

        emit AppointOfficer(candidate, title, nominator);

        _officers[candidate] = Officer({
            title: title,
            acct: candidate,
            appointer: nominator,
            startDate: uint48(block.timestamp),
            endDate: 0
        });
    }

    //##################
    //##    读接口    ##
    //##################

    function maxQtyOfDirectors() public view returns (uint8) {
        return _officers[0].title;
    }

    function qtyOfDirectors() public view returns (uint16) {
        return uint16(_board.length());
    }

    function isOfficer(uint40 acct) public view returns (bool) {
        return _officers[acct].acct == acct;
    }

    function isDirector(uint40 acct) public view returns (bool) {
        return _board.contains(acct);
    }

    function whoIs(uint8 title) external view returns (uint40) {
        if (title == uint8(TitleOfDirectors.Chairman))
            return _officers[0].appointer;
        else if (title == uint8(TitleOfDirectors.ViceChairman))
            return _officers[0].acct;
        else revert("BOD.whoIs: value of title overflow");
    }

    function getDirector(uint40 acct)
        external
        view
        returns(Officer memory)
    {
        require(_board.contains(acct), "BOD.GD: acct is not Director");
        
        return _officers[acct];
    }

    function directors() external view returns (uint40[] memory) {
        return _board.valuesToUint40();
    }

    function boardSeatsOf(uint256 acct) external view returns(uint256) {
        return _appointmentCounter[acct];
    } 
}

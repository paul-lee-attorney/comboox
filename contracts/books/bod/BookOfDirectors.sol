// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfDirectors.sol";

import "../../common/components/MeetingMinutes.sol";

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/RulesParser.sol";

contract BookOfDirectors is IBookOfDirectors, MeetingMinutes {
    using EnumerableSet for EnumerableSet.UintSet;
    using RulesParser for bytes32;

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
        RulesParser.BoardSeatsRule memory bsr,
        uint256 candidate,
        uint8 title,
        uint256 appointer
    ) private {
        if (!isDirector(candidate))
            require(
                qtyOfDirectors() < maxQtyOfDirectors(),
                "BOD.addDirector: number of directors overflow"
            );

        uint48 startDate = uint48(block.timestamp);

        RulesParser.GovernanceRule memory gr = _getSHA().getRule(0).governanceRuleParser();

        uint48 endDate = startDate +
            uint48(gr.tenureOfBoard) * 31536000;

        require(bsr.qtyOfBoardSeats < _appointmentCounter[appointer], 
            "BOD.addDirector: Board seets used up");

        _officers[candidate] = Officer({
            title: title,
            acct: uint40(candidate),
            appointer: uint40(appointer),
            startDate: startDate,
            endDate: endDate
        });

        if (title == uint8(TitleOfDirectors.Chairman)) {
            if (_officers[0].appointer == 0)
                _officers[0].appointer = uint40(candidate);
            else revert("BOD.addDirector: Chairman's position is occupied");
        } else if (title == uint8(TitleOfDirectors.ViceChairman)) {
            if (_officers[0].acct == 0) _officers[0].acct = uint40(candidate);
            else revert("BOD.addDirector: ViceChairman's position is occupied");
        }

        if (_board.add(candidate)) {
            emit AddDirector(candidate, title, appointer, startDate, endDate);

            _appointmentCounter[appointer]++;
        }
    }

    function takePosition(
        uint256 seqOfBSR, 
        uint8 title, 
        uint256 candidate, 
        uint256 nominator
    ) external onlyDirectKeeper {
        RulesParser.BoardSeatsRule memory bsr = 
            RulesParser.boardSeatsRuleParser(_getSHA().getRule(seqOfBSR));
        _addDirector(bsr, candidate, title, nominator);
    }

    function removeDirector(uint256 acct) external onlyDirectKeeper {
        if (isDirector(acct)) {
            if (_officers[acct].title == uint8(TitleOfDirectors.Chairman)) {
                _officers[0].appointer = 0;
            } else if (_officers[acct].title == uint8(TitleOfDirectors.ViceChairman)) {
                _officers[0].acct = 0;
            }

            delete _officers[acct];

            _board.remove(acct);

            emit RemoveDirector(acct);
        }
    }

    // ==== Officer ====

    function appointOfficer(
        uint256 seqOfVR,
        uint8 title,
        uint256 nominator,
        uint256 candidate
    ) external onlyDirectKeeper {
        require(isDirector(candidate) || !isOfficer(candidate), 
            "BODK.AO: officer needs to quit first");

        RulesParser.VotingRule memory vr = _getSHA().getRule(seqOfVR).votingRuleParser();

        require((vr.amountRatio == 0) && 
            (vr.headRatio == 0), "BOD.AO: nomination needs to vote");

        emit AppointOfficer(candidate, title, nominator);

        _officers[candidate] = Officer({
            title: title,
            acct: uint40(candidate),
            appointer: uint40(nominator),
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

    function isOfficer(uint256 acct) public view returns (bool) {
        return _officers[acct].acct == acct;
    }

    function isDirector(uint256 acct) public view returns (bool) {
        return _board.contains(acct);
    }

    function whoIs(uint8 title) external view returns (uint40) {
        if (title == uint8(TitleOfDirectors.Chairman))
            return _officers[0].appointer;
        else if (title == uint8(TitleOfDirectors.ViceChairman))
            return _officers[0].acct;
        else revert("BOD.whoIs: value of title overflow");
    }

    function getDirector(uint256 acct)
        external
        view
        returns(Officer memory)
    {
        require(_board.contains(acct), "BOD.GD: acct is not Director");        
        return _officers[acct];
    }

    function directors() external view returns (uint256[] memory) {
        return _board.values();
    }

    function boardSeatsOf(uint256 acct) external view returns(uint256) {
        return _appointmentCounter[acct];
    } 
}

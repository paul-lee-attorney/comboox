// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library RulesParser {

    // ======== GovernanceRule ========

    struct GovernanceRule {
        uint16 seq;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        bool basedOnPar;
        uint16 proposalThreshold;
        uint8 maxNumOfDirectors;
        uint8 tenureOfBoard;
        uint16 shaEffectiveRatio;
    }

    function governanceRuleParser(uint256 sn) public pure returns (GovernanceRule memory rule) {
        rule = GovernanceRule({
            seq: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            basedOnPar: uint8(sn >> 216) == 1,
            proposalThreshold: uint16(sn >> 200),
            maxNumOfDirectors: uint8(sn >> 192),
            tenureOfBoard: uint8(sn >> 184),
            shaEffectiveRatio: uint16(sn >> 168)
        });
    }

    function codifyGovernanceRule(GovernanceRule memory rule) public pure returns (uint256 sn) {
        sn = (uint256(rule.seq) << 240) +
            (uint256(rule.qtyOfSubRule) << 232) +
            (uint256(rule.seqOfSubRule) << 224) +
            (uint256(rule.basedOnPar ? 1 : 0) << 216) +
            (uint256(rule.proposalThreshold) << 200) +
            (uint256(rule.maxNumOfDirectors) << 192) +
            (uint256(rule.tenureOfBoard) << 184) +
            (uint256(rule.shaEffectiveRatio) << 168);
    }

    // ---- VotingRule ----

    struct VotingRule{
        uint16 seq;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        uint8 authority;
        uint16 headRatio;
        uint16 amountRatio;
        bool onlyAttendance;
        bool impliedConsent;
        bool partyAsConsent;
        bool againstShallBuy;
        uint8 shaExecDays;
        uint8 reviewDays;
        uint8 votingDays;
        uint8 execDaysForPutOpt;
        uint40[3] vetoers;
    }

    function votingRuleParser(uint256 sn) public pure returns (VotingRule memory rule) {
        rule = VotingRule({
            seq: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            authority: uint8(sn >> 216),
            headRatio: uint16(sn >> 200),
            amountRatio: uint16(sn >> 184),
            onlyAttendance: uint8(sn >> 176) == 1,
            impliedConsent: uint8(sn >> 168) == 1,
            partyAsConsent: uint8(sn >> 160) == 1,
            againstShallBuy: uint8(sn >> 152) == 1,
            shaExecDays: uint8(sn >> 144),
            reviewDays: uint8(sn >> 136),
            votingDays: uint8(sn >> 128),
            execDaysForPutOpt: uint8(sn >> 120),
            vetoers: [uint40(sn >> 80), uint40(sn >> 40), uint40(sn)]
        });
    }

    // ---- BoardSeatsRule ----

/*
    1: Chairman;
    2: ViceChairman;
    3: Director;
    ...
*/

    struct BoardSeatsRule {
        uint16 seq;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        uint40 rightholder;
        uint16 qtyOfBoardSeats;
        uint8[7] nominationTitle;
        uint16[7] vrSeqOfNomination;
    }

    function boardSeatsRuleParser(bytes32 sn) public pure returns(BoardSeatsRule memory rule) {
        rule = BoardSeatsRule({
            seq: uint16(bytes2(sn)),
            qtyOfSubRule: uint8(sn[2]),
            seqOfSubRule: uint8(sn[3]),
            rightholder: uint40(bytes5(sn << 32)),
            qtyOfBoardSeats: uint16(bytes2(sn<<72)),
            nominationTitle: [uint8(sn[11]), uint8(sn[12]), uint8(sn[13]), uint8(sn[14]), uint8(sn[15]),
                uint8(sn[16]), uint8(sn[17])],
            vrSeqOfNomination: [uint16(bytes2(sn<<144)), uint16(bytes2(sn<<156)), uint16(bytes2(sn<<160)),
                uint16(bytes2(sn<<176)), uint16(bytes2(sn<<188)), uint16(bytes2(sn<<204)),
                uint16(bytes2(sn<<220))]
        });
    }

    // ---- FirstRefusal Rule ----

    struct FirstRefusalRule {
        uint16 seq;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        uint8 typeOfDeal;
        bool membersEqual;
        bool proRata;
        bool basedOnPar;
        uint40[5] rightholders;        
    }

    function firstRefusalRuleParser(bytes32 sn) public pure returns(FirstRefusalRule memory rule) {
        rule = FirstRefusalRule({
            seq: uint16(bytes2(sn)),
            qtyOfSubRule: uint8(sn[2]),
            seqOfSubRule: uint8(sn[3]),
            typeOfDeal: uint8(sn[4]),
            membersEqual: uint8(sn[5]) == 1,
            proRata: uint8(sn[6]) == 1,
            basedOnPar: uint8(sn[7]) == 1,
            rightholders: [uint40(bytes5(sn<<56)), uint40(bytes5(sn<<96)), uint40(bytes5(sn<<136)),
                uint40(bytes5(sn<<176)), uint40(bytes5(sn<<216))]
        });
    }

    // ---- GroupUpdateOrder ----

    struct GroupUpdateOrder {
        uint16 seq;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        bool addMember;
        uint40 groupRep;
        uint40[4] members;        
    }

    function groupUpdateOrderParser(bytes32 sn) public pure returns(GroupUpdateOrder memory order) {
        order = GroupUpdateOrder({
            seq: uint16(bytes2(sn)),
            qtyOfSubRule: uint8(sn[2]),
            seqOfSubRule: uint8(sn[3]),
            addMember: uint8(sn[4]) == 1,
            groupRep: uint40(bytes5(sn<<40)),
            members: [uint40(bytes5(sn<<80)), uint40(bytes5(sn<<120)), uint40(bytes5(sn<<160)),
                uint40(bytes5(sn<<200))]
        });
    }    

    // ======== LinkRule ========

    struct LinkRule {
        uint16 seq;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        uint40 drager;
        uint40 dragerGroup;
        uint8 triggerType;  
        uint16 shareRatioThreshold;
        bool proRata;
        uint32 unitPrice;
        uint32 roe;
    }

    function linkRuleParser(bytes32 sn) public pure returns (LinkRule memory rule) {
        return LinkRule({
            seq: uint16(bytes2(sn)),
            qtyOfSubRule: uint8(sn[2]),
            seqOfSubRule: uint8(sn[3]),
            drager: uint40(bytes5(sn << 32)),
            dragerGroup: uint40(bytes5(sn << 72)),
            triggerType: uint8(sn[14]),
            shareRatioThreshold: uint16(bytes2(sn << 120)),
            proRata: (uint8(sn[17]) == 1),
            unitPrice: uint32(bytes4(sn<<144)),
            roe: uint32(bytes4(sn<<176))
        });
    }


}

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

    function boardSeatsRuleParser(uint256 sn) public pure returns(BoardSeatsRule memory rule) {
        rule = BoardSeatsRule({
            seq: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            rightholder: uint40(sn >> 184),
            qtyOfBoardSeats: uint16(sn >> 168),
            nominationTitle: [uint8(sn >> 160), uint8(sn >> 152), uint8(sn >> 144), uint8(sn >> 136), uint8(sn >> 128),
                uint8(sn >> 120), uint8(sn >> 112)],
            vrSeqOfNomination: [uint16(sn >> 96), uint16(sn >> 80), uint16(sn >> 64),
                uint16(sn >> 48), uint16(sn >> 32), uint16(sn >> 16),
                uint16(sn)]
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
        uint40[4] rightholders;        
    }

    function firstRefusalRuleParser(uint256 sn) public pure returns(FirstRefusalRule memory rule) {
        rule = FirstRefusalRule({
            seq: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            typeOfDeal: uint8(sn >> 216),
            membersEqual: uint8(sn >> 208) == 1,
            proRata: uint8(sn >> 200) == 1,
            basedOnPar: uint8(sn >> 192) == 1,
            rightholders: [uint40(sn >> 152), uint40(sn >> 112), uint40(sn >> 72),
                uint40(sn >> 32)]
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

    function groupUpdateOrderParser(uint256 sn) public pure returns(GroupUpdateOrder memory order) {
        order = GroupUpdateOrder({
            seq: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            addMember: uint8(sn >> 216) == 1,
            groupRep: uint40(sn >> 176),
            members: [uint40(sn >> 136), uint40(sn >> 96), uint40(sn >> 56),
                uint40(sn >> 16)]
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

    function linkRuleParser(uint256 sn) public pure returns (LinkRule memory rule) {
        return LinkRule({
            seq: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            drager: uint40(sn >> 184),
            dragerGroup: uint40(sn >> 144),
            triggerType: uint8(sn >> 136),
            shareRatioThreshold: uint16(sn >> 120),
            proRata: (uint8(sn >> 112) == 1),
            unitPrice: uint32(sn >> 80),
            roe: uint32(sn >> 48)
        });
    }


}

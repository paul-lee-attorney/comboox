// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library RulesParser {

    // ======== GovernanceRule ========

    struct GovernanceRule {
        uint16 seqOfRule;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        bool basedOnPar;
        uint16 proposeWeightRatioOfShares;
        uint16 proposeHeadNumOfDirectors;
        uint16 maxNumOfMembers;
        uint16 maxNumOfDirectors;
        uint16 tenureMonOfBoard;
        uint16 shaEffectiveRatio;
    }

    function governanceRuleParser(uint256 sn) public pure returns (GovernanceRule memory rule) {
        rule = GovernanceRule({
            seqOfRule: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            basedOnPar: uint8(sn >> 216) == 1,
            proposeWeightRatioOfShares: uint16(sn >> 200),
            proposeHeadNumOfDirectors: uint16(sn >> 184),
            maxNumOfMembers: uint16(sn >> 168),
            maxNumOfDirectors: uint16(sn >> 152),
            tenureMonOfBoard: uint16(sn >> 136),
            shaEffectiveRatio: uint16(sn >> 120)
        });
    }

    // ---- VotingRule ----

    struct VotingRule{
        uint16 seqOfRule;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        uint16 authority;
        uint16 headRatio;
        uint16 amountRatio;
        bool onlyAttendance;
        bool impliedConsent;
        bool partyAsConsent;
        bool againstShallBuy;
        uint8 shaExecDays;
        uint8 reviewDays;
        uint8 reconsiderDays;
        uint8 votingDays;
        uint8 execDaysForPutOpt;
        uint40[2] vetoers;
    }

    function votingRuleParser(uint256 sn) public pure returns (VotingRule memory rule) {
        rule = VotingRule({
            seqOfRule: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            authority: uint16(sn >> 208),
            headRatio: uint16(sn >> 192),
            amountRatio: uint16(sn >> 176),
            onlyAttendance: uint8(sn >> 168) == 1,
            impliedConsent: uint8(sn >> 160) == 1,
            partyAsConsent: uint8(sn >> 152) == 1,
            againstShallBuy: uint8(sn >> 144) == 1,
            shaExecDays: uint8(sn >> 136),
            reviewDays: uint8(sn >> 128),
            reconsiderDays: uint8(sn >> 120),
            votingDays: uint8(sn >> 112),
            execDaysForPutOpt: uint8(sn >> 104),
            vetoers: [uint40(sn >> 64), uint40(sn >> 24)]
        });
    }

    // ---- BoardSeatsRule ----

/*
    1: Chairman;
    2: ViceChairman;
    3: Director;
    ...
*/

    struct PositionAllocateRule {
        uint16 seqOfRule;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        bool removePos;
        uint16 seqOfPos;
        uint16 titleOfPos;
        uint40 nominator;
        uint16 seqOfVR;
        uint48 endDate;
        uint16 para;
        uint16 arg;
    }

    function positionAllocateRuleParser(uint256 sn) public pure returns(PositionAllocateRule memory rule) {
        rule = PositionAllocateRule({
            seqOfRule: uint16(sn >> 240),
            qtyOfSubRule: uint8(sn >> 232),
            seqOfSubRule: uint8(sn >> 224),
            removePos: uint8(sn >> 216) == 1,
            seqOfPos: uint16(sn >> 200),
            titleOfPos: uint16(sn >> 184),
            nominator: uint40(sn >> 144),
            seqOfVR: uint16(sn >> 128),
            endDate: uint48(sn >> 80),
            para: uint16(sn >> 64),
            arg: uint16(sn >> 48)
        });
    }

    // ---- FirstRefusal Rule ----

    struct FirstRefusalRule {
        uint16 seqOfRule;
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
            seqOfRule: uint16(sn >> 240),
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
        uint16 seqOfRule;
        uint8 qtyOfSubRule;
        uint8 seqOfSubRule;
        bool addMember;
        uint40 groupRep;
        uint40[4] members;        
    }

    function groupUpdateOrderParser(uint256 sn) public pure returns(GroupUpdateOrder memory order) {
        order = GroupUpdateOrder({
            seqOfRule: uint16(sn >> 240),
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
        uint16 seqOfRule;
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
            seqOfRule: uint16(sn >> 240),
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

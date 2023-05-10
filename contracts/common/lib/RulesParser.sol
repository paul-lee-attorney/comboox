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
        uint16 proposeWeightRatioOfGM; 
        uint16 proposeHeadNumOfMembers; 
        uint16 proposeHeadNumOfDirectors;
        uint16 maxNumOfMembers;
        uint16 quorumOfGM;  
        uint16 maxNumOfDirectors;
        uint16 tenureMonOfBoard;
        uint16 quorumOfBoardMeeting;
        uint48 establishedDate;    
        uint16 businessTerm;
        uint8 typeOfComp;
        uint8 argu; 
        bool flag; 
    }

    function governanceRuleParser(bytes32 sn) public pure returns (GovernanceRule memory rule) {
        uint _sn = uint(sn);

        rule = GovernanceRule({
            seqOfRule: uint16(_sn >> 240),
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224),
            basedOnPar: uint8(_sn >> 216) == 1,
            proposeWeightRatioOfGM: uint16(_sn >> 200),
            proposeHeadNumOfMembers: uint16(_sn >> 184),
            proposeHeadNumOfDirectors: uint16(_sn >> 168),
            maxNumOfMembers: uint16(_sn >> 152),
            quorumOfGM: uint16(_sn >> 136),
            maxNumOfDirectors: uint16(_sn >> 120),
            tenureMonOfBoard: uint16(_sn >> 104),
            quorumOfBoardMeeting: uint16(_sn >> 88),
            establishedDate: uint48(_sn >> 40),
            businessTerm: uint16(_sn >> 24),
            typeOfComp: uint8(_sn >> 16),
            argu: uint8(_sn >> 8),
            flag: uint8(_sn) == 1
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
        uint8 votePrepareDays;
        uint8 votingDays;
        uint8 execDaysForPutOpt;
        uint40[2] vetoers;
        uint16 para;
    }

    function votingRuleParser(bytes32 sn) public pure returns (VotingRule memory rule) {
        uint _sn = uint(sn);

        rule = VotingRule({
            seqOfRule: uint16(_sn >> 240),
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224),
            authority: uint16(_sn >> 208),
            headRatio: uint16(_sn >> 192),
            amountRatio: uint16(_sn >> 176),
            onlyAttendance: uint8(_sn >> 168) == 1,
            impliedConsent: uint8(_sn >> 160) == 1,
            partyAsConsent: uint8(_sn >> 152) == 1,
            againstShallBuy: uint8(_sn >> 144) == 1,
            shaExecDays: uint8(_sn >> 136),
            reviewDays: uint8(_sn >> 128),
            reconsiderDays: uint8(_sn >> 120),
            votePrepareDays: uint8(_sn >> 112),
            votingDays: uint8(_sn >> 104),
            execDaysForPutOpt: uint8(_sn >> 96),
            vetoers: [uint40(_sn >> 56), uint40(_sn >> 16)],
            para: uint16(_sn)            
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
        uint16 titleOfNominator;    
        uint16 seqOfVR; 
        uint48 endDate;
        uint16 para;    
        uint16 argu;
        uint32 data;
    }

    function positionAllocateRuleParser(bytes32 sn) public pure returns(PositionAllocateRule memory rule) {
        uint _sn = uint(sn);

        rule = PositionAllocateRule({
            seqOfRule: uint16(_sn >> 240), 
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224), 
            removePos: uint8(_sn >> 216) == 1,
            seqOfPos: uint16(_sn >> 200),
            titleOfPos: uint16(_sn >> 184),  
            nominator: uint40(_sn >> 144),   
            titleOfNominator: uint16(_sn >> 128),    
            seqOfVR: uint16(_sn >> 112), 
            endDate: uint48(_sn >> 64),
            para: uint16(_sn >> 48),    
            argu: uint16(_sn >> 32),
            data: uint32(_sn)
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
        uint16 para;
        uint16 argu;        
    }

    function firstRefusalRuleParser(bytes32 sn) public pure returns(FirstRefusalRule memory rule) {
        uint _sn = uint(sn);

        rule = FirstRefusalRule({
            seqOfRule: uint16(_sn >> 240),
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224),
            typeOfDeal: uint8(_sn >> 216),
            membersEqual: uint8(_sn >> 208) == 1,
            proRata: uint8(_sn >> 200) == 1,
            basedOnPar: uint8(_sn >> 192) == 1,
            rightholders: [uint40(_sn >> 152), uint40(_sn >> 112), uint40(_sn >> 72), uint40(_sn >> 32)],
            para: uint16(_sn >> 16),
            argu: uint16(_sn)                    
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
        uint16 para;        
    }

    function groupUpdateOrderParser(bytes32 sn) public pure returns(GroupUpdateOrder memory order) {
        uint _sn = uint(sn);
        
        order = GroupUpdateOrder({
            seqOfRule: uint16(_sn >> 240),
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224),
            addMember: uint8(_sn >> 216) == 1,
            groupRep: uint40(_sn >> 176),
            members: [
                uint40(_sn >> 136),
                uint40(_sn >> 96),
                uint40(_sn >> 56),
                uint40(_sn >> 16)
            ],
            para: uint16(_sn)
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
        uint16 para;
        uint32 data;
    }

    function linkRuleParser(bytes32 sn) public pure returns (LinkRule memory rule) {
        uint _sn = uint(sn);

        rule = LinkRule({
            seqOfRule: uint16(_sn >> 240),
            qtyOfSubRule: uint8(_sn >> 232),
            seqOfSubRule: uint8(_sn >> 224),
            drager: uint40(_sn >> 184),
            dragerGroup: uint40(_sn >> 144),
            triggerType: uint8(_sn >> 136),  
            shareRatioThreshold: uint16(_sn >> 120),
            proRata: uint8(_sn >> 112) == 1,
            unitPrice: uint32(_sn >> 80),
            roe: uint32(_sn >> 48),
            para: uint16(_sn >> 32),
            data: uint32(_sn)            
        });
    }


}

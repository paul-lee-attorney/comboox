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
        uint16 proposeHeadNumOfGM; 
        uint16 proposeHeadNumOfDirectors;
        uint32 maxNumOfMembers;
        uint16 quorumOfGM;  
        uint16 maxNumOfDirectors;
        uint16 tenureMonOfBoard;
        uint16 quorumOfBoardMeeting;
        uint16 para;    
        uint16 arg; 
        uint32 data;
        bool flag; 
    }

    function governanceRuleParser(bytes32 sn) public pure returns (GovernanceRule memory rule) {
        bytes memory _sn = new bytes(32);
        assembly {
            _sn := mload(add(sn, 0x20))
        }
        rule = abi.decode(_sn, (GovernanceRule));        
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
        bytes memory _sn = new bytes(32);
        assembly {
            _sn := mload(add(sn, 0x20))
        }
        rule = abi.decode(_sn, (VotingRule));        
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
        uint16 arg;
        uint32 data;
    }

    function positionAllocateRuleParser(bytes32 sn) public pure returns(PositionAllocateRule memory rule) {
        bytes memory _sn = new bytes(32);
        assembly {
            _sn := mload(add(sn, 0x20))
        }
        rule = abi.decode(_sn, (PositionAllocateRule));        
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
        uint16 arg;        
    }

    function firstRefusalRuleParser(bytes32 sn) public pure returns(FirstRefusalRule memory rule) {
        bytes memory _sn = new bytes(32);
        assembly {
            _sn := mload(add(sn, 0x20))
        }
        rule = abi.decode(_sn, (FirstRefusalRule));                
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
        bytes memory _sn = new bytes(32);
        assembly {
            _sn := mload(add(sn, 0x20))
        }
        order = abi.decode(_sn, (GroupUpdateOrder));                
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
        uint16 pare;
        uint32 data;
    }

    function linkRuleParser(bytes32 sn) public pure returns (LinkRule memory rule) {
        bytes memory _sn = new bytes(32);
        assembly {
            _sn := mload(add(sn, 0x20))
        }
        rule = abi.decode(_sn, (LinkRule));                
    }


}

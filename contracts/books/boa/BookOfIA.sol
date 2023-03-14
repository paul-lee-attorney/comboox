// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./InvestmentAgreement.sol";
import "./IInvestmentAgreement.sol";
import "./IBookOfIA.sol";

import "../../common/components/RepoOfDocs.sol";
import "../../common/components/IRepoOfDocs.sol";

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/RulesParser.sol";
import "../../common/lib/FRClaims.sol";
import "../../common/lib/DTClaims.sol";
import "../../common/lib/TopChain.sol";

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/BOHSetting.sol";
import "../../common/ruting/ROMSetting.sol";

contract BookOfIA is IBookOfIA, BOHSetting, ROMSetting, BOSSetting, RepoOfDocs {
    using RulesParser for bytes32;
    using FRClaims for FRClaims.Claims;
    using DTClaims for DTClaims.Claims;
    using TopChain for TopChain.Chain;
    using EnumerableSet for EnumerableSet.UintSet;

    // ia => frClaims
    mapping(address => FRClaims.Claims) private _frClaims;

    // ia => dtClaims
    mapping(address => DTClaims.Claims) private _dtClaims;

    // ia => mockResults
    mapping(address => TopChain.Chain) private _mockOfIA;

    //#################
    //##  Write I/O  ##
    //#################

    function circulateIA(
        address ia, 
        bytes32 docUrl, 
        bytes32 docHash
    ) external onlyDirectKeeper {
        uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();
        RulesParser.VotingRule memory vr = 
            _getSHA().getRule(typeOfIA).votingRuleParser();
        circulateDoc(ia, vr, docUrl, docHash);
    }

    // ==== FirstRefusal ====

    function execFirstRefusalRight(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyKeeper returns (bool flag) {
        Head memory headOfDoc = getHeadOfDoc(ia);
        require(headOfDoc.shaExecDeadline > block.timestamp, 
            "BOA.EFRR: missed shaExecDeadline");

        if (_frClaims[ia].execFirstRefusalRight(seqOfDeal, caller, sigHash))
        {
            emit ExecFirstRefusalRight(ia, seqOfDeal, caller);

            _resetDoc(ia, headOfDoc);

            flag = true;
        }
    }

    function _resetDoc(address ia, Head memory headOfDoc) private {
        if (headOfDoc.state > uint8(RODStates.Circulated)) {
            setStateOfDoc(ia, uint8(RODStates.Circulated));
            ISigPage(ia).setSigDeadline(false, headOfDoc.proposeDeadline);
        }
    }

    function acceptFirstRefusalClaims(
        address ia,
        uint256 seqOfDeal
    ) external onlyKeeper returns (FRClaims.Claim[] memory output) {        
        // IRepoOfDocs.Head memory headOfDoc = getHeadOfDoc(ia);
        // require(headOfDoc.shaExecDeadline <= block.timestamp, 
        //     "BOA.EFRR: shaExecDeadline not expired");

        emit AcceptFirstRefusalClaims(ia, seqOfDeal);
        output = _frClaims[ia].acceptFirstRefusalClaims(seqOfDeal, _getROM());
    }

    // ==== DragAlong & TagAlong ====

    function execAlongRight(
        address ia,
        bool dragAlong,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint256 caller,
        bytes32 sigHash
    ) external onlyKeeper
    {
        if (_dtClaims[ia].execAlongRight(dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash))
        {
            emit ExecAlongRight(ia, dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);
            _resetDoc(ia, getHeadOfDoc(ia));                
        }
    }

    // ==== Mock ====

    function createMockOfIA(address ia)
        external
        onlyKeeper
        returns (bool)
    {
        return _createMockOfIA(ia);
    }

    function _createMockOfIA(address ia)
        private
        returns (bool flag)
    {        
        if (_mockOfIA[ia].qtyOfMembers() == 0) {
            _mockOfIA[ia].restoreChain(_getROM().getSnapshot());
            _mockOfIA[ia].mockDealsOfIA(IInvestmentAgreement(ia));

            flag = true;
        }
    }

    function mockDealOfSell (address ia, uint40 seller, uint64 amount) 
        external
        onlyKeeper
        returns (bool flag) 
    {
        flag = _mockOfIA[ia].mockDealOfSell(seller, amount);
    }

    function mockDealOfBuy (address ia, uint40 buyer, uint40 groupRep, uint64 amount) 
        external
        onlyKeeper
        returns (bool flag) 
    {
        flag = _mockOfIA[ia].mockDealOfBuy(buyer, groupRep, amount);
    }

    //#################
    //##    读接口    ##
    //#################

    function isFRClaimer(address ia, uint256 acct) external view returns (bool)
    {
        return _frClaims[ia].isClaimer[acct];
    }

    function claimsOfFR(address ia, uint256 seqOfDeal)
        external view returns(FRClaims.Claim[] memory) 
    {
        return _frClaims[ia].claimsOfFR(seqOfDeal);
    }

    function hasDTClaims(address ia, uint256 seqOfDeal) 
        public view returns(bool)
    {
        return _dtClaims[ia].deals.contains(seqOfDeal);
    }

    function getDraggingDeals(address ia) 
        public view returns(uint256[] memory)
    {
        return _dtClaims[ia].deals.values();
    }

    function getDTClaimsForDeal(address ia, uint256 seqOfDeal)
        external view returns(DTClaims.Claim[] memory)
    {
        require(hasDTClaims(ia, seqOfDeal), "BOA.CODT: no claims found");

        return _dtClaims[ia].claimsOfDT(seqOfDeal);
    }

    function getDTClaimForShare(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external view returns(DTClaims.Claim memory)
    {
        return _dtClaims[ia].packs[seqOfDeal][2].claims[seqOfShare];
    }

    function mockResultsOfIA(address ia)
        external view
        returns (uint40 controllor, uint16 ratio) 
    {
        TopChain.Chain storage mock = _mockOfIA[ia];

        controllor = mock.head();
        ratio = uint16 (mock.votesOfGroup(controllor) / mock.totalVotes());
    }

    function mockResultsOfAcct(address ia, uint256 acct)
        external view
        returns (uint40 groupRep, uint16 ratio) 
    {
        TopChain.Chain storage mock = _mockOfIA[ia];

        groupRep = mock.rootOf(acct);
        ratio = uint16 (mock.votesOfGroup(groupRep) / mock.totalVotes());
    }
}

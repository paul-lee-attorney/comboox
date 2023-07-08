// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBookOfIA.sol";

import "../../common/components/FilesFolder.sol";

contract BookOfIA is IBookOfIA, FilesFolder {
    using DTClaims for DTClaims.Claims;
    using EnumerableSet for EnumerableSet.UintSet;
    using FRClaims for FRClaims.Claims;
    using FilesRepo for FilesRepo.Repo;
    // using RulesParser for bytes32;
    using TopChain for TopChain.Chain;

    // ia => frClaims
    mapping(address => FRClaims.Claims) private _frClaims;

    // ia => dtClaims
    mapping(address => DTClaims.Claims) private _dtClaims;

    // ia => mockResults
    mapping(address => TopChain.Chain) private _mockOfIA;

    //#################
    //##  Write I/O  ##
    //#################

    // function circulateIA(
    //     address ia, 
    //     bytes32 docUrl, 
    //     bytes32 docHash
    // ) external onlyDirectKeeper {
    //     uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();
    //     RulesParser.VotingRule memory vr = 
    //         _gk.getSHA().getRule(typeOfIA).votingRuleParser();
    //     circulateDoc(ia, vr, docUrl, docHash);
    // }

    // ==== FirstRefusal ====

    function execFirstRefusalRight(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyKeeper returns (bool flag) {
        FilesRepo.Head memory headOfFile = getHeadOfFile(ia);
        require(_repo.shaExecDeadline(ia) >= block.timestamp, 
            "BOA.EFRR: missed shaExecDeadline");

        if (_frClaims[ia].execFirstRefusalRight(seqOfDeal, caller, sigHash))
        {
            emit ExecFirstRefusalRight(ia, seqOfDeal, caller);

            _resetDoc(ia, headOfFile);

            flag = true;
        }
    }

    function _resetDoc(address ia, FilesRepo.Head memory headOfFile) private {
        if (headOfFile.state > uint8(FilesRepo.StateOfFile.Circulated)) {
            setStateOfFile(ia, uint8(FilesRepo.StateOfFile.Circulated));
        }
    }

    function acceptFirstRefusalClaims(
        address ia,
        uint256 seqOfDeal
    ) external onlyKeeper returns (FRClaims.Claim[] memory output) {        
        emit AcceptFirstRefusalClaims(ia, seqOfDeal);
        output = _frClaims[ia].acceptFirstRefusalClaims(seqOfDeal, _gk.getBOM());
    }

    // ==== DragAlong & TagAlong ====

    function execAlongRight(
        address ia,
        bool dragAlong,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint256 caller,
        bytes32 sigHash
    ) external onlyKeeper
    {
        if (_dtClaims[ia].execAlongRight(dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash))
        {
            emit ExecAlongRight(ia, dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);
            _resetDoc(ia, getHeadOfFile(ia));                
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
        if (_mockOfIA[ia].getNumOfMembers() == 0) {
            _mockOfIA[ia].restoreChain(_gk.getBOM().getSnapshot());
            _mockOfIA[ia].mockDealsOfIA(IInvestmentAgreement(ia));

            flag = true;
        }
    }

    function mockDealOfSell (address ia, uint seller, uint amount) 
        external
        onlyKeeper
        returns (bool flag) 
    {
        flag = _mockOfIA[ia].mockDealOfSell(seller, amount);
    }

    function mockDealOfBuy (address ia, uint buyer, uint groupRep, uint amount) 
        external
        onlyKeeper
        returns (bool flag) 
    {
        flag = _mockOfIA[ia].mockDealOfBuy(buyer, groupRep, amount);
    }

    //#################
    //##   Read I/O  ##
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

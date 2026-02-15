// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "./IRegisterOfAgreements.sol";

import "../../common/components/FilesFolder.sol";

contract RegisterOfAgreements is IRegisterOfAgreements, FilesFolder {
    using DTClaims for DTClaims.Claims;
    using DTClaims for DTClaims.Head;
    using FRClaims for FRClaims.Claims;
    using FilesRepo for FilesRepo.Repo;
    using TopChain for TopChain.Chain;
    using InterfacesHub for address;

    // ia => frClaims
    mapping(address => FRClaims.Claims) private _frClaims;
    // ia => dtClaims
    mapping(address => DTClaims.Claims) private _dtClaims;
    // ia => mockResults
    mapping(address => TopChain.Chain) private _mockOfIA;

    // ==== UUPSUpgradable ====
    uint256[50] private __gap;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== FirstRefusal ====

    function claimFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyKeeper {
        if (block.timestamp >= _repo.frExecDeadline(ia)) {
            revert ROA_WrongState("ROA_MissedDeadline");
        }
        _frClaims[ia].claimFirstRefusal(seqOfDeal, caller, sigHash);
        emit ClaimFirstRefusal(ia, seqOfDeal, caller);
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external onlyKeeper returns (FRClaims.Claim[] memory output) {
        if (block.timestamp < _repo.frExecDeadline(ia)) {
            revert ROA_WrongState("ROA_NotReachedFRDeadline");
        }
        output = _frClaims[ia].computeFirstRefusal(seqOfDeal, _gk.getROM());
        emit ComputeFirstRefusal(ia, seqOfDeal);
    }

    // ==== DragAlong & TagAlong ====

    function execAlongRight(
        address ia,
        bytes32 snOfClaim,
        bytes32 sigHash
    ) external onlyKeeper {
        if (block.timestamp < _repo.frExecDeadline(ia)) {
            revert ROA_WrongState("ROA_NotReachedFRDeadline");
        }
        if (block.timestamp >= _repo.dtExecDeadline(ia)) {
            revert ROA_WrongState("ROA_MissedDTDeadline");
        }

        _dtClaims[ia].execAlongRight(snOfClaim, sigHash);

        emit ExecAlongRight(ia, snOfClaim, sigHash);
    }

    function acceptAlongClaims(
        address ia, 
        uint seqOfDeal
    ) external onlyKeeper returns(DTClaims.Claim[] memory) {
        if (block.timestamp < _repo.dtExecDeadline(ia)) {
            revert ROA_WrongState("ROA_NotReachedDTDeadline");
        }
        
        emit AcceptAlongClaims(ia, seqOfDeal);
        return _dtClaims[ia].acceptAlongClaims(seqOfDeal);
    }

    // ==== Mock ====

    function createMockOfIA(address ia) external onlyKeeper {
        if (_mockOfIA[ia].qtyOfMembers() == 0) {
            (TopChain.Node[] memory list, TopChain.Para memory para) = 
                _gk.getROM().getSnapshot();
            _mockOfIA[ia].restoreChain(list, para);
            _mockOfIA[ia].mockDealsOfIA(IInvestmentAgreement(ia), _gk.getROS());
        }
    }
    
    //###############
    //##  Read I/O ##
    //###############

    // ==== FR Claims ====

    function hasFRClaims(address ia, uint seqOfDeal) external view returns (bool) {
        return _frClaims[ia].isDeal(seqOfDeal);
    }

    function isFRClaimer(address ia, uint256 acct) external view returns (bool)
    {
        return _frClaims[ia].isClaimer(acct);
    }

    function getSubjectDealsOfFR(address ia) external view returns(uint[] memory) {
        return _frClaims[ia].getDeals();
    }

    function getFRClaimsOfDeal(address ia, uint256 seqOfDeal)
        external view returns(FRClaims.Claim[] memory) 
    {
        return _frClaims[ia].getClaimsOfDeal(seqOfDeal);
    }

    function allFRClaimsAccepted(address ia) external view returns (bool) {
        return _frClaims[ia].allAccepted();
    }    

    // ==== DT Claims ====

    function hasDTClaims(address ia, uint256 seqOfDeal) 
        public view returns(bool)
    {
        return _dtClaims[ia].hasClaim(seqOfDeal);
    }

    function getSubjectDealsOfDT(address ia) 
        public view returns(uint256[] memory)
    {
        return _dtClaims[ia].getDeals();
    }

    function getDTClaimsOfDeal(address ia, uint256 seqOfDeal)
        external view returns(DTClaims.Claim[] memory)
    {
        return _dtClaims[ia].getClaimsOfDeal(seqOfDeal);
    }

    function getDTClaimForShare(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external view returns(DTClaims.Claim memory)
    {
        return _dtClaims[ia].getClaimForShare(seqOfDeal, seqOfShare);
    }

    function allDTClaimsAccepted(address ia) external view returns(bool) {
        return _dtClaims[ia].allAccepted();
    }

    // ==== Mock Results ====

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

    // ==== allClaimsAccepted ====

    function allClaimsAccepted(address ia) external view returns(bool) {
        return (_dtClaims[ia].allAccepted() && _frClaims[ia].allAccepted());
    }
}

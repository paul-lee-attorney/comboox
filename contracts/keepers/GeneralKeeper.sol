// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";
import "../common/access/IAccessControl.sol";

import "../common/lib/RolesRepo.sol";

import "./IGeneralKeeper.sol";
import "./IBOAKeeper.sol";
import "./IBODKeeper.sol";
import "./IBOHKeeper.sol";
import "./IBOMKeeper.sol";
import "./IBOOKeeper.sol";
import "./IBOPKeeper.sol";
import "./IBOSKeeper.sol";
import "./IROMKeeper.sol";
import "./ISHAKeeper.sol";

contract GeneralKeeper is IGeneralKeeper, AccessControl {
    using RolesRepo for RolesRepo.Roles;

    mapping (uint256 => address) private _keepers;

    IBOAKeeper private _BOAKeeper;
    IBODKeeper private _BODKeeper;
    IBOHKeeper private _BOHKeeper;
    IBOMKeeper private _BOMKeeper;
    IBOOKeeper private _BOOKeeper;
    IBOPKeeper private _BOPKeeper;
    IBOSKeeper private _BOSKeeper;
    IROMKeeper private _ROMKeeper;
    ISHAKeeper private _SHAKeeper;

    mapping (address => bool) private _isKeeper;

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setOwner(uint40 acct)
        external
        override
        onlyOwner
    {
        _roles.setOwner(acct);
    }

    function setGeneralCounsel(uint40 acct)
        external
        override
        onlyOwner
    {
        _roles.setGeneralCounsel(acct);
    }

    function setBookeeper(uint8 title, address keeper) external onlyDirectKeeper {
        if (_isKeeper[_keepers[title]])
            _isKeeper[_keepers[title]] = false;

        emit SetBookeeper(title, keeper);

        _keepers[title] = keeper;
        _isKeeper[keeper] = true;

        if (title == uint8(TitleOfKeepers.BOAKeeper))
            _BOAKeeper = IBOAKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.BODKeeper))
            _BODKeeper = IBODKeeper(keeper);
    }

    function isKeeper(address caller)
        external
        view
        returns (bool flag)
    {
        flag = _isKeeper[caller];
    }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function setTempOfIA(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .setTempOfIA(temp, typeOfDoc);
    }

    function createIA(uint8 typeOfIA) external {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .createIA(typeOfIA, _msgSender());
    }

    function removeIA(address body) external {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .removeIA(body, _msgSender());
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .circulateIA(body, _msgSender(), docUrl, docHash);
    }

    function signIA(address ia, bytes32 sigHash) external {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .signIA(ia, _msgSender(), sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint48 closingDate
    ) external {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .pushToCoffer(ia, sn, hashLock, closingDate, _msgSender());
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey
    ) external {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .closeDeal(ia, sn, hashKey, _msgSender());
    }

    function transferTargetShare(address ia, bytes32 sn) external {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .transferTargetShare(ia, sn, _msgSender());
    }

    function issueNewShare(address ia, bytes32 sn) external onlyDirectKeeper {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .issueNewShare(ia, sn);
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey
    ) external {
        IBOAKeeper(_keepers[uint8(TitleOfKeepers.BOAKeeper)])
            .revokeDeal(ia, sn, _msgSender(), hashKey);
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function appointDirector(uint16 seqOfRule, uint8 seqOfTitle, uint40 candidate) external {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .appointDirector(seqOfRule, seqOfTitle, candidate, _msgSender());
    }

    function takePosition(bytes32 rule, uint256 motionId) external {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .takePosition(rule, _msgSender(), motionId);
    }

    function removeDirector(uint40 director) external {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .removeDirector(director, _msgSender());
    }

    function quitPosition() external {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .quitPosition(_msgSender());
    }

    // ==== resolution ====

    function entrustDirectorDelegate(uint40 delegate, uint256 actionId)
        external
    {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .entrustDelegate(_msgSender(), delegate, actionId);
    }

    function proposeBoardAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor
    ) external {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .proposeAction(
                actionType,
                targets,
                values,
                params,
                desHash,
                _msgSender(),
                executor
            );
    }

    function castBoardVote(
        uint256 actionId,
        uint8 attitude,
        bytes32 sigHash
    ) external {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .castVote(actionId, attitude, _msgSender(), sigHash);
    }

    function boardVoteCounting(uint256 actionId) external {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .voteCounting(actionId, _msgSender());
    }

    function execBoardAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external {
        IBODKeeper(_keepers[uint8(TitleOfKeepers.BODKeeper)])
            .execAction(
                actionType,
                targets,
                values,
                params,
                desHash,
                _msgSender()
            );
    }

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function setTempOfSHA(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
        IBOHKeeper(_keepers[uint8(TitleOfKeepers.BOHKeeper)])
            .setTempOfSHA(temp, typeOfDoc);
    }

    function setTermTemplate(uint8 title, address addr) external onlyDirectKeeper {
        IBOHKeeper(_keepers[uint8(TitleOfKeepers.BOHKeeper)])
            .setTermTemplate(title, addr);
    }

    function createSHA(uint8 docType) external {
        IBOHKeeper(_keepers[uint8(TitleOfKeepers.BOHKeeper)])
            .createSHA(docType, _msgSender());
    }

    function removeSHA(address body) external {
        IBOHKeeper(_keepers[uint8(TitleOfKeepers.BOHKeeper)])
            .removeSHA(body, _msgSender());
    }

    function circulateSHA(address body, bytes32 rule, bytes32 docUrl, bytes32 docHash) external {
        IBOHKeeper(_keepers[uint8(TitleOfKeepers.BOHKeeper)])
            .circulateSHA(body, _msgSender(), rule, docUrl, docHash);
    }

    function signSHA(address sha, bytes32 sigHash) external {
        IBOHKeeper(_keepers[uint8(TitleOfKeepers.BOHKeeper)])        
            .signSHA(sha, _msgSender(), sigHash);
    }

    function effectiveSHA(address body) external {
        IBOHKeeper(_keepers[uint8(TitleOfKeepers.BOHKeeper)])
            .effectiveSHA(body, _msgSender());
    }

    function acceptSHA(bytes32 sigHash) external {
        IBOHKeeper(_keepers[uint8(TitleOfKeepers.BOHKeeper)])
            .acceptSHA(sigHash, _msgSender());
    }

    // ###################
    // ##   BOMKeeper   ##
    // ###################

    function createCorpSeal() external onlyDirectKeeper {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .createCorpSeal();
    }

    function createBoardSeal() external onlyDirectKeeper {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .createBoardSeal();
    }

    function setRegNumberHash(bytes32 numHash) external onlyDirectKeeper {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .setRegNumberHash(numHash);
    }

    function entrustMemberDelegate(uint40 delegate, uint256 motionId) external {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .entrustDelegate(_msgSender(), delegate, motionId);
    }

    function nominateDirector(uint40 candidate) external {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .nominateDirector(candidate, _msgSender());
    }

    function proposeIA(address ia, uint8 typeOfDoc) external {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .proposeDoc(ia, typeOfDoc, _msgSender());
    }

    function proposeGMAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor
    ) external {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .proposeAction(
                actionType,
                targets,
                values,
                params,
                desHash,
                _msgSender(),
                executor
            );
    }

    function castGMVote(
        uint256 motionId,
        uint8 attitude,
        bytes32 sigHash
    ) external {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .castVote(motionId, attitude, _msgSender(), sigHash);
    }

    function voteCounting(uint256 motionId) external {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .voteCounting(motionId, _msgSender());
    }

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external returns (uint256) {
        return  IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .execAction(
                actionType,
                targets,
                values,
                params,
                desHash,
                _msgSender()
            );
    }

    function requestToBuy(
        address ia,
        bytes32 sn,
        uint40 againstVoter
    ) external {
        IBOMKeeper(_keepers[uint8(TitleOfKeepers.BOMKeeper)])
            .requestToBuy(ia, sn, againstVoter, _msgSender());
    }

    // #################
    // ##  BOOKeeper  ##
    // #################

    function createOption(
        bytes32 sn,
        uint40 rightholder,
        uint64 paid,
        uint64 par
    ) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .createOption(sn, rightholder, paid, par, _msgSender());
    }

    function joinOptionAsObligor(bytes32 sn) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .joinOptionAsObligor(sn, _msgSender());
    }

    function removeObligorFromOption(bytes32 sn, uint40 obligor) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .removeObligorFromOption(sn, obligor, _msgSender());
    }

    function updateOracle(
        bytes32 sn,
        uint32 d1,
        uint32 d2
    ) external onlyDirectKeeper {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .updateOracle(sn, d1, d2);
    }

    function execOption(bytes32 sn) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .execOption(sn, _msgSender());
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .addFuture(sn, shareNumber, paidPar, _msgSender());
    }

    function removeFuture(bytes32 sn, bytes32 ft) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .removeFuture(sn, ft, _msgSender());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .requestPledge(sn, shareNumber, paidPar, _msgSender());
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .lockOption(sn, hashLock, _msgSender());
    }

    function closeOption(bytes32 sn, string memory hashKey) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .closeOption(sn, hashKey, _msgSender());
    }

    function revokeOption(bytes32 sn) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .revokeOption(sn, _msgSender());
    }

    function releasePledges(bytes32 sn) external {
        IBOOKeeper(_keepers[uint8(TitleOfKeepers.BOOKeeper)])
            .releasePledges(sn, _msgSender());
    }

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 pledgedPar,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 guaranteedAmt
    ) external {
        IBOPKeeper(_keepers[uint8(TitleOfKeepers.BOPKeeper)])
            .createPledge(
                sn,
                shareNumber,
                creditor,
                monOfGuarantee,
                pledgedPar,
                guaranteedAmt,
                _msgSender()
            );
    }

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint48 expireDate,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external {
        IBOPKeeper(_keepers[uint8(TitleOfKeepers.BOPKeeper)])
            .updatePledge(
                sn,
                creditor,
                expireDate,
                pledgedPar,
                guaranteedAmt,
                _msgSender()
            );
    }

    function delPledge(bytes32 sn) external {
        IBOPKeeper(_keepers[uint8(TitleOfKeepers.BOPKeeper)])
            .delPledge(sn, _msgSender());
    }

    // ###################
    // ##   BOSKeeper   ##
    // ###################

    function setPayInAmount(bytes32 sn, uint64 amount) external onlyDirectKeeper {
        IBOSKeeper(_keepers[uint8(TitleOfKeepers.BOSKeeper)])
            .setPayInAmount(sn, amount);
    }

    function requestPaidInCapital(bytes32 sn, string memory hashKey) external {
        IBOSKeeper(_keepers[uint8(TitleOfKeepers.BOSKeeper)])
            .requestPaidInCapital(sn, hashKey);
    }

    function withdrawPayInAmount(bytes32 sn) external onlyDirectKeeper {
        IBOSKeeper(_keepers[uint8(TitleOfKeepers.BOSKeeper)])
            .withdrawPayInAmount(sn);
    }

    function decreaseCapital(
        uint32 ssn,
        uint64 parValue,
        uint64 paidPar
    ) external onlyDirectKeeper {
        IBOSKeeper(_keepers[uint8(TitleOfKeepers.BOSKeeper)])
            .decreaseCapital(ssn, parValue, paidPar);
    }

    function updatePaidInDeadline(uint32 ssn, uint32 line) external onlyDirectKeeper {
        IBOSKeeper(_keepers[uint8(TitleOfKeepers.BOSKeeper)])
            .updatePaidInDeadline(ssn, line);
    }

    // ##################
    // ##  ROMKeeper   ##
    // ##################

    function setVoteBase(bool onPar) external onlyDirectKeeper {
        IROMKeeper(_keepers[uint8(TitleOfKeepers.ROMKeeper)])
            .setVoteBase(onPar);
    }

    function setMaxQtyOfMembers(uint8 max) external onlyDirectKeeper {
        IROMKeeper(_keepers[uint8(TitleOfKeepers.ROMKeeper)])
            .setMaxQtyOfMembers(max);
    }

    function setAmtBase(bool onPar) external onlyDirectKeeper {
        IROMKeeper(_keepers[uint8(TitleOfKeepers.ROMKeeper)])
            .setAmtBase(onPar);
    }

    // ###################
    // ##   SHAKeeper   ##
    // ###################

    // ======= TagAlong ========

    function execTagAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[uint8(TitleOfKeepers.SHAKeeper)])
            .execAlongRight(
                ia,
                sn,
                false,
                shareNumber,
                paid,
                par,
                _msgSender(),
                sigHash
            );
    }

    function acceptTagAlong(
        address ia,
        bytes32 sn,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[uint8(TitleOfKeepers.SHAKeeper)])
            .acceptAlongDeal(ia, sn, _msgSender(), sigHash);
    }

    // ======= DragAlong ========

    function execDragAlong(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[uint8(TitleOfKeepers.SHAKeeper)])
            .execAlongRight(
                ia,
                sn,
                true,
                shareNumber,
                paid,
                par,
                _msgSender(),
                sigHash
            );
    }

    function acceptDragAlong(
        address ia,
        bytes32 sn,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[uint8(TitleOfKeepers.SHAKeeper)])
            .acceptAlongDeal(ia, sn, _msgSender(), sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[uint8(TitleOfKeepers.SHAKeeper)])
            .execAntiDilution(ia, sn, shareNumber, _msgSender(), sigHash);
    }

    function takeGiftShares(address ia, bytes32 sn) external {
        ISHAKeeper(_keepers[uint8(TitleOfKeepers.SHAKeeper)])
            .takeGiftShares(ia, sn, _msgSender());
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        bytes32 rule,
        uint256 seqOfRightholder,
        address ia,
        bytes32 sn,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[uint8(TitleOfKeepers.SHAKeeper)])
            .execFirstRefusal(rule, seqOfRightholder, ia, sn, _msgSender(), sigHash);
    }

    function acceptFirstRefusal(
        address ia,
        bytes32 snOfOrg,
        uint16 ssnOfFR,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[uint8(TitleOfKeepers.SHAKeeper)])
            .acceptFirstRefusal(
                ia,
                snOfOrg,
                ssnOfFR,
                _msgSender(),
                sigHash
            );
    }
}

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
import "./IBOGKeeper.sol";
import "./IBOOKeeper.sol";
import "./IBOPKeeper.sol";
import "./IBOSKeeper.sol";
import "./IROMKeeper.sol";
import "./ISHAKeeper.sol";

contract GeneralKeeper is IGeneralKeeper, AccessControl {
    using RolesRepo for RolesRepo.Roles;

    bytes32 public regNumHash;

    IBOAKeeper private _BOAKeeper;
    IBODKeeper private _BODKeeper;
    IBOGKeeper private _BOGKeeper;
    IBOHKeeper private _BOHKeeper;
    IBOOKeeper private _BOOKeeper;
    IBOPKeeper private _BOPKeeper;
    IBOSKeeper private _BOSKeeper;
    IROMKeeper private _ROMKeeper;
    ISHAKeeper private _SHAKeeper;

    mapping(uint256 => address) private _books;

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setRegNumHash (bytes32 _regNumHash)
        external
        onlyOwner
    {
        emit SetRegNumberHash(regNumHash);
        regNumHash = _regNumHash;
    }

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

        emit SetBookeeper(title, keeper);

        if (title == uint8(TitleOfKeepers.BOAKeeper))
            _BOAKeeper = IBOAKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.BODKeeper))
            _BODKeeper = IBODKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.BOGKeeper))
            _BOGKeeper = IBOGKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.BOHKeeper))
            _BOHKeeper = IBOHKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.BOOKeeper))
            _BOOKeeper = IBOOKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.BOPKeeper))
            _BOPKeeper = IBOPKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.BOSKeeper))
            _BOSKeeper = IBOSKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.ROMKeeper))
            _ROMKeeper = IROMKeeper(keeper);
        else if (title == uint8(TitleOfKeepers.SHAKeeper))
            _SHAKeeper = ISHAKeeper(keeper);
        else revert("GK.SBK: title overflow");
    }

    function isKeeper(address caller)
        external
        view
        returns (bool flag)
    {        
        flag = (caller == address(_BOAKeeper) ||
                caller == address(_BODKeeper) ||
                caller == address(_BOGKeeper) ||
                caller == address(_BOHKeeper) ||
                caller == address(_BOOKeeper) ||
                caller == address(_BOPKeeper) ||
                caller == address(_BOSKeeper) ||
                caller == address(_ROMKeeper) ||
                caller == address(_SHAKeeper));
    }

    function setBook(uint16 title, address book) external onlyDirectKeeper {
        _books[title] = book;
        emit SetBook(title, book);
    } 

    // function getBook(uint16 title) public view returns (interface) {
    //     return IBOAKeeper(_books[title]);
    // }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function setTempOfIA(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
        _BOAKeeper.setTempOfIA(temp, typeOfDoc);
    }

    function createIA(uint8 typeOfIA) external {
        _BOAKeeper.createIA(typeOfIA, _msgSender());
    }

    function removeIA(address body) external {
        _BOAKeeper.removeIA(body, _msgSender());
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        _BOAKeeper.circulateIA(body, _msgSender(), docUrl, docHash);
    }

    function signIA(address ia, bytes32 sigHash) external {
        _BOAKeeper.signIA(ia, _msgSender(), sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint48 closingDate
    ) external {
        _BOAKeeper.pushToCoffer(ia, sn, hashLock, closingDate, _msgSender());
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey
    ) external {
        _BOAKeeper.closeDeal(ia, sn, hashKey, _msgSender());
    }

    function transferTargetShare(address ia, bytes32 sn) external {
        _BOAKeeper.transferTargetShare(ia, sn, _msgSender());
    }

    function issueNewShare(address ia, bytes32 sn) external onlyDirectKeeper {
        _BOAKeeper.issueNewShare(ia, sn);
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey
    ) external {
        _BOAKeeper.revokeDeal(ia, sn, _msgSender(), hashKey);
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function appointOfficer(bytes32 bsRule, uint8 seqOfTitle, uint40 candidate) external {
        _BODKeeper.appointOfficer(bsRule, seqOfTitle, _msgSender(), candidate);
    }

    function takePosition(bytes32 bsRule, uint8 seqOfTitle, uint256 motionId) external {
        _BODKeeper.takePosition(bsRule, seqOfTitle, motionId, _msgSender());
    }

    function removeDirector(uint40 director) external {
        _BODKeeper.removeDirector(director, _msgSender());
    }

    function quitPosition() external {
        _BODKeeper.quitPosition(_msgSender());
    }

    // ==== resolution ====

    function entrustDirectorDelegate(uint40 delegate, uint256 actionId)
        external
    {
        _BODKeeper.entrustDelegate(_msgSender(), delegate, actionId);
    }

    function proposeBoardAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor
    ) external {
        _BODKeeper.proposeAction(
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
        _BODKeeper.castVote(actionId, attitude, _msgSender(), sigHash);
    }

    function boardVoteCounting(uint256 actionId) external {
        _BODKeeper.voteCounting(actionId, _msgSender());
    }

    function execBoardAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external {
        _BODKeeper.execAction(
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
        _BOHKeeper.setTempOfSHA(temp, typeOfDoc);
    }

    function setTermTemplate(uint8 title, address addr) external onlyDirectKeeper {
        _BOHKeeper.setTermTemplate(title, addr);
    }

    function createSHA(uint8 docType) external {
        _BOHKeeper.createSHA(docType, _msgSender());
    }

    function removeSHA(address body) external {
        _BOHKeeper.removeSHA(body, _msgSender());
    }

    function circulateSHA(address body, bytes32 rule, bytes32 docUrl, bytes32 docHash) external {
        _BOHKeeper.circulateSHA(body, _msgSender(), rule, docUrl, docHash);
    }

    function signSHA(address sha, bytes32 sigHash) external  {
        _BOHKeeper.signSHA(sha, _msgSender(), sigHash);
    }

    function effectiveSHA(address body) external {
        _BOHKeeper.effectiveSHA(body, _msgSender());
    }

    function acceptSHA(bytes32 sigHash) external {
        _BOHKeeper.acceptSHA(sigHash, _msgSender());
    }

    // ###################
    // ##   BOGKeeper   ##
    // ###################

    function createCorpSeal() external onlyDirectKeeper {
        _BOGKeeper.createCorpSeal();
    }

    function createBoardSeal() external onlyDirectKeeper {
        _BOGKeeper.createBoardSeal();
    }

    function entrustMemberDelegate(uint40 delegate, uint256 motionId) external {
        _BOGKeeper.entrustDelegate(motionId, _msgSender(), delegate);
    }

    function nominateOfficer(bytes32 bsRule, uint8 seqOfTitle, uint40 candidate) external {
        _BOGKeeper.nominateOfficer(bsRule, seqOfTitle, _msgSender(), candidate);
    }

    function proposeIA(address ia, uint8 typeOfDoc) external {
        _BOGKeeper.proposeDoc(ia, typeOfDoc, _msgSender());
    }

    function proposeGMAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor
    ) external {
        _BOGKeeper.proposeAction(
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
        _BOGKeeper.castVote(motionId, _msgSender(), attitude, sigHash);
    }

    function voteCounting(uint256 motionId) external {
        _BOGKeeper.voteCounting(motionId, _msgSender());
    }

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external returns (uint256) {
        return _BOGKeeper.execAction(
                    actionType,
                    targets,
                    values,
                    params,
                    desHash,
                    _msgSender()
                );
    }

    function requestToBuy(
        uint256 motionId,
        bytes32 snOfDeal,
        uint40 againstVoter
    ) external {
        _BOGKeeper.requestToBuy(motionId, snOfDeal, againstVoter, _msgSender());
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
        _BOOKeeper.createOption(sn, rightholder, paid, par, _msgSender());
    }

    function joinOptionAsObligor(bytes32 sn) external {
        _BOOKeeper.joinOptionAsObligor(sn, _msgSender());
    }

    function removeObligorFromOption(bytes32 sn, uint40 obligor) external {
        _BOOKeeper.removeObligorFromOption(sn, obligor, _msgSender());
    }

    function updateOracle(
        bytes32 sn,
        uint32 d1,
        uint32 d2
    ) external onlyDirectKeeper {
        _BOOKeeper.updateOracle(sn, d1, d2);
    }

    function execOption(bytes32 sn) external {
        _BOOKeeper.execOption(sn, _msgSender());
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external {
        _BOOKeeper.addFuture(sn, shareNumber, paidPar, _msgSender());
    }

    function removeFuture(bytes32 sn, bytes32 ft) external {
        _BOOKeeper.removeFuture(sn, ft, _msgSender());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external {
        _BOOKeeper.requestPledge(sn, shareNumber, paidPar, _msgSender());
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external {
        _BOOKeeper.lockOption(sn, hashLock, _msgSender());
    }

    function closeOption(bytes32 sn, string memory hashKey) external {
        _BOOKeeper.closeOption(sn, hashKey, _msgSender());
    }

    function revokeOption(bytes32 sn) external {
        _BOOKeeper.revokeOption(sn, _msgSender());
    }

    function releasePledges(bytes32 sn) external {
        _BOOKeeper.releasePledges(sn, _msgSender());
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
        _BOPKeeper.createPledge(
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
        _BOPKeeper.updatePledge(
                sn,
                creditor,
                expireDate,
                pledgedPar,
                guaranteedAmt,
                _msgSender()
            );
    }

    function delPledge(bytes32 sn) external {
        _BOPKeeper.delPledge(sn, _msgSender());
    }

    // ###################
    // ##   BOSKeeper   ##
    // ###################

    function setPayInAmount(bytes32 sn, uint64 amount) external onlyDirectKeeper {
        _BOSKeeper.setPayInAmount(sn, amount);
    }

    function requestPaidInCapital(bytes32 sn, string memory hashKey) external {
        _BOSKeeper.requestPaidInCapital(sn, hashKey);
    }

    function withdrawPayInAmount(bytes32 sn) external onlyDirectKeeper {
        _BOSKeeper.withdrawPayInAmount(sn);
    }

    function decreaseCapital(
        uint32 ssn,
        uint64 parValue,
        uint64 paidPar
    ) external onlyDirectKeeper {
        _BOSKeeper.decreaseCapital(ssn, parValue, paidPar);
    }

    function updatePaidInDeadline(uint32 ssn, uint32 line) external onlyDirectKeeper {
        _BOSKeeper.updatePaidInDeadline(ssn, line);
    }

    // ##################
    // ##  ROMKeeper   ##
    // ##################

    function setVoteBase(bool onPar) external onlyDirectKeeper {
        _ROMKeeper.setVoteBase(onPar);
    }

    function setMaxQtyOfMembers(uint8 max) external onlyDirectKeeper {
        _ROMKeeper.setMaxQtyOfMembers(max);
    }

    function setAmtBase(bool onPar) external onlyDirectKeeper {
        _ROMKeeper.setAmtBase(onPar);
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
        _SHAKeeper.execAlongRight(
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
        _SHAKeeper.acceptAlongDeal(ia, sn, _msgSender(), sigHash);
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
        _SHAKeeper.execAlongRight(
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
        _SHAKeeper.acceptAlongDeal(ia, sn, _msgSender(), sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        bytes32 sigHash
    ) external {
        _SHAKeeper.execAntiDilution(ia, sn, shareNumber, _msgSender(), sigHash);
    }

    function takeGiftShares(address ia, bytes32 sn) external {
        _SHAKeeper.takeGiftShares(ia, sn, _msgSender());
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        bytes32 rule,
        uint256 seqOfRightholder,
        address ia,
        bytes32 sn,
        bytes32 sigHash
    ) external {
        _SHAKeeper.execFirstRefusal(rule, seqOfRightholder, ia, sn, _msgSender(), sigHash);
    }

    function acceptFirstRefusal(
        address ia,
        bytes32 snOfOrg,
        uint16 ssnOfFR,
        bytes32 sigHash
    ) external {
        _SHAKeeper.acceptFirstRefusal(
                ia,
                snOfOrg,
                ssnOfFR,
                _msgSender(),
                sigHash
            );
    }
}

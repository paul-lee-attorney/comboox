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

    mapping(uint256 => address) private _books;
    mapping(uint256 => address) private _keepers;

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

    function setBookeeper(uint16 title, address keeper) external onlyDirectKeeper {

        emit SetBookeeper(title, keeper);
        _keepers[title] = keeper;
    }

    function isKeeper(address caller)
        external
        view
        returns (bool)
    {   
        uint256 len = 9;

        while (len > 0) {
            if (caller == _keepers[len - 1]) return true;
            len--;
        }
        return false;
    }

    function setBook(uint16 title, address book) external onlyDirectKeeper {
        emit SetBook(title, book);
        _books[title] = book;
    } 

    function getBook(uint16 title) external view returns (address) {
        return _books[title];
    }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function setTempOfIA(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
        IBOAKeeper(_keepers[0]).setTempOfIA(temp, typeOfDoc);
    }

    function createIA(uint8 typeOfIA) external {
        IBOAKeeper(_keepers[0]).createIA(typeOfIA, _msgSender());
    }

    function removeIA(address body) external {
        IBOAKeeper(_keepers[0]).removeIA(body, _msgSender());
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IBOAKeeper(_keepers[0]).circulateIA(body, _msgSender(), docUrl, docHash);
    }

    function signIA(address ia, bytes32 sigHash) external {
        IBOAKeeper(_keepers[0]).signIA(ia, _msgSender(), sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint48 closingDate
    ) external {
        IBOAKeeper(_keepers[0]).pushToCoffer(ia, sn, hashLock, closingDate, _msgSender());
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey
    ) external {
        IBOAKeeper(_keepers[0]).closeDeal(ia, sn, hashKey, _msgSender());
    }

    function transferTargetShare(address ia, bytes32 sn) external {
        IBOAKeeper(_keepers[0]).transferTargetShare(ia, sn, _msgSender());
    }

    function issueNewShare(address ia, bytes32 sn) external onlyDirectKeeper {
        IBOAKeeper(_keepers[0]).issueNewShare(ia, sn);
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey
    ) external {
        IBOAKeeper(_keepers[0]).revokeDeal(ia, sn, _msgSender(), hashKey);
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function appointOfficer(bytes32 bsRule, uint8 seqOfTitle, uint40 candidate) external {
        IBODKeeper(_keepers[1]).appointOfficer(bsRule, seqOfTitle, _msgSender(), candidate);
    }

    function takePosition(bytes32 bsRule, uint8 seqOfTitle, uint256 motionId) external {
        IBODKeeper(_keepers[1]).takePosition(bsRule, seqOfTitle, motionId, _msgSender());
    }

    function removeDirector(uint40 director) external {
        IBODKeeper(_keepers[1]).removeDirector(director, _msgSender());
    }

    function quitPosition() external {
        IBODKeeper(_keepers[1]).quitPosition(_msgSender());
    }

    // ==== resolution ====

    function entrustDirectorDelegate(uint40 delegate, uint256 actionId)
        external
    {
        IBODKeeper(_keepers[1]).entrustDelegate(_msgSender(), delegate, actionId);
    }

    function proposeBoardAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor
    ) external {
        IBODKeeper(_keepers[1]).proposeAction(
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
        IBODKeeper(_keepers[1]).castVote(actionId, attitude, _msgSender(), sigHash);
    }

    function boardVoteCounting(uint256 actionId) external {
        IBODKeeper(_keepers[1]).voteCounting(actionId, _msgSender());
    }

    function execBoardAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external {
        IBODKeeper(_keepers[1]).execAction(
                actionType,
                targets,
                values,
                params,
                desHash,
                _msgSender()
            );
    }

    // ###################
    // ##   BOGKeeper   ##
    // ###################

    function createCorpSeal() external onlyDirectKeeper {
        IBOGKeeper(_keepers[2]).createCorpSeal();
    }

    function createBoardSeal() external onlyDirectKeeper {
        IBOGKeeper(_keepers[2]).createBoardSeal();
    }

    function entrustMemberDelegate(uint40 delegate, uint256 motionId) external {
        IBOGKeeper(_keepers[2]).entrustDelegate(motionId, _msgSender(), delegate);
    }

    function nominateOfficer(bytes32 bsRule, uint8 seqOfTitle, uint40 candidate) external {
        IBOGKeeper(_keepers[2]).nominateOfficer(bsRule, seqOfTitle, _msgSender(), candidate);
    }

    function proposeIA(address ia, uint8 typeOfDoc) external {
        IBOGKeeper(_keepers[2]).proposeDoc(ia, typeOfDoc, _msgSender());
    }

    function proposeGMAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor
    ) external {
        IBOGKeeper(_keepers[2]).proposeAction(
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
        IBOGKeeper(_keepers[2]).castVote(motionId, _msgSender(), attitude, sigHash);
    }

    function voteCounting(uint256 motionId) external {
        IBOGKeeper(_keepers[2]).voteCounting(motionId, _msgSender());
    }

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external returns (uint256) {
        return IBOGKeeper(_keepers[2]).execAction(
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
        IBOGKeeper(_keepers[2]).requestToBuy(motionId, snOfDeal, againstVoter, _msgSender());
    }

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function setTempOfBOH(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
        IBOHKeeper(_keepers[3]).setTempOfBOH(temp, typeOfDoc);
    }

    // function setTermTemplate(uint8 title, address addr) external onlyDirectKeeper {
    //     IBOHKeeper(_keepers[3]).setTermTemplate(title, addr);
    // }

    function createSHA(uint8 docType) external {
        IBOHKeeper(_keepers[3]).createSHA(docType, _msgSender());
    }

    function removeSHA(address body) external {
        IBOHKeeper(_keepers[3]).removeSHA(body, _msgSender());
    }

    function circulateSHA(address body, bytes32 rule, bytes32 docUrl, bytes32 docHash) external {
        IBOHKeeper(_keepers[3]).circulateSHA(body, _msgSender(), rule, docUrl, docHash);
    }

    function signSHA(address sha, bytes32 sigHash) external  {
        IBOHKeeper(_keepers[3]).signSHA(sha, _msgSender(), sigHash);
    }

    function effectiveSHA(address body) external {
        IBOHKeeper(_keepers[3]).effectiveSHA(body, _msgSender());
    }

    function acceptSHA(bytes32 sigHash) external {
        IBOHKeeper(_keepers[3]).acceptSHA(sigHash, _msgSender());
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
        IBOOKeeper(_keepers[4]).createOption(sn, rightholder, paid, par, _msgSender());
    }

    function joinOptionAsObligor(bytes32 sn) external {
        IBOOKeeper(_keepers[4]).joinOptionAsObligor(sn, _msgSender());
    }

    function removeObligorFromOption(bytes32 sn, uint40 obligor) external {
        IBOOKeeper(_keepers[4]).removeObligorFromOption(sn, obligor, _msgSender());
    }

    function updateOracle(
        bytes32 sn,
        uint32 d1,
        uint32 d2
    ) external onlyDirectKeeper {
        IBOOKeeper(_keepers[4]).updateOracle(sn, d1, d2);
    }

    function execOption(bytes32 sn) external {
        IBOOKeeper(_keepers[4]).execOption(sn, _msgSender());
    }

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external {
        IBOOKeeper(_keepers[4]).addFuture(sn, shareNumber, paidPar, _msgSender());
    }

    function removeFuture(bytes32 sn, bytes32 ft) external {
        IBOOKeeper(_keepers[4]).removeFuture(sn, ft, _msgSender());
    }

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar
    ) external {
        IBOOKeeper(_keepers[4]).requestPledge(sn, shareNumber, paidPar, _msgSender());
    }

    function lockOption(bytes32 sn, bytes32 hashLock) external {
        IBOOKeeper(_keepers[4]).lockOption(sn, hashLock, _msgSender());
    }

    function closeOption(bytes32 sn, string memory hashKey) external {
        IBOOKeeper(_keepers[4]).closeOption(sn, hashKey, _msgSender());
    }

    function revokeOption(bytes32 sn) external {
        IBOOKeeper(_keepers[4]).revokeOption(sn, _msgSender());
    }

    function releasePledges(bytes32 sn) external {
        IBOOKeeper(_keepers[4]).releasePledges(sn, _msgSender());
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
        IBOPKeeper(_keepers[5]).createPledge(
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
        IBOPKeeper(_keepers[5]).updatePledge(
                sn,
                creditor,
                expireDate,
                pledgedPar,
                guaranteedAmt,
                _msgSender()
            );
    }

    function delPledge(bytes32 sn) external {
        IBOPKeeper(_keepers[5]).delPledge(sn, _msgSender());
    }

    // ###################
    // ##   BOSKeeper   ##
    // ###################

    function setPayInAmount(bytes32 sn, uint64 amount) external onlyDirectKeeper {
        IBOSKeeper(_keepers[6]).setPayInAmount(sn, amount);
    }

    function requestPaidInCapital(bytes32 sn, string memory hashKey) external {
        IBOSKeeper(_keepers[6]).requestPaidInCapital(sn, hashKey);
    }

    function withdrawPayInAmount(bytes32 sn) external onlyDirectKeeper {
        IBOSKeeper(_keepers[6]).withdrawPayInAmount(sn);
    }

    function decreaseCapital(
        uint32 ssn,
        uint64 parValue,
        uint64 paidPar
    ) external onlyDirectKeeper {
        IBOSKeeper(_keepers[6]).decreaseCapital(ssn, parValue, paidPar);
    }

    function updatePaidInDeadline(uint32 ssn, uint32 line) external onlyDirectKeeper {
        IBOSKeeper(_keepers[6]).updatePaidInDeadline(ssn, line);
    }

    // ##################
    // ##  ROMKeeper   ##
    // ##################

    function setVoteBase(bool onPar) external onlyDirectKeeper {
        IROMKeeper(_keepers[7]).setVoteBase(onPar);
    }

    function setMaxQtyOfMembers(uint8 max) external onlyDirectKeeper {
        IROMKeeper(_keepers[7]).setMaxQtyOfMembers(max);
    }

    function setAmtBase(bool onPar) external onlyDirectKeeper {
        IROMKeeper(_keepers[7]).setAmtBase(onPar);
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
        ISHAKeeper(_keepers[8]).execAlongRight(
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
        ISHAKeeper(_keepers[8]).acceptAlongDeal(ia, sn, _msgSender(), sigHash);
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
        ISHAKeeper(_keepers[8]).execAlongRight(
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
        ISHAKeeper(_keepers[8]).acceptAlongDeal(ia, sn, _msgSender(), sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).execAntiDilution(ia, sn, shareNumber, _msgSender(), sigHash);
    }

    function takeGiftShares(address ia, bytes32 sn) external {
        ISHAKeeper(_keepers[8]).takeGiftShares(ia, sn, _msgSender());
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        uint16 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        bytes32 sn,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).execFirstRefusal(seqOfRule, seqOfRightholder, ia, sn, _msgSender(), sigHash);
    }

    function acceptFirstRefusal(
        address ia,
        bytes32 snOfDeal,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).acceptFirstRefusal(
                ia,
                snOfDeal,
                _msgSender(),
                sigHash
            );
    }
}

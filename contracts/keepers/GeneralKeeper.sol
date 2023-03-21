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

    function setOwner(uint256 acct)
        external
        override
        onlyOwner
    {
        _roles.setOwner(acct);
    }

    function setBookeeper(uint256 title, address keeper) external onlyDirectKeeper {

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

    function setBook(uint256 title, address book) external onlyDirectKeeper {
        emit SetBook(title, book);
        _books[title] = book;
    } 

    function getBook(uint256 title) external view returns (address) {
        return _books[title];
    }

    // ###################
    // ##   BOAKeeper   ##
    // ###################

    function setTempOfIA(address temp, uint256 typeOfDoc) external onlyDirectKeeper {
        IBOAKeeper(_keepers[0]).setTempOfIA(temp, typeOfDoc);
    }

    function createIA(uint256 typeOfIA) external {
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
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint48 closingDate
    ) external {
        IBOAKeeper(_keepers[0]).pushToCoffer(ia, seqOfDeal, hashLock, closingDate, _msgSender());
    }

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external {
        IBOAKeeper(_keepers[0]).closeDeal(ia, seqOfDeal, hashKey, _msgSender());
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external onlyDirectKeeper {
        IBOAKeeper(_keepers[0]).issueNewShare(ia, seqOfDeal);
    }

    function transferTargetShare(address ia, uint256 seqOfDeal) external {
        IBOAKeeper(_keepers[0]).transferTargetShare(ia, seqOfDeal, _msgSender());
    }

    function revokeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external {
        IBOAKeeper(_keepers[0]).revokeDeal(ia, seqOfDeal, _msgSender(), hashKey);
    }

    function terminateDeal(
        address ia,
        uint256 seqOfDeal
    ) external {
        IBOAKeeper(_keepers[0]).terminateDeal(ia, seqOfDeal, _msgSender());
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function appointOfficer(uint256 seqOfBSR, uint256 seqOfTitle, uint256 candidate) external {
        IBODKeeper(_keepers[1]).appointOfficer(seqOfBSR, seqOfTitle, _msgSender(), candidate);
    }

    function takePosition(uint256 seqOfBSR, uint256 seqOfTitle, uint256 motionId) external {
        IBODKeeper(_keepers[1]).takePosition(seqOfBSR, seqOfTitle, motionId, _msgSender());
    }

    function removeDirector(uint256 director) external {
        IBODKeeper(_keepers[1]).removeDirector(director, _msgSender());
    }

    function quitPosition() external {
        IBODKeeper(_keepers[1]).quitPosition(_msgSender());
    }

    // ==== resolution ====

    function entrustDirectorDelegate(uint256 delegate, uint256 actionId)
        external
    {
        IBODKeeper(_keepers[1]).entrustDelegate(_msgSender(), delegate, actionId);
    }

    function proposeBoardAction(
        uint256 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 executor
    ) external {
        IBODKeeper(_keepers[1]).proposeAction(
                typeOfAction,
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
        uint256 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external {
        IBODKeeper(_keepers[1]).execAction(
                typeOfAction,
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

    function entrustMemberDelegate(uint256 delegate, uint256 motionId) external {
        IBOGKeeper(_keepers[2]).entrustDelegate(motionId, _msgSender(), delegate);
    }

    function nominateOfficer(uint256 seqOfBSR, uint256 seqOfTitle, uint256 candidate) external {
        IBOGKeeper(_keepers[2]).nominateOfficer(seqOfBSR, seqOfTitle, _msgSender(), candidate);
    }

    function proposeIA(address ia, uint256 typeOfDoc) external {
        IBOGKeeper(_keepers[2]).proposeDoc(ia, typeOfDoc, _msgSender());
    }

    function proposeGMAction(
        uint256 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 executor
    ) external {
        IBOGKeeper(_keepers[2]).proposeAction(
                typeOfAction,
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
        uint256 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) external returns (uint256) {
        return IBOGKeeper(_keepers[2]).execAction(
                    typeOfAction,
                    targets,
                    values,
                    params,
                    desHash,
                    _msgSender()
                );
    }

    function requestToBuy(
        uint256 motionId,
        uint256 seqOfDeal,
        uint256 againstVoter
    ) external {
        IBOGKeeper(_keepers[2]).requestToBuy(motionId, seqOfDeal, againstVoter, _msgSender());
    }

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function setTempOfBOH(address temp, uint256 typeOfDoc) external onlyDirectKeeper {
        IBOHKeeper(_keepers[3]).setTempOfBOH(temp, typeOfDoc);
    }

    // function setTermTemplate(uint8 title, address addr) external onlyDirectKeeper {
    //     IBOHKeeper(_keepers[3]).setTermTemplate(title, addr);
    // }

    function createSHA(uint256 typeOfDoc) external {
        IBOHKeeper(_keepers[3]).createSHA(typeOfDoc, _msgSender());
    }

    function removeSHA(address body) external {
        IBOHKeeper(_keepers[3]).removeSHA(body, _msgSender());
    }

    function circulateSHA(address body, uint256 seqOfVR, bytes32 docUrl, bytes32 docHash) external {
        IBOHKeeper(_keepers[3]).circulateSHA(body, _msgSender(), seqOfVR, docUrl, docHash);
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

    function issueOption(
        bytes32 sn,
        uint256 rightholder,
        uint64 paid,
        uint64 par
    ) external {
        IBOOKeeper(_keepers[4]).issueOption(sn, rightholder, paid, par, _msgSender());
    }

    function joinOptionAsObligor(uint256 seqOfOpt) external {
        IBOOKeeper(_keepers[4]).joinOptionAsObligor(seqOfOpt, _msgSender());
    }

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external {
        IBOOKeeper(_keepers[4]).removeObligorFromOption(seqOfOpt, obligor, _msgSender());
    }

    function updateOracle(
        uint256 seqOfOpt,
        uint32 d1,
        uint32 d2
    ) external onlyDirectKeeper {
        IBOOKeeper(_keepers[4]).updateOracle(seqOfOpt, d1, d2);
    }

    function execOption(uint256 seqOfOpt) external {
        IBOOKeeper(_keepers[4]).execOption(seqOfOpt, _msgSender());
    }

    function addFuture(
        uint256 seqOfOpt,
        uint256 seqOfShare,
        uint64 paid
    ) external {
        IBOOKeeper(_keepers[4]).addFuture(seqOfOpt, seqOfShare, paid, _msgSender());
    }

    function removeFuture(uint256 seqOfOpt, uint256 seqOfFt) external {
        IBOOKeeper(_keepers[4]).removeFuture(seqOfOpt, seqOfFt, _msgSender());
    }

    function requestPledge(
        uint256 seqOfOpt,
        uint256 seqOfShare,
        uint64 paid
    ) external {
        IBOOKeeper(_keepers[4]).requestPledge(seqOfOpt, seqOfShare, paid, _msgSender());
    }

    function lockOption(uint256 seqOfOpt, bytes32 hashLock) external {
        IBOOKeeper(_keepers[4]).lockOption(seqOfOpt, hashLock, _msgSender());
    }

    function closeOption(uint256 seqOfOpt, string memory hashKey) external {
        IBOOKeeper(_keepers[4]).closeOption(seqOfOpt, hashKey, _msgSender());
    }

    function revokeOption(uint256 seqOfOpt) external {
        IBOOKeeper(_keepers[4]).revokeOption(seqOfOpt, _msgSender());
    }

    function releasePledges(uint256 seqOfOpt) external {
        IBOOKeeper(_keepers[4]).releasePledges(seqOfOpt, _msgSender());
    }

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        bytes32 sn,
        // uint256 seqOfShare,
        uint64 pledgedPar,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 guaranteedAmt
    ) external {
        IBOPKeeper(_keepers[5]).createPledge(
                sn,
                // seqOfShare,
                creditor,
                monOfGuarantee,
                pledgedPar,
                guaranteedAmt,
                _msgSender()
            );
    }

    function updatePledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint256 creditor,
        uint48 expireDate,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external {
        IBOPKeeper(_keepers[5]).updatePledge(
                seqOfShare,
                seqOfPld,
                creditor,
                expireDate,
                pledgedPar,
                guaranteedAmt,
                _msgSender()
            );
    }

    function delPledge(uint256 seqOfShare, uint256 seqOfPld) external {
        IBOPKeeper(_keepers[5]).delPledge(seqOfShare, seqOfPld, _msgSender());
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
        uint256 seqOfShare,
        uint64 parValue,
        uint64 paidPar
    ) external onlyDirectKeeper {
        IBOSKeeper(_keepers[6]).decreaseCapital(seqOfShare, parValue, paidPar);
    }

    function updatePaidInDeadline(uint256 seqOfShare, uint48 line) external onlyDirectKeeper {
        IBOSKeeper(_keepers[6]).updatePaidInDeadline(seqOfShare, line);
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
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).execAlongRight(
                ia,
                seqOfDeal,
                false,
                seqOfShare,
                paid,
                par,
                _msgSender(),
                sigHash
            );
    }

    // ======= DragAlong ========

    function execDragAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).execAlongRight(
                ia,
                seqOfDeal,
                true,
                seqOfShare,
                paid,
                par,
                _msgSender(),
                sigHash
            );
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).acceptAlongDeal(ia, seqOfDeal, seqOfShare, _msgSender(), sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).execAntiDilution(ia, seqOfDeal, seqOfShare, _msgSender(), sigHash);
    }

    function takeGiftShares(address ia, uint256 seqOfDeal) external {
        ISHAKeeper(_keepers[8]).takeGiftShares(ia, seqOfDeal, _msgSender());
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).execFirstRefusal(seqOfRule, seqOfRightholder, ia, seqOfDeal, _msgSender(), sigHash);
    }

    function acceptFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        ISHAKeeper(_keepers[8]).acceptFirstRefusal(
                ia,
                seqOfDeal,
                _msgSender(),
                sigHash
            );
    }
}

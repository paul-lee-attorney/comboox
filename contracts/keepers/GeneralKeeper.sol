// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IGeneralKeeper.sol";

contract GeneralKeeper is IGeneralKeeper, AccessControl {

    bytes32 public regNumHash;
    string public nameOfCompany;
    string public symbolOfCompany;

    mapping(uint256 => address) private _books;
    mapping(uint256 => address) private _keepers;

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setCompInfo (
        bytes32 _regNumHash,
        string memory _name,
        string memory _symbol
    ) external onlyOwner {
        emit SetCompInfo(_regNumHash, _name, _symbol);
        regNumHash = _regNumHash;
        nameOfCompany = _name;
        symbolOfCompany = _symbol;
    }

    // function setOwner(uint256 acct) external override {
    //     _roles.setOwner(acct, _msgSender());
    // }

    function setBookeeper(uint256 title, address keeper) 
    external onlyDirectKeeper {
        emit SetBookeeper(title, keeper);
        _keepers[title] = keeper;
    }

    function isKeeper(address caller) external view returns (bool) {   
        uint256 len = 10;

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

    function createIA(uint256 snOfIA) external {
        IBOAKeeper(_keepers[0]).createIA(snOfIA, msg.sender, _msgSender());
    }

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external {
        IBOAKeeper(_keepers[0]).circulateIA(body, _msgSender(), docUrl, docHash);
    }

    function signIA(address ia, bytes32 sigHash) external {
        IBOAKeeper(_keepers[0]).signIA(ia, _msgSender(), sigHash);
    }

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint48 closingDate) 
    external {
        IBOAKeeper(_keepers[0]).pushToCoffer(ia, seqOfDeal, hashLock, closingDate, _msgSender());
    }

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external {
        IBOAKeeper(_keepers[0]).closeDeal(ia, seqOfDeal, hashKey, _msgSender());
    }

    function issueNewShare(address ia, uint256 seqOfDeal) external onlyDirectKeeper {
        IBOAKeeper(_keepers[0]).issueNewShare(ia, seqOfDeal);
    }

    function transferTargetShare(address ia, uint256 seqOfDeal) external {
        IBOAKeeper(_keepers[0]).transferTargetShare(ia, seqOfDeal, _msgSender());
    }

    function revokeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external {
        IBOAKeeper(_keepers[0]).revokeDeal(ia, seqOfDeal, _msgSender(), hashKey);
    }

    function terminateDeal(address ia, uint256 seqOfDeal) external {
        IBOAKeeper(_keepers[0]).terminateDeal(ia, seqOfDeal, _msgSender());
    }

    // ###################
    // ##   BODKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint40 candidate) external {
        IBODKeeper(_keepers[1]).nominateOfficer(seqOfPos, candidate, _msgSender());
    }

    function proposeToRemoveOfficer(uint256 seqOfPos) external {
        IBODKeeper(_keepers[1]).proposeToRemoveOfficer(seqOfPos, _msgSender());
    }

    function proposeDoc(address doc, uint16 seqOfVR, uint40 executor) external {
        IBODKeeper(_keepers[1]).proposeDoc(doc, seqOfVR, executor, _msgSender());
    }

    function proposeAction(
        uint16 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor
    ) external {
        IBODKeeper(_keepers[1]).proposeAction(seqOfVR, targets, values, params, desHash, executor, _msgSender());
    }

    function entrustDelegate(uint256 seqOfMotion, uint40 delegate) external {
        IBODKeeper(_keepers[1]).entrustDelegate(seqOfMotion, delegate, _msgSender());
    }

    function castVote(uint256 seqOfMotion, uint8 attitude, bytes32 sigHash) external {
        IBODKeeper(_keepers[1]).castVote(seqOfMotion, attitude, sigHash, _msgSender());
    }

    function voteCounting(uint256 seqOfMotion) external {
        IBODKeeper(_keepers[1]).voteCounting(seqOfMotion, _msgSender());
    }

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external {
        IBODKeeper(_keepers[1]).takePosition(seqOfMotion, seqOfPos, _msgSender());
    }

    function quitPosition(uint256 seqOfPos) external {
        IBODKeeper(_keepers[1]).quitPosition(seqOfPos, _msgSender());
    }

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos, uint40 officer) external {
        IBODKeeper(_keepers[1]).removeOfficer(seqOfMotion, seqOfPos, officer, _msgSender());
    }

    function execAction(
        uint16 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        IBODKeeper(_keepers[1]).execAction(typeOfAction, targets, values, params, desHash, seqOfMotion, _msgSender());
    }

    // ###################
    // ##   BOGKeeper   ##
    // ###################

    function createCorpSeal() external onlyDirectKeeper {
        IBOGKeeper(_keepers[2]).createCorpSeal();
    }

    function createBoardSeal() external onlyDirectKeeper {
        IBOGKeeper(_keepers[2]).createBoardSeal(_keepers[1]);
    }

    function nominateDirector(uint256 seqOfPos, uint40 candidate) external {
        IBOGKeeper(_keepers[2]).nominateDirector(seqOfPos, candidate, _msgSender());
    }

    function proposeToRemoveDirector(uint256 seqOfPos) external {
        IBOGKeeper(_keepers[2]).proposeToRemoveDirector(seqOfPos, _msgSender());
    }

    function proposeDocOfGM(address doc, uint16 seqOfVR, uint40 executor) external {
        IBOGKeeper(_keepers[2]).proposeDocOfGM(doc, seqOfVR, executor, _msgSender());
    }

    function proposeActionOfGM(
        uint16 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor
    ) external {
        IBOGKeeper(_keepers[2]).proposeActionOfGM(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            _msgSender()
        );
    }

    function entrustDelegateOfMember(uint256 seqOfMotion, uint40 delegate) external {
        IBOGKeeper(_keepers[2]).entrustDelegateOfMember(seqOfMotion, delegate, _msgSender());
    }

    function proposeMotionOfGM(uint256 seqOfMotion) external {
        IBOGKeeper(_keepers[2]).proposeMotionOfGM(seqOfMotion, _msgSender());
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint8 attitude,
        bytes32 sigHash
    ) external {
        IBOGKeeper(_keepers[2]).castVoteOfGM(seqOfMotion, attitude, sigHash, _msgSender());
    }

    function voteCountingOfGM(uint256 seqOfMotion) external {
        IBOGKeeper(_keepers[2]).voteCountingOfGM(seqOfMotion, _msgSender());
    }

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external {
        IBOGKeeper(_keepers[2]).takeSeat(seqOfMotion, seqOfPos, _msgSender());
    }

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint40 director
    ) external {
        IBOGKeeper(_keepers[2]).removeDirector(seqOfMotion, seqOfPos, director, _msgSender());        
    }

    function execActionOfGM(
        uint16 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external {
        IBOGKeeper(_keepers[2]).execActionOfGM(
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            _msgSender()
        );
    }

    // ##################
    // ##  BOHKeeper   ##
    // ##################

    function createSHA(uint16 version) external {
        IBOHKeeper(_keepers[3]).createSHA(version, msg.sender, _msgSender());
    }

    function circulateSHA(address body, uint256 seqOfVR, bytes32 docUrl, bytes32 docHash) external {
        IBOHKeeper(_keepers[3]).circulateSHA(body, seqOfVR, docUrl, docHash, _msgSender());
    }

    function signSHA(address sha, bytes32 sigHash) external  {
        IBOHKeeper(_keepers[3]).signSHA(sha, sigHash, _msgSender());
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

    function updateOracle(
        uint256 seqOfOpt,
        uint64 d1,
        uint64 d2,
        uint64 d3
    ) external onlyDirectKeeper {
        IBOOKeeper(_keepers[4]).updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external {
        IBOOKeeper(_keepers[4]).execOption(seqOfOpt, _msgSender());
    }

    function placeSwapOrder(
        uint256 seqOfOpt,
        uint32 seqOfConsider,
        uint32 paidOfConsider,
        uint32 seqOfTarget
    ) external {
        IBOOKeeper(_keepers[4]).placeSwapOrder(seqOfOpt, seqOfConsider, paidOfConsider, seqOfTarget, _msgSender());
    }

    function lockSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        bytes32 hashLock
    ) external {
        IBOOKeeper(_keepers[4]).lockSwapOrder(seqOfOpt, seqOfBrf, hashLock, _msgSender());
    }

    function releaseSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        string memory hashKey
    ) external {
        IBOOKeeper(_keepers[4]).releaseSwapOrder(seqOfOpt, seqOfBrf, hashKey, _msgSender());
    }

    function execSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf
    ) external {
        IBOOKeeper(_keepers[4]).execSwapOrder(seqOfOpt, seqOfBrf, _msgSender());
    }

    function revokeSwapOrder(uint256 seqOfOpt, uint256 seqOfBrf) external {
        IBOOKeeper(_keepers[4]).revokeSwapOrder(seqOfOpt, seqOfBrf, _msgSender());
    }

    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(uint256 sn, uint40 creditor, uint16 guaranteeDays, uint64 paid,
    uint64 par, uint64 guaranteedAmt) external {
        IBOPKeeper(_keepers[5]).createPledge(sn, creditor, guaranteeDays, paid, par,
        guaranteedAmt, _msgSender());
    }

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint40 buyer, uint64 amt) 
    external {
        IBOPKeeper(_keepers[5]).transferPledge(seqOfShare, seqOfPld, buyer, amt, _msgSender());
    }

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint64 amt) external {
        IBOPKeeper(_keepers[5]).refundDebt(seqOfShare, seqOfPld, amt, _msgSender());
    }

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint16 extDays) external {
        IBOPKeeper(_keepers[5]).extendPledge(seqOfShare, seqOfPld, extDays, _msgSender());
    }

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external {
        IBOPKeeper(_keepers[5]).lockPledge(seqOfShare, seqOfPld, hashLock, _msgSender());
    }

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external {
        IBOPKeeper(_keepers[5]).releasePledge(seqOfShare, seqOfPld, hashKey, _msgSender());
    }

    function execPledge(uint256 seqOfShare, uint256 seqOfPld) external {
        IBOPKeeper(_keepers[5]).execPledge(seqOfShare, seqOfPld, _msgSender());
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external {
        IBOPKeeper(_keepers[5]).revokePledge(seqOfShare, seqOfPld, _msgSender());
    }

    // ###################
    // ##   BOSKeeper   ##
    // ###################

    function setPayInAmt(uint256 snOfLocker, uint64 amount) external onlyDirectKeeper {
        IBOSKeeper(_keepers[6]).setPayInAmt(snOfLocker, amount);
    }

    function requestPaidInCapital(uint256 snOfLocker, string memory hashKey, uint8 salt) external {
        IBOSKeeper(_keepers[6]).requestPaidInCapital(snOfLocker, hashKey, salt, _msgSender());
    }

    function withdrawPayInAmt(uint256 snOfLocker) external onlyDirectKeeper {
        IBOSKeeper(_keepers[6]).withdrawPayInAmt(snOfLocker);
    }

    function decreaseCapital(uint256 seqOfShare, uint64 parValue, uint64 paidPar) 
    external onlyDirectKeeper {
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

    // ##################
    // ##  ROSKeeper   ##
    // ##################

    function createSwap(
        uint256 sn,
        uint40 rightholder, 
        uint64 paidOfConsider
    ) external  {
        IROSKeeper(_keepers[9]).createSwap(sn, rightholder, paidOfConsider, _msgSender());
    }

    function transferSwap(
        uint256 seqOfSwap, 
        uint40 to, 
        uint64 amt
    ) external {
        IROSKeeper(_keepers[9]).transferSwap(seqOfSwap, to, amt, _msgSender());
    }

    function crystalizeSwap(
        uint256 seqOfSwap, 
        uint32 seqOfConsider, 
        uint32 seqOfTarget
    ) external {
        IROSKeeper(_keepers[9]).crystalizeSwap(seqOfSwap, seqOfConsider, seqOfTarget, _msgSender());
    }

    function lockSwap(
        uint256 seqOfSwap, 
        bytes32 hashLock
    ) external {
        IROSKeeper(_keepers[9]).lockSwap(seqOfSwap, hashLock, _msgSender());
    }

    function releaseSwap(uint256 seqOfSwap, string memory hashKey) external {
        IROSKeeper(_keepers[9]).releaseSwap(seqOfSwap, hashKey, _msgSender());
    } 

    function execSwap(uint256 seqOfSwap) external {
        IROSKeeper(_keepers[9]).execSwap(seqOfSwap, _msgSender());
    }

    function revokeSwap(uint256 seqOfSwap) external
    {
        IROSKeeper(_keepers[9]).revokeSwap(seqOfSwap, _msgSender());
    }

    function requestToBuy(
        uint256 seqOfMotion,
        uint256 seqOfDeal,
        uint32 seqOfTarget
    ) external {
        IROSKeeper(_keepers[9]).requestToBuy(seqOfMotion, seqOfDeal, seqOfTarget, _msgSender());
    }

    // ###############
    // ##  Ruting   ##
    // ###############

    function getBOA() external view returns (IBookOfIA) {
        return IBookOfIA(_books[0]);
    }

    function getBOD() external view returns (IBookOfDirectors ) {
        return IBookOfDirectors(_books[1]);
    }

    function getBOG() external view returns (IBookOfGM ) {
        return IBookOfGM(_books[2]);
    }

    function getBOH() external view returns (IBookOfSHA ) {
        return IBookOfSHA(_books[3]);
    }

    function getSHA() external view returns (IShareholdersAgreement ) {
        return IShareholdersAgreement(IBookOfSHA(_books[3]).pointer());
    }

    function getBOO() external view returns (IBookOfOptions ) {
        return IBookOfOptions(_books[4]);
    }

    function getBOP() external view returns (IBookOfPledges ) {
        return IBookOfPledges(_books[5]);
    }

    function getBOS() external view returns (IBookOfShares ) {
        return IBookOfShares(_books[6]);
    }

    function getROM() external view returns (IRegisterOfMembers ) {
        return IRegisterOfMembers(_books[7]);
    }

    function getROS() external view returns (IRegisterOfSwaps ) {
        return IRegisterOfSwaps(_books[8]);
    }

    
}

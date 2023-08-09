// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IROCKeeper.sol";

contract ROCKeeper is IROCKeeper, AccessControl {
    using RulesParser for bytes32;

    
    
    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address body, uint256 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function createSHA(
        uint version, 
        address primeKeyOfCaller, 
        uint caller
    ) external onlyDK {

        IRegCenter _rc = _getRC();
        IGeneralKeeper _gk = _getGK();

        require(_gk.getROM().isMember(caller), "not MEMBER");

        bytes32 snOfDoc = bytes32((uint256(uint8(IRegCenter.TypeOfDoc.SHA)) << 224) +
            uint224(version << 192)); 

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, primeKeyOfCaller);

        IAccessControl(doc.body).init(
            primeKeyOfCaller,
            address(this),
            address(_rc),
            address(_gk)
        );

        IShareholdersAgreement(doc.body).initDefaultRules();

        _gk.getROC().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external onlyDK onlyPartyOf(sha, caller) {
        require(IAccessControl(sha).isFinalized(), 
            "BOHK.CSHA: SHA not finalized");

        ISigPage(sha).circulateDoc();

        uint16 signingDays = ISigPage(sha).getSigningDays();
        uint16 closingDays = ISigPage(sha).getClosingDays();

        IGeneralKeeper _gk = _getGK();
        IShareholdersAgreement _sha = _gk.getSHA();

        RulesParser.VotingRule memory vr = 
            address(_sha) == address(0) ?
                RulesParser.SHA_INIT_VR.votingRuleParser() :
                _sha.getRule(8).votingRuleParser();
        
        // ISigPage(sha).setTiming(false, signingDays + vr.shaExecDays + vr.shaConfirmDays, closingDays);

        _gk.getROC().circulateFile(sha, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK onlyPartyOf(sha, caller) {

        IRegisterOfConstitution _roc = _getGK().getROC();

        require(
            _roc.getHeadOfFile(sha).state == uint8(FilesRepo.StateOfFile.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(true, caller, sigHash);

        if (ISigPage(sha).established())
        {
            _roc.establishFile(sha);
        }
    }

    function activateSHA(address sha, uint256 caller)
        external onlyDK onlyPartyOf(sha, caller)
    {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfConstitution _roc = _gk.getROC();
        IRegisterOfMembers _rom = _gk.getROM();

        _roc.execFile(sha);

        _roc.changePointer(sha);

        RulesParser.GovernanceRule memory gr = 
            IShareholdersAgreement(sha).getRule(0).governanceRuleParser();

        if (_rom.maxQtyOfMembers() != gr.maxQtyOfMembers)
            _rom.setMaxQtyOfMembers(gr.maxQtyOfMembers);

        _rom.setAmtBase(gr.basedOnPar);

        _rom.setVoteBase(gr.basedOnPar);


        // if (IShareholdersAgreement(sha).hasTitle(uint8(IRegCenter.TypeOfDoc.LockUp)))
        //     _lockUpShares(sha);
        
        if (IShareholdersAgreement(sha).hasTitle(uint8(IRegCenter.TypeOfDoc.Options))) 
            _regOptionTerms(sha);

        _updatePositionSetting(sha);
        _updateGrouping(sha);
    }

    // function _lockUpShares(address sha) private {
    //     IBookOfShares _bos = _getGK().getBOS();

    //     uint256[] memory lockedShares = ILockUp(IShareholdersAgreement(sha).getTerm(
    //         uint8(IRegCenter.TypeOfDoc.LockUp))).lockedShares();
    //     uint256 len = lockedShares.length;
    //     while (len > 0) {

    //         SharesRepo.Share memory share = _bos.getShare(lockedShares[len-1]);
    //         _bos.decreaseCleanPaid(share.head.seqOfShare, share.body.cleanPaid);
    //         len--;
    //     }
    // }

    function _regOptionTerms(address sha) private {
        address opts = IShareholdersAgreement(sha).
            getTerm(uint8(IRegCenter.TypeOfDoc.Options));
        _getGK().getROO().regOptionTerms(opts);
    }

    function _updatePositionSetting(address sha) private {
        IRegisterOfDirectors _rod = _getGK().getROD();

        uint256 len = IShareholdersAgreement(sha).getRule(256).positionAllocateRuleParser().qtyOfSubRule;
        uint256 i;
        while (i < len) {
            RulesParser.PositionAllocateRule memory rule = 
                IShareholdersAgreement(sha).getRule(256+i).positionAllocateRuleParser();

            if (rule.removePos) {
                _rod.removePosition(rule.seqOfPos);
            } else {
                OfficersRepo.Position memory pos = _rod.getPosition(rule.seqOfPos);
                pos = OfficersRepo.Position({
                    title: rule.titleOfPos,
                    seqOfPos: rule.seqOfPos,
                    acct: pos.acct,
                    nominator: rule.nominator,
                    startDate: pos.startDate,
                    endDate: rule.endDate,
                    seqOfVR: rule.seqOfVR,
                    titleOfNominator: rule.titleOfNominator,
                    argu: rule.argu
                });
                
                _rod.updatePosition(pos);
            }

            i++;
        }                
    }


    function _updateGrouping(address sha) private {
        IRegisterOfMembers _rom = _getGK().getROM();

        uint256 len = IShareholdersAgreement(sha).getRule(768).groupUpdateOrderParser().qtyOfSubRule;
        uint256 i;

        while (i < len) {
            RulesParser.GroupUpdateOrder memory order = 
                IShareholdersAgreement(sha).getRule(768+i).groupUpdateOrderParser();

            uint256 j;        
            if (order.addMember) {
                while (j < 4) {
                    if (order.members[j] > 0)
                        _rom.addMemberToGroup(order.members[j], order.groupRep);
                    j++;
                }
            } else {
                while (j < 4) {
                    if (order.members[j] > 0)
                        _rom.removeMemberFromGroup(order.members[j], order.groupRep);
                    j++;
                }
            }

            i++;
        }        
    }

    function acceptSHA(bytes32 sigHash, uint256 caller) external onlyDK {
        address _sha = address(_getGK().getSHA());
        ISigPage(_sha).addBlank(false, true, 1, caller);
        ISigPage(_sha).signDoc(false, caller, sigHash);
    }
}

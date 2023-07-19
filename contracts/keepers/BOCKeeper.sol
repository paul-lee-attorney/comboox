// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IBOCKeeper.sol";

contract BOCKeeper is IBOCKeeper, AccessControl {
    using RulesParser for bytes32;

    IGeneralKeeper private _gk = _getGK();
    IBookOfDirectors private _bod = _gk.getBOD();
    IBookOfMembers private _bom = _gk.getBOM();
    IBookOfConstitution private _boc = _gk.getBOC(); 
    IBookOfOptions private _boo = _gk.getBOO(); 
    IBookOfShares private _bos = _gk.getBOS();
    
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

        require(_bom.isMember(caller), "not MEMBER");

        bytes32 snOfDoc = bytes32((uint256(uint8(IRegCenter.TypeOfDoc.SHA)) << 240) +
            (version << 224)); 

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, primeKeyOfCaller);

        IAccessControl(doc.body).init(
            primeKeyOfCaller,
            address(this),
            address(_rc),
            address(_gk)
        );

        _boc.regFile(DocsRepo.codifyHead(doc.head), doc.body);
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

        IShareholdersAgreement _sha = _gk.getSHA();

        RulesParser.VotingRule memory vr = 
            address(_sha) == address(0) ?
                RulesParser.SHA_INIT_VR.votingRuleParser() :
                _sha.getRule(8).votingRuleParser();
        
        ISigPage(sha).setTiming(false, signingDays + vr.shaExecDays + vr.shaConfirmDays, closingDays);

        _boc.circulateFile(sha, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK onlyPartyOf(sha, caller) {
        require(
            _boc.getHeadOfFile(sha).state == uint8(FilesRepo.StateOfFile.Circulated),
            "SHA not in Circulated State"
        );

        if (ISigPage(sha).signDoc(true, caller, sigHash) &&
            ISigPage(sha).established())
        {
            _boc.establishFile(sha);
        }
    }

    function activateSHA(address sha, uint256 caller)
        external onlyDK onlyPartyOf(sha, caller)
    {
        IBookOfConstitution _boh = _boc;

        _boh.execFile(sha);

        _boh.changePointer(sha);

        RulesParser.GovernanceRule memory gr = 
            IShareholdersAgreement(sha).getRule(0).governanceRuleParser();

        if (_bom.maxQtyOfMembers() != gr.maxQtyOfMembers)
            _bom.setMaxQtyOfMembers(gr.maxQtyOfMembers);

        _bom.setAmtBase(gr.basedOnPar);

        _bom.setVoteBase(gr.basedOnPar);


        if (IShareholdersAgreement(sha).hasTitle(uint8(IRegCenter.TypeOfDoc.LockUp)))
            _lockUpShares(sha);
        
        if (IShareholdersAgreement(sha).hasTitle(uint8(IRegCenter.TypeOfDoc.Options))) 
            _regOptionTerms(sha);

        _updatePositionSetting(sha);
        _updateGrouping(sha);
    }

    function _lockUpShares(address sha) private {
        uint256[] memory lockedShares = ILockUp(IShareholdersAgreement(sha).getTerm(
            uint8(IRegCenter.TypeOfDoc.Options))).lockedShares();
        uint256 len = lockedShares.length;
        while (len > 0) {

            SharesRepo.Share memory share = _bos.getShare(lockedShares[len-1]);
            _bos.decreaseCleanPaid(share.head.seqOfShare, share.body.paid);
            len--;
        }
    }

    function _regOptionTerms(address sha) private {
        address opts = IShareholdersAgreement(sha).
            getTerm(uint8(IRegCenter.TypeOfDoc.Options));
        _boo.regOptionTerms(opts);
    }

    function _updatePositionSetting(address sha) private {
        uint256 len = IShareholdersAgreement(sha).getRule(256).positionAllocateRuleParser().qtyOfSubRule;
        uint256 i;
        while (i < len) {
            RulesParser.PositionAllocateRule memory rule = 
                IShareholdersAgreement(sha).getRule(256+i).positionAllocateRuleParser();

            if (rule.removePos) {
                _bod.removePosition(rule.seqOfPos);
            } else {
                OfficersRepo.Position memory pos = _bod.getPosition(rule.seqOfPos);
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
                
                _bod.updatePosition(pos);
            }

            i++;
        }                
    }


    function _updateGrouping(address sha) private {
        uint256 len = IShareholdersAgreement(sha).getRule(768).groupUpdateOrderParser().qtyOfSubRule;
        uint256 i;

        while (i < len) {
            RulesParser.GroupUpdateOrder memory order = 
                IShareholdersAgreement(sha).getRule(768+i).groupUpdateOrderParser();

            uint256 j;        
            if (order.addMember) {
                while (j < 4) {
                    if (order.members[j] > 0)
                        _bom.addMemberToGroup(order.members[j], order.groupRep);
                    j++;
                }
            } else {
                while (j < 4) {
                    if (order.members[j] > 0)
                        _bom.removeMemberFromGroup(order.members[j], order.groupRep);
                    j++;
                }
            }

            i++;
        }        
    }

    function acceptSHA(bytes32 sigHash, uint256 caller) external onlyDK {
        address _sha = address(_gk.getSHA());
        ISigPage(_sha).addBlank(false, true, 1, caller);
        ISigPage(_sha).signDoc(false, caller, sigHash);
    }
}

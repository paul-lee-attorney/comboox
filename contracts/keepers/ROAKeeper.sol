// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IROAKeeper.sol";

import "../common/access/AccessControl.sol";

contract ROAKeeper is IROAKeeper, AccessControl {
    using RulesParser for bytes32;


    // IRegCenter.TypeOfDoc[] public termsForCapitalIncrease = [
    //     IRegCenter.TypeOfDoc.AntiDilution
    // ];

    // IRegCenter.TypeOfDoc[] public termsForShareTransfer = [
    //     IRegCenter.TypeOfDoc.LockUp,
    //     IRegCenter.TypeOfDoc.TagAlong,
    //     IRegCenter.TypeOfDoc.DragAlong
    // ];

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address ia, uint256 caller) {
        require(ISigPage(ia).isParty(caller), "BOIK.md.OPO: NOT Party");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function createIA(uint version, address primeKeyOfCaller, uint caller) external onlyDK {
 
        IRegCenter _rc = _getRC();
        IGeneralKeeper _gk = _getGK();
 
        require(_gk.getROM().isMember(caller), "not MEMBER");
        
        bytes32 snOfDoc = bytes32((uint(uint8(IRegCenter.TypeOfDoc.IA)) << 224) +
            uint224(version << 192)); 

        DocsRepo.Doc memory doc = _rc.createDoc(
            snOfDoc,
            primeKeyOfCaller
        );

        IAccessControl(doc.body).init(
            primeKeyOfCaller,
            address(this),
            address(_rc),
            address(_gk)
        );

        _gk.getROA().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    // ======== Circulate IA ========

    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external onlyDK onlyPartyOf(ia, caller){
        require(IAccessControl(ia).isFinalized(), 
            "BOIK.CIA: IA not finalized");

        ISigPage(ia).circulateDoc();

        uint16 signingDays = ISigPage(ia).getSigningDays();
        uint16 closingDays = ISigPage(ia).getClosingDays();

        uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();

        IGeneralKeeper _gk = _getGK();

        RulesParser.VotingRule memory vr = 
            _gk.getSHA().getRule(typeOfIA).votingRuleParser();

        ISigPage(ia).setTiming(false, signingDays + vr.shaExecDays + vr.shaConfirmDays, closingDays);

        _gk.getROA().circulateFile(ia, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK onlyPartyOf(ia, caller) {
        IRegisterOfAgreements _roa = _getGK().getROA();

        require(
            _roa.getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Circulated),
            "BOIK.signIA: wrong state"
        );

        _lockDealsOfParty(ia, caller);
        ISigPage(ia).signDoc(true, caller, sigHash);
        
        if (ISigPage(ia).established()) {
            _roa.establishFile(ia);
        }
    }

    function _lockDealsOfParty(address ia, uint256 caller) private {
        uint[] memory list = IInvestmentAgreement(ia).getSeqList();
        uint256 len = list.length;
        while (len > 0) {
            uint seq = list[len - 1];
            len--;

            DealsRepo.Deal memory deal = 
                IInvestmentAgreement(ia).getDeal(seq);

            if (deal.head.seller == caller) {
                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    _getGK().getBOS().decreaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
                }
            } else if (
                deal.body.buyer == caller &&
                deal.head.typeOfDeal ==
                uint8(DealsRepo.TypeOfDeal.CapitalIncrease)
            ) IInvestmentAgreement(ia).lockDealSubject(seq);
        }
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline,
        uint256 caller
    ) external onlyDK {

        DealsRepo.Head memory head = 
            IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);

        bool isST = (head.seqOfShare != 0);

        if (isST) require(caller == head.seller, "BOIK.PTC: not seller");
        else require(_getGK().getROD().isDirector(caller), "BOIK.PTC: not director");

        _vrAndSHACheck(ia, seqOfDeal, isST);

        IInvestmentAgreement(ia).clearDealCP(seqOfDeal, hashLock, closingDeadline);
    }

    function _vrAndSHACheck(address ia, uint256 seqOfDeal, bool isST) private view {
        IGeneralKeeper _gk = _getGK();

        IMeetingMinutes _bmm = _gk.getBMM();
        IMeetingMinutes _gmm = _gk.getGMM();
        IRegisterOfAgreements _roa = _gk.getROA();

        require(
            _roa.getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Approved),
            "BOIK.vrAndSHACheck: wrong state"
        );

        uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();

        IShareholdersAgreement _sha = _gk.getSHA();

        RulesParser.VotingRule memory vr = _sha.getRule(typeOfIA).votingRuleParser();

        uint seqOfMotion = _roa.getHeadOfFile(ia).seqOfMotion;

        if (vr.amountRatio > 0 || vr.headRatio > 0) {
            if (vr.authority == 1)
                require(_gmm.isPassed(seqOfMotion), 
                    "BOIK.vrCheck:  rejected by GM");
            else if (vr.authority == 2)
                require(_bmm.isPassed(seqOfMotion), 
                    "BOIK.vrCheck:  rejected by Board");
            else if (vr.authority == 3)
                require(_gmm.isPassed(seqOfMotion) && 
                    _bmm.isPassed(seqOfMotion), 
                    "BOIK.vrCheck: rejected by GM or Board");
            else revert("BOIK.vrCheck: authority overflow");
        }

        if (isST && _sha.hasTitle(uint8(IShareholdersAgreement.TitleOfTerm.LockUp))) {
            address lu = _sha.getTerm(uint8(IShareholdersAgreement.TitleOfTerm.LockUp));
            require(
                ILockUp(lu).isExempted(ia, IInvestmentAgreement(ia).getDeal(seqOfDeal)),
                "ROAKeeper.lockUpCheck: not exempted");
        }
    }

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external onlyDK {

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        if (IInvestmentAgreement(ia).closeDeal(seqOfDeal, hashKey))
            _getGK().getROA().execFile(ia);

        if (deal.head.seqOfShare > 0) {
            _shareTransfer(ia, seqOfDeal);
        } else _issueNewShare(ia, seqOfDeal);
    }

    function _shareTransfer(address ia, uint256 seqOfDeal) private {
        IBookOfShares _bos = _getGK().getBOS();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        _bos.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _bos.transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, deal.body.buyer, deal.head.priceOfPaid, deal.head.priceOfPar);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) public onlyDK {

        _vrAndSHACheck(ia, seqOfDeal, false);

        if (IInvestmentAgreement(ia).directCloseDeal(seqOfDeal))
            _getGK().getROA().execFile(ia);

        _issueNewShare(ia, seqOfDeal);
    }

    function _issueNewShare(address ia, uint seqOfDeal) private {
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        SharesRepo.Share memory share;

        share.head = SharesRepo.Head({
            seqOfShare: 0,
            preSeq: 0,
            class: deal.head.classOfShare,
            issueDate: uint48(block.timestamp),
            shareholder: deal.body.buyer,
            priceOfPaid: deal.head.priceOfPaid,
            priceOfPar: deal.head.priceOfPar,
            para: 0,
            argu: 0
        });

        share.body = SharesRepo.Body({
            payInDeadline: uint48(block.timestamp) + 43200,
            paid: deal.body.paid,
            par: deal.body.par,
            cleanPaid: deal.body.paid,
            state: 0,
            para: 0
        });

        _getGK().getBOS().regShare(share);
    }


    function transferTargetShare(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) public onlyDK {
        require(
            caller == IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal).seller,
                "BOIK.TTS: not sellerOfDeal"
        );


        _vrAndSHACheck(ia, seqOfDeal, true);

        if (IInvestmentAgreement(ia).directCloseDeal(seqOfDeal))
            _getGK().getROA().execFile(ia);

        _shareTransfer(ia, seqOfDeal);
    }

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfAgreements _roa = _gk.getROA();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "BOIK.TD: NOT seller"
        );

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        uint8 state = _roa.getHeadOfFile(ia).state;

        if ((state < uint8(FilesRepo.StateOfFile.Proposed) &&
                block.timestamp >= _roa.terminateStartpoint(ia)) || 
            (state == uint8(FilesRepo.StateOfFile.Rejected)) ||
            (state == uint8(FilesRepo.StateOfFile.Approved) &&
                block.timestamp >= _ia.getHeadOfDeal(seqOfDeal).closingDeadline)
        ) {
            if (_ia.terminateDeal(seqOfDeal))
                _roa.terminateFile(ia);
            if (_ia.releaseDealSubject(seqOfDeal))
                _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);            
        } else revert("BOIK.TD: wrong state");
    }
}

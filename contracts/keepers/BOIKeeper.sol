// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOIKeeper.sol";

import "../common/access/AccessControl.sol";

contract BOIKeeper is IBOIKeeper, AccessControl {
    using RulesParser for bytes32;

    IRegCenter.TypeOfDoc[] private _termsForCapitalIncrease = [
        IRegCenter.TypeOfDoc.AntiDilution
    ];

    IRegCenter.TypeOfDoc[] private _termsForShareTransfer = [
        IRegCenter.TypeOfDoc.LockUp,
        IRegCenter.TypeOfDoc.TagAlong,
        IRegCenter.TypeOfDoc.DragAlong
    ];

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address ia, uint256 caller) {
        require(ISigPage(ia).isParty(caller), "BOAK.md.OPO: NOT Party");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function createIA(uint version, address primeKeyOfCaller, uint caller) external onlyDirectKeeper {
        require(_gk.getBOM().isMember(caller), "not MEMBER");
        
        bytes32 snOfDoc = bytes32((uint(uint8(IRegCenter.TypeOfDoc.IA)) << 240) +
            (version << 224)); 

        DocsRepo.Doc memory doc = _rc.createDoc(
            snOfDoc,
            primeKeyOfCaller
        );

        IAccessControl(doc.body).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );

        _gk.getBOI().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    // ======== Circulate IA ========

    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external onlyDirectKeeper onlyPartyOf(ia, caller){
        require(IAccessControl(ia).finalized(), 
            "BOAK.CIA: IA not finalized");

        ISigPage(ia).circulateDoc();

        uint16 signingDays = ISigPage(ia).getSigningDays();
        uint16 closingDays = ISigPage(ia).getClosingDays();

        uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();
        RulesParser.VotingRule memory vr = 
            _gk.getSHA().getRule(typeOfIA).votingRuleParser();

        ISigPage(ia).setTiming(false, signingDays + vr.shaExecDays + vr.shaConfirmDays, closingDays);

        _gk.getBOI().circulateFile(ia, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyPartyOf(ia, caller) {
        require(
            _gk.getBOI().getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Circulated),
            "BOAK.signIA: wrong state"
        );

        _lockDealsOfParty(ia, caller);
        if (ISigPage(ia).signDoc(true, caller, sigHash) && 
            ISigPage(ia).established()) 
        {
            _gk.getBOI().establishFile(ia);
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
                    _gk.getBOS().decreaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
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
    ) external onlyDirectKeeper {
        DealsRepo.Head memory head = 
            IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);

        bool isST = (head.seqOfShare != 0);

        if (isST) require(caller == head.seller, "BOAK.PTC: not seller");
        else require(_gk.getBOD().isDirector(caller), "BOAK.PTC: not director");

        _vrAndSHACheck(ia, seqOfDeal, isST);

        IInvestmentAgreement(ia).clearDealCP(seqOfDeal, hashLock, closingDeadline);
    }

    function _vrAndSHACheck(address ia, uint256 seqOfDeal, bool isST) private view {

        IBookOfIA _boi = _gk.getBOI();

        require(
            _boi.getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Approved),
            "BOAK.vrAndSHACheck: wrong state"
        );

        uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();

        RulesParser.VotingRule memory vr = _gk.getSHA().getRule(typeOfIA).votingRuleParser();

        uint seqOfMotion = _boi.getHeadOfFile(ia).seqOfMotion;

        IMeetingMinutes _gmm = _gk.getGMM();
        IMeetingMinutes _bmm = _gk.getBMM();

        if (vr.amountRatio > 0 || vr.headRatio > 0) {
            if (vr.authority == 1)
                require(_gmm.isPassed(seqOfMotion), 
                    "BOAK.vrCheck:  rejected by GM");
            else if (vr.authority == 2)
                require(_bmm.isPassed(seqOfMotion), 
                    "BOAK.vrCheck:  rejected by Board");
            else if (vr.authority == 3)
                require(_gmm.isPassed(seqOfMotion) && 
                    _bmm.isPassed(seqOfMotion), 
                    "BOAK.vrCheck: rejected by GM or Board");
            else revert("BOAK.vrCheck: authority overflow");
        }

        if (isST) _checkSHA(_termsForShareTransfer, ia, seqOfDeal);
        else _checkSHA(_termsForCapitalIncrease, ia, seqOfDeal);
    }

    function _checkSHA(
        IRegCenter.TypeOfDoc[] memory terms,
        address ia,
        uint256 seqOfDeal
    ) private view {
        uint256 len = terms.length;
        IShareholdersAgreement _sha = _gk.getSHA();

        while (len > 0) {
            if (_sha.hasTitle(uint8(terms[len - 1])))
                require(
                    _sha.termIsExempted(uint8(terms[len - 1]), ia, seqOfDeal),
                    "BOAK.PTC: term not exempted"
                );
            len--;
        }
    }

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external onlyDirectKeeper {

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        //交易发起人为买方;
        // require(
        //     deal.body.buyer == caller,
        //     "BOIKeeper.closeDeal: NOT buyer"
        // );

        //验证hashKey, 执行Deal
        if (IInvestmentAgreement(ia).closeDeal(seqOfDeal, hashKey))
            _gk.getBOI().execFile(ia);

        if (deal.head.seqOfShare > 0) {
            _shareTransfer(ia, seqOfDeal);
        } else _issueNewShare(ia, seqOfDeal);
    }

    function _shareTransfer(address ia, uint256 seqOfDeal) private {
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _gk.getBOS().transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, deal.body.buyer, deal.head.priceOfPaid, deal.head.priceOfPar);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) public onlyDirectKeeper {

        _vrAndSHACheck(ia, seqOfDeal, false);

        if (IInvestmentAgreement(ia).directCloseDeal(seqOfDeal))
            _gk.getBOI().execFile(ia);

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

        _gk.getBOS().regShare(share);
    }


    function transferTargetShare(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) public onlyDirectKeeper {
        require(
            caller == IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal).seller,
                "BOAK.TTS: not sellerOfDeal"
        );

        _vrAndSHACheck(ia, seqOfDeal, true);

        if (IInvestmentAgreement(ia).directCloseDeal(seqOfDeal))
            _gk.getBOI().execFile(ia);

        _shareTransfer(ia, seqOfDeal);
    }

    // function revokeDeal(
    //     address ia,
    //     uint256 seqOfDeal,
    //     uint256 caller,
    //     string memory hashKey
    // ) external onlyDirectKeeper {
    //     require(_gk.getBOI().getHeadOfFile(ia).state == 
    //                 uint8(FilesRepo.StateOfFile.Approved),
    //                 "BOAK.RD: wrong State");

    //     DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

    //     require(caller == deal.head.seller, "BOAK.RD: NOT seller");

    //     if (IInvestmentAgreement(ia).revokeDeal(seqOfDeal, hashKey))
    //         _gk.getBOI().terminateFile(ia);

    //     if (IInvestmentAgreement(ia).releaseDealSubject(seqOfDeal))
    //         _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
    // }

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external onlyDirectKeeper {

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "BOAK.TD: NOT seller"
        );

        IBookOfIA _boi = _gk.getBOI();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        uint8 state = _boi.getHeadOfFile(ia).state;

        if ((state < uint8(FilesRepo.StateOfFile.Proposed) &&
                block.timestamp >= _boi.terminateStartpoint(ia)) || 
            state == uint8(FilesRepo.StateOfFile.Rejected) ||
            (state == uint8(FilesRepo.StateOfFile.Approved) &&
                block.timestamp >= _ia.getHeadOfDeal(seqOfDeal).closingDeadline)
        ) {
            if (_ia.terminateDeal(seqOfDeal))
                _boi.terminateFile(ia);
            if (_ia.releaseDealSubject(seqOfDeal))
                _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);            
        } else revert("BOAK.TD: wrong state");
    }
}

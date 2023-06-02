// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOAKeeper.sol";

import "../common/access/AccessControl.sol";

contract BOAKeeper is IBOAKeeper, AccessControl {
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
        require(ISigPage(ia).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function createIA(uint version, address primeKeyOfCaller, uint caller) external onlyDirectKeeper {
        require(_gk.getROM().isMember(caller), "caller not MEMBER");
        
        bytes32 snOfDoc = bytes32((uint(uint8(IRegCenter.TypeOfDoc.InvestmentAgreement)) << 240) +
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

        _gk.getBOA().regFile(DocsRepo.codifyHead(doc.head), doc.body);
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

        ISigPage(ia).setTiming(false, signingDays + vr.shaExecDays + vr.reviewDays, closingDays);

        _gk.getBOA().circulateFile(ia, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyPartyOf(ia, caller) {
        require(
            _gk.getBOA().getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Circulated),
            "IA not in Circulated State"
        );

        _lockDealsOfParty(ia, caller);
        if (ISigPage(ia).signDoc(true, caller, sigHash) && 
            ISigPage(ia).established()) 
        {
            _gk.getBOA().establishFile(ia);
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
        uint closingDate,
        uint256 caller
    ) external onlyDirectKeeper {
        require(
            _gk.getBOA().getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Approved),
            "BOAK.PTC: wrong state"
        );

        DealsRepo.Head memory head = 
            IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);

        bool isST = (head.seqOfShare != 0);

        if (isST) require(caller == head.seller, "BOAK.PTC: not seller");
        else require(_gk.getBOD().isDirector(caller), "BOAK.PTC: not director");

        _vrAndSHACheck(ia, seqOfDeal, isST);

        IInvestmentAgreement(ia).clearDealCP(seqOfDeal, hashLock, closingDate);
    }

    function _vrAndSHACheck(address ia, uint256 seqOfDeal, bool isST) private view {
        uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();

        RulesParser.VotingRule memory vr = _gk.getSHA().getRule(typeOfIA).votingRuleParser();

        if (vr.amountRatio > 0 || vr.headRatio > 0) {
            if (vr.authority == 1)
                require(_gk.getBOG().isPassed(uint256(uint160(ia))), 
                    "BOAK.PTC:  Motion NOT passed");
            else if (vr.authority == 2)
                require(_gk.getBOD().isPassed(uint256(uint160(ia))), 
                    "BOAK.PTC:  Motion NOT passed");
            else if (vr.authority == 3)
                require(_gk.getBOG().isPassed(uint256(uint160(ia))) && 
                    _gk.getBOD().isPassed(uint256(uint160(ia))), 
                    "BOAK.PTC: motion not passed");
            else revert("BOAK.PTC: authority overflow");
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

        while (len > 0) {
            if (_gk.getSHA().hasTitle(uint8(terms[len - 1])))
                require(
                    _gk.getSHA().termIsExempted(uint8(terms[len - 1]), ia, seqOfDeal),
                    "BOAK.PTC: term not exempted"
                );
            len--;
        }
    }

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey,
        uint256 caller
    ) external onlyDirectKeeper {
        require(
            _gk.getBOA().getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Approved),
            "BOAK.CD: wrong state"
        );

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        //交易发起人为买方;
        require(
            deal.body.buyer == caller,
            "BOAKeeper.closeDeal: caller is NOT buyer"
        );

        //验证hashKey, 执行Deal
        if (IInvestmentAgreement(ia).closeDeal(seqOfDeal, hashKey))
            _gk.getBOA().execFile(ia);

        if (deal.head.seqOfShare > 0) {
            _shareTransfer(ia, seqOfDeal);
        } else issueNewShare(ia, seqOfDeal);
    }

    function _shareTransfer(address ia, uint256 seqOfDeal) private {
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _gk.getBOS().transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, deal.body.buyer, deal.head.priceOfPaid, deal.head.priceOfPar);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) public onlyDirectKeeper {
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
        DealsRepo.Head memory headOfDeal = 
            IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);

        require(
            caller == headOfDeal.seller,
                "BOAK.TTS: not sellerOfDeal"
        );

        _vrAndSHACheck(ia, seqOfDeal, true);

        _shareTransfer(ia, seqOfDeal);
    }

    function revokeDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        string memory hashKey
    ) external onlyDirectKeeper {
        require(_gk.getBOA().getHeadOfFile(ia).state == 
                    uint8(FilesRepo.StateOfFile.Approved),
                    "BOAK.RD: wrong State");

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(caller == deal.head.seller, "BOAK.RD: NOT seller");

        if (IInvestmentAgreement(ia).revokeDeal(seqOfDeal, hashKey))
            _gk.getBOA().execFile(ia);

        if (IInvestmentAgreement(ia).releaseDealSubject(seqOfDeal))
            _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
    }

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external onlyDirectKeeper {
        IBookOfIA _boa = _gk.getBOA();

        require(
            _boa.getHeadOfFile(ia).state < uint8(FilesRepo.StateOfFile.Executed),
            "BOAK.TD: wrong State"
        );

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "BOAK.TD: NOT seller"
        );

        if (IInvestmentAgreement(ia).terminateDeal(seqOfDeal))
        {
            _boa.revokeFile(ia);
            _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        }

    }


}

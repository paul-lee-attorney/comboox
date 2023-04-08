// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOAKeeper.sol";

import "../common/access/AccessControl.sol";

contract BOAKeeper is IBOAKeeper, AccessControl {

    using RulesParser for uint256;

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

    function createIA(uint256 snOfDoc, address primeKeyOfCaller, uint40 caller) external onlyDirectKeeper {
        require(_gk.getROM().isMember(caller), "caller not MEMBER");
        
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
        uint256 caller,
        bytes32 docUrl,
        bytes32 docHash
    ) external onlyDirectKeeper onlyPartyOf(ia, caller){
        require(IAccessControl(ia).finalized(), 
            "BOAK.CIA: IA not finalized");

        _gk.getBOA().circulateIA(ia, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyPartyOf(ia, caller) {
        IBookOfIA _boa = _gk.getBOA();
        
        require(
            _boa.getHeadOfFile(ia).state == uint8(IFilesFolder.StateOfFile.Circulated),
            "IA not in Circulated State"
        );

        _lockDealsOfParty(ia, caller);

        ISigPage(ia).signDoc(true, caller, sigHash);

        if (ISigPage(ia).established())
            _boa.setStateOfFile(ia, uint8(IFilesFolder.StateOfFile.Established));
    }

    function _lockDealsOfParty(address ia, uint256 caller) private {
        uint256[] memory list = IInvestmentAgreement(ia).getSNList();
        uint256 len = list.length;
        while (len > 0) {
            uint256 seq = list[len - 1];
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
        uint48 closingDate,
        uint256 caller
    ) external onlyDirectKeeper {
        require(
            _gk.getBOA().getHeadOfFile(ia).state == uint8(IFilesFolder.StateOfFile.Voted),
            "BOAK.PTC: wrong state"
        );

        DealsRepo.Head memory head = 
            IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);

        // uint16 seq = sn.seqOfDeal();

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
            _gk.getBOA().getHeadOfFile(ia).state == uint8(IFilesFolder.StateOfFile.Voted),
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
            _gk.getBOA().setStateOfFile(ia, uint8(IFilesFolder.StateOfFile.Executed));

        if (deal.head.seqOfShare > 0) {
            _shareTransfer(ia, seqOfDeal);
        } else issueNewShare(ia, seqOfDeal);
    }

    function _shareTransfer(address ia, uint256 seqOfDeal) private {
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _gk.getBOS().transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, deal.body.buyer, deal.head.priceOfPaid);
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
            price: deal.head.priceOfPaid
        });

        share.body = SharesRepo.Body({
            payInDeadline: uint48(block.timestamp) + 43200,
            paid: deal.body.paid,
            par: deal.body.par,
            cleanPaid: deal.body.paid,
            state: 0
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
        require(
            _gk.getBOA().getHeadOfFile(ia).state == uint8(IFilesFolder.StateOfFile.Voted),
            "BOAK.RD: wrong State"
        );

        // uint16 seq = sn.seqOfDeal();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "BOAK.RD: NOT seller"
        );

        if (IInvestmentAgreement(ia).revokeDeal(seqOfDeal, hashKey))
            _gk.getBOA().setStateOfFile(ia, uint8(IFilesFolder.StateOfFile.Executed));

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
            _boa.getHeadOfFile(ia).state < uint8(IFilesFolder.StateOfFile.Executed),
            "BOAK.TD: wrong State"
        );

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "BOAK.TD: NOT seller"
        );

        if (IInvestmentAgreement(ia).terminateDeal(seqOfDeal))
        {
            _boa.setStateOfFile(ia, uint8(IFilesFolder.StateOfFile.Executed));
            _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        }

    }


}

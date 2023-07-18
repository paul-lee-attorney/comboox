// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./ISHAKeeper.sol";

contract SHAKeeper is ISHAKeeper, AccessControl {
    using RulesParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier withinExecPeriod(address ia) {
        require(
            block.timestamp < _gk.getBOI().shaExecDeadline(ia),
            "missed review period"
        );
        _;
    }

    modifier afterExecPeriod(address ia) {
        require(
            block.timestamp >= _gk.getBOI().shaExecDeadline(ia),
            "still within review period"
        );
        _;
    }

    modifier beforeProposeDeadline(address ia) {
        require(
            block.timestamp < _gk.getBOI().terminateStartpoint(ia),
            "SHAK.md.BPD: missed proposal deadline"
        );
        _;
    }

    // modifier onlyEstablished(address ia) {
    //     require(
    //         _gk.getBOI().getHeadOfFile(ia).state ==
    //             uint8(FilesRepo.StateOfFile.Established),
    //         "IA not established"
    //     );
    //     _;
    // }

    // ####################
    // ##   SHA Rights   ##
    // ####################

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        uint256 seqOfDeal,
        bool dragAlong,
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper withinExecPeriod(ia) {

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);
        SharesRepo.Share memory share = _gk.getBOS().getShare(seqOfShare);

        require(deal.body.state != uint8(DealsRepo.StateOfDeal.Terminated), 
            "SHAK.EAR: deal terminated");
        
        IBookOfIA _boi = _gk.getBOI();

        _boi.createMockOfIA(ia);
        _checkAlongDeal(dragAlong, ia, deal, share, caller, _boi);

        _boi.execAlongRight(ia, dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);
    }

    function _checkAlongDeal(
        bool dragAlong,
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint256 caller,
        IBookOfIA _boi
    ) private {

        require(!_boi.isFRClaimer(ia, caller), 
            "SHAK.CAD: caller is frClaimer");

        require(!_boi.isFRClaimer(ia, share.head.shareholder), 
            "SHAK.CAD: shareholder is frClaimer");

        address term = dragAlong
            ? _gk.getSHA().getTerm(
                uint8(IRegCenter.TypeOfDoc.DragAlong)
            )
            : _gk.getSHA().getTerm(
                uint8(IRegCenter.TypeOfDoc.TagAlong)
            );

        require(ITerm(term).isTriggered(ia, deal), "SHAK.CAD: not triggered");

        require(
            IAlongs(term).isLinked(deal.head.seller, share.head.shareholder, _gk.getBOM()),
            "SHAK.CAD: NOT linked"
        );

        if (dragAlong) {
            require(caller == deal.head.seller, "SHAK.MAD: caller is not drager of DragAlong");
            require(IAlongs(term).priceCheck(ia, deal, share, caller),
                    "SHAK.CAD: price NOT satisfied");
        } else {
            require(caller == share.head.shareholder,
                    "SHAK.CAD: not shareholder of TagAlong");
            require(!ISigPage(ia).isBuyer(true, caller),
                    "SHAK.CAD: is Buyer of Deal");
        }
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper afterExecPeriod(ia) {

        require(
            block.timestamp < _gk.getBOI().terminateStartpoint(ia),
            "SHAK.acceptAlongDeal: missed proposal deadline"
        );

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "SHAK.AAD: not buyer");

        if (deal.body.state != uint8(DealsRepo.StateOfDeal.Terminated))
        {
            DTClaims.Claim memory claim = _gk.getBOI().getDTClaimForShare(ia, seqOfDeal, seqOfShare);
            SharesRepo.Share memory share = _gk.getBOS().getShare(seqOfShare);

            uint256 seqOfAlongDeal = _createAlongDeal(ia, claim, deal, share);

            ISigPage(ia).regSig(seqOfAlongDeal, claim.claimer, claim.sigDate, claim.sigHash);
            ISigPage(ia).regSig(seqOfAlongDeal, caller, uint48(block.timestamp), sigHash);
        }        

    }

    function _createAlongDeal(
        address ia,
        DTClaims.Claim memory claim,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share
    ) private returns (uint256 seqOfAlongDeal) {
        deal.head = DealsRepo.Head({
            typeOfDeal: claim.typeOfClaim == 0 ? 
                uint8(DealsRepo.TypeOfDeal.DragAlong) : 
                uint8(DealsRepo.TypeOfDeal.TagAlong),
            seqOfDeal: 0,
            preSeq: deal.head.seqOfDeal,
            classOfShare: share.head.class,
            seqOfShare: share.head.seqOfShare,
            seller: share.head.shareholder,
            priceOfPaid: deal.head.priceOfPaid,
            priceOfPar: deal.head.priceOfPar,
            closingDeadline: deal.head.closingDeadline,
            para: 0
        });

        deal.body = DealsRepo.Body({
            buyer: deal.body.buyer,
            groupOfBuyer: deal.body.groupOfBuyer,
            paid: claim.paid,
            par: claim.par,
            state: uint8(DealsRepo.StateOfDeal.Locked),
            para: 0,
            argu: 0,
            flag: false
        });

        seqOfAlongDeal = IInvestmentAgreement(ia).regDeal(deal);

        IInvestmentAgreement(ia).lockDealSubject(seqOfAlongDeal);
        _gk.getBOS().decreaseCleanPaid(share.head.seqOfShare, claim.paid);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper withinExecPeriod(ia) {

        SharesRepo.Share memory share = _gk.getBOS().getShare(seqOfShare);

        require(caller == share.head.shareholder,
                "SHAK.EAD: not shareholder");

        require(!ISigPage(ia).isInitSigner(caller),
                "SHAK.EAD: is InitSigner");

        address ad = _gk.getSHA().getTerm(
            uint8(IRegCenter.TypeOfDoc.AntiDilution)
        );

        uint64 giftPaid = IAntiDilution(ad).getGiftPaid(ia, seqOfDeal, seqOfShare);
        uint256[] memory obligors = IAntiDilution(ad).getObligorsOfAD(share.head.class);

        _createGiftDeals(ia, seqOfDeal, giftPaid, obligors, caller, sigHash);
    }

    function _createGiftDeals(
        address ia,
        uint256 seqOfDeal,
        uint giftPaid,
        uint256[] memory obligors,
        uint256 caller,
        bytes32 sigHash
    ) private {
        for (uint256 i = 0; i < obligors.length; i++) {
            bytes32[] memory sharesInHand = _gk.getBOM().sharesInHand(obligors[i]);

            for (uint256 j = 0; j < sharesInHand.length; j++) {
                (uint256 seqOfGiftDeal, uint64 result) = _createGift(
                    ia,
                    seqOfDeal,
                    uint(sharesInHand[j]) >> 224,
                    giftPaid
                );

                ISigPage(ia).regSig(
                    seqOfGiftDeal,
                    caller,
                    uint48(block.timestamp),
                    sigHash
                );

                if (result == 0) break;
                giftPaid = result;
            }
            if (giftPaid == 0) break;
        }
        require(giftPaid == 0, "SHAK.CGD: insufficient paid amount");
    }

    function _createGift(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint giftPaid
    ) private returns (uint256 seqOfGiftDeal, uint64 result) {
        
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);
        SharesRepo.Share memory share = _gk.getBOS().getShare(seqOfShare);

        uint64 lockAmount;

        if (share.body.cleanPaid > 0) {

            lockAmount = (share.body.cleanPaid < giftPaid) ? share.body.cleanPaid : uint64(giftPaid);

            DealsRepo.Deal memory giftDeal;

            giftDeal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.FreeGift);
            giftDeal.head.preSeq = uint16(seqOfDeal);
            giftDeal.head.classOfShare = share.head.class;

            giftDeal.head.seqOfShare = share.head.seqOfShare;
            giftDeal.head.seller = share.head.shareholder;
            giftDeal.head.closingDeadline = deal.head.closingDeadline;

            giftDeal.body.buyer = deal.body.buyer;
            giftDeal.body.groupOfBuyer = deal.body.groupOfBuyer; 
            giftDeal.body.paid = lockAmount;
            giftDeal.body.par = lockAmount;
            giftDeal.body.state = uint8(DealsRepo.StateOfDeal.Locked);
            
            seqOfGiftDeal = IInvestmentAgreement(ia).regDeal(giftDeal);

            _gk.getBOS().decreaseCleanPaid(share.head.seqOfShare, lockAmount);
        }
        result = uint64(giftPaid) - lockAmount;
    }

    function takeGiftShares(
        address ia,
        uint256 seqOfDeal,
        uint caller
    ) external onlyDirectKeeper {
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "caller is not buyer");

        if (IInvestmentAgreement(ia).takeGift(seqOfDeal))
            _gk.getBOI().setStateOfFile(ia, uint8(FilesRepo.StateOfFile.Closed));

        _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _gk.getBOS().transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, deal.body.buyer, 0, 0);
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper withinExecPeriod(ia) {

        require(!ISigPage(ia).isSeller(true, caller), 
            "SHAK.EFR: frClaimer is seller");

        DealsRepo.Head memory headOfDeal = IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);
        
        RulesParser.FirstRefusalRule memory rule = _gk.getSHA().getRule(seqOfFRRule).firstRefusalRuleParser();

        require(rule.typeOfDeal == headOfDeal.typeOfDeal, 
            "SHAK.EFR: rule and deal are not same type");

        require(
            (rule.membersEqual && _gk.getBOM().isMember(caller)) || 
            rule.rightholders[seqOfRightholder] == caller,
            "SHAK.EFR: caller NOT rightholder"
        );

        if (_gk.getBOI().execFirstRefusalRight(ia, seqOfDeal, caller, sigHash))
            IInvestmentAgreement(ia).terminateDeal(seqOfDeal); 
    }

    function acceptFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper afterExecPeriod(ia) {

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        if (deal.head.typeOfDeal == uint8(DealsRepo.TypeOfDeal.CapitalIncrease)
        ) require( _gk.getBOM().groupRep(caller) == _gk.getBOM().controllor(), 
            "SHAK.AFR: not controller");
        else require(caller == deal.head.seller, "SHAK.AFR: not sellerOfDeal");

        FRClaims.Claim[] memory cls = _gk.getBOI().acceptFirstRefusalClaims(ia, seqOfDeal);

        uint256 len = cls.length;

        while (len > 0) {
            _createFRDeal(ia, deal, cls[len-1]);
            len--;
        }

        ISigPage(ia).signDoc(false, caller, sigHash);
    }

    function _createFRDeal(
        address ia,
        DealsRepo.Deal memory deal,
        FRClaims.Claim memory cl
    ) private {

        if (deal.head.seqOfShare != 0) {
            deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.FirstRefusal);
        } else  deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.PreEmptive);
        
        deal.head.preSeq = deal.head.seqOfDeal;

        
        deal.body.buyer = cl.rightholder;
        deal.body.groupOfBuyer = _gk.getBOM().groupRep(cl.rightholder);
        deal.body.paid = (deal.body.paid * cl.ratio) / 10000;
        deal.body.par = (deal.body.par * cl.ratio) / 10000;
        deal.body.state = uint8(DealsRepo.StateOfDeal.Locked);

        IInvestmentAgreement(ia).lockDealSubject(IInvestmentAgreement(ia).regDeal(deal));

        ISigPage(ia).signDoc(false, cl.rightholder, cl.sigHash);
    }
}

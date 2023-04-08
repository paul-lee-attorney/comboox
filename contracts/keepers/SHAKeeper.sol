// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

// import "../common/ruting/BOASetting.sol";
// import "../common/ruting/BOHSetting.sol";
// import "../common/ruting/BOSSetting.sol";
// import "../common/ruting/ROMSetting.sol";

import "./ISHAKeeper.sol";

contract SHAKeeper is ISHAKeeper, AccessControl {
    using RulesParser for uint256;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier withinExecPeriod(address ia) {
        require(
            _gk.getBOA().getHeadOfFile(ia).shaExecDeadline > block.timestamp,
            "missed review period"
        );
        _;
    }

    modifier afterExecPeriod(address ia) {
        require(
            _gk.getBOA().getHeadOfFile(ia).shaExecDeadline <= block.timestamp,
            "still within review period"
        );
        _;
    }

    modifier beforeProposeDeadline(address ia) {
        require(
            _gk.getBOA().getHeadOfFile(ia).proposeDeadline >= block.timestamp,
            "still within review period"
        );
        _;
    }

    modifier onlyEstablished(address ia) {
        require(
            _gk.getBOA().getHeadOfFile(ia).state ==
                uint8(IFilesFolder.StateOfFile.Established),
            "IA not established"
        );
        _;
    }

    // ####################
    // ##   SHA Rights   ##
    // ####################

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        uint256 seqOfDeal,
        bool dragAlong,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper withinExecPeriod(ia) {

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);
        SharesRepo.Share memory share = _gk.getBOS().getShare(seqOfShare);

        require(deal.body.state != uint8(DealsRepo.StateOfDeal.Terminated), 
            "SHAK.EAR: deal terminated");

        _gk.getBOA().createMockOfIA(ia);
        _checkAlongDeal(dragAlong, ia, deal, share, caller);

        _gk.getBOA().execAlongRight(ia, dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);
    }

    function _checkAlongDeal(
        bool dragAlong,
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint256 caller
    ) private {

        require(!_gk.getBOA().isFRClaimer(ia, caller), 
            "SHAK.CAD: caller is frClaimer");

        require(!_gk.getBOA().isFRClaimer(ia, share.head.shareholder), 
            "SHAK.CAD: shareholder is frClaimer");

        address term = dragAlong
            ? _gk.getSHA().getTerm(
                uint8(IRegCenter.TypeOfDoc.DragAlong)
            )
            : _gk.getSHA().getTerm(
                uint8(IRegCenter.TypeOfDoc.TagAlong)
            );

        require(ITerm(term).isTriggered(ia, deal), "not triggered");

        require(
            IAlongs(term).isLinked(deal.head.seller, share.head.shareholder),
            "drager and target shareholder NOT linked"
        );

        if (dragAlong) {
            require(caller == deal.head.seller, "SHAK.MAD: caller is not drager of DragAlong");
            require(IAlongs(term).priceCheck(ia, deal, share, caller),
                    "SHAK.MAD: price NOT satisfied");
        } else {
            require(caller == share.head.shareholder,
                    "SHAK.MAD: caller is not shareholder of TagAlong");
            require(!ISigPage(ia).isBuyer(true, caller),
                    "SHAK.MAD: caller is Buyer of Deal");
        }
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper afterExecPeriod(ia) beforeProposeDeadline(ia) {

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "SHAK.AAD: not buyer");


        if (deal.body.state != uint8(DealsRepo.StateOfDeal.Terminated))
        {
            DTClaims.Claim memory claim = _gk.getBOA().getDTClaimForShare(ia, seqOfDeal, seqOfShare);
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
            closingDate: deal.head.closingDate
            // state: uint8(DealsRepo.StateOfDeal.Locked)
        });

        deal.body = DealsRepo.Body({
            buyer: deal.body.buyer,
            groupOfBuyer: deal.body.groupOfBuyer,
            paid: claim.paid,
            par: claim.par,
            // closingDate: deal.body.closingDate,
            state: uint8(DealsRepo.StateOfDeal.Locked)
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
    ) external onlyDirectKeeper onlyEstablished(ia) withinExecPeriod(ia) {

        SharesRepo.Share memory share = _gk.getBOS().getShare(seqOfShare);

        require(caller == share.head.shareholder,
                "SHAK.EAD: caller is not shareholder");

        require(!ISigPage(ia).isSigner(caller),
                "SHAK.EAD: caller is an InitSigner");

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
        uint64 giftPaid,
        uint256[] memory obligors,
        uint256 caller,
        bytes32 sigHash
    ) private {
        for (uint256 i = 0; i < obligors.length; i++) {
            uint256[] memory sharesInHand = _gk.getROM().sharesInHand(obligors[i]);

            for (uint256 j = 0; j < sharesInHand.length; j++) {
                (uint256 seqOfGiftDeal, uint64 result) = _createGift(
                    ia,
                    seqOfDeal,
                    sharesInHand[j],
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
        require(giftPaid == 0, "obligors have not enough parValue");
    }

    function _createGift(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint64 giftPaid
    ) private returns (uint256 seqOfGiftDeal, uint64 result) {
        
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);
        SharesRepo.Share memory share = _gk.getBOS().getShare(seqOfShare);

        uint64 lockAmount;

        if (share.body.cleanPaid > 0) {

            lockAmount = (share.body.cleanPaid < giftPaid) ? share.body.cleanPaid : giftPaid;

            DealsRepo.Deal memory giftDeal = DealsRepo.Deal({
                head: DealsRepo.Head({
                    typeOfDeal: uint8(DealsRepo.TypeOfDeal.FreeGift),
                    seqOfDeal: 0,
                    preSeq: uint16(seqOfDeal),
                    classOfShare: share.head.class,
                    seqOfShare: share.head.seqOfShare,
                    seller: share.head.shareholder,
                    priceOfPaid: 0,
                    priceOfPar: 0,
                    closingDate: deal.head.closingDate
                }),
                body: DealsRepo.Body({
                    buyer: deal.body.buyer,
                    groupOfBuyer: deal.body.groupOfBuyer,
                    paid: lockAmount,
                    par: lockAmount,
                    state: uint8(DealsRepo.StateOfDeal.Locked)
                }),
                hashLock: bytes32(0)
            });
            
            seqOfGiftDeal = IInvestmentAgreement(ia).regDeal(giftDeal);

            _gk.getBOS().decreaseCleanPaid(share.head.seqOfShare, lockAmount);
        }
        result = giftPaid - lockAmount;
    }

    function takeGiftShares(
        address ia,
        uint256 seqOfDeal,
        uint40 caller
    ) external onlyDirectKeeper {
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "caller is not buyer");

        if (IInvestmentAgreement(ia).takeGift(seqOfDeal))
            _gk.getBOA().setStateOfFile(ia, uint8(IFilesFolder.StateOfFile.Executed));

        _gk.getBOS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _gk.getBOS().transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, deal.body.buyer, 0);
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
            (rule.membersEqual && _gk.getROM().isMember(caller)) || 
            rule.rightholders[seqOfRightholder] == caller,
            "SHAK.EFR: caller NOT rightholder"
        );

        if (_gk.getBOA().execFirstRefusalRight(ia, seqOfDeal, caller, sigHash))
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
        ) require( _gk.getROM().groupRep(caller) == _gk.getROM().controllor(), 
            "SHAK.AFR: not controller");
        else require(caller == deal.head.seller, "SHAK.AFR: not sellerOfDeal");

        FRClaims.Claim[] memory cls = _gk.getBOA().acceptFirstRefusalClaims(ia, seqOfDeal);

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

        deal.body = DealsRepo.Body({
            buyer: cl.rightholder,
            groupOfBuyer: _gk.getROM().groupRep(cl.rightholder),
            paid: (deal.body.paid * cl.ratio) / 10000,
            par: (deal.body.par * cl.ratio) / 10000,
            state: uint8(DealsRepo.StateOfDeal.Locked)
        });

        IInvestmentAgreement(ia).lockDealSubject(IInvestmentAgreement(ia).regDeal(deal));

        ISigPage(ia).signDoc(false, cl.rightholder, cl.sigHash);
    }
}

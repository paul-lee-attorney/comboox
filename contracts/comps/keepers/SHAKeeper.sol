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
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfAgreements _roa = _gk.getROA();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);
        SharesRepo.Share memory share = _gk.getROS().getShare(seqOfShare);

        require(deal.body.state == uint8(DealsRepo.StateOfDeal.Locked), 
            "SHAK.execAlongs: state not Locked");

        require(!_roa.isFRClaimer(ia, caller), 
            "SHAK.execAlongs: caller is frClaimer");

        require(!_roa.isFRClaimer(ia, share.head.shareholder), 
            "SHAK.execAlongs: shareholder is frClaimer");

        _roa.createMockOfIA(ia);

        _checkAlongDeal(dragAlong, ia, deal, share, caller, paid, par);

        _roa.execAlongRight(ia, dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);
    }

    function _checkAlongDeal(
        bool dragAlong,
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint256 caller,
        uint paid,
        uint par
    ) private view {
        IGeneralKeeper _gk = _getGK();
 
        IAlongs _al = dragAlong
            ? IAlongs(_gk.getSHA().
                getTerm(uint8(IShareholdersAgreement.TitleOfTerm.DragAlong)))
            : IAlongs(_gk.getSHA().
                getTerm(uint8(IShareholdersAgreement.TitleOfTerm.TagAlong)));

        require(
            _al.isFollower(deal.head.seller, share.head.shareholder),
            "SHAK.checkAlongs: NOT linked"
        );

        require(_al.isTriggered(ia, deal), "SHAK.checkAlongs: not triggered");

        if (dragAlong) {
            require(caller == deal.head.seller, "SHAK.checkAlongs: not drager");
        } else {
            require(caller == share.head.shareholder,
                "SHAK.checkAlongs: not follower");
            require(!ISigPage(ia).isBuyer(true, caller),
                "SHAK.checkAlongs: caller is Buyer");
        }

        if(_al.getLinkRule(deal.head.seller).proRata) {
            IRegisterOfMembers _rom = _getGK().getROM();
            
            if (_rom.basedOnPar())
                require ( par <= 
                deal.body.par * share.body.par / _rom.votesOfGroup(deal.head.seller), 
                "SHAKeeper.checkAlong: par overflow");
            else require ( paid <=
                deal.body.paid * share.body.paid / _rom.votesOfGroup(deal.head.seller),
                "SHAKeeper.checkAlong: paid overflow");            
        }
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfAgreements _roa = _gk.getROA();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "SHAK.AAD: not buyer");

        DTClaims.Claim[] memory claims = _roa.acceptAlongClaims(ia, seqOfDeal);

        uint len = claims.length;
        while(len > 0) {
            DTClaims.Claim memory claim = claims[len - 1];

            SharesRepo.Share memory share = 
                _gk.getROS().getShare(claim.seqOfShare);

            _createAlongDeal(_ia, claim, deal, share);

            _ia.regSig(deal.head.seller, claim.sigDate, claim.sigHash);

            len--;
        }

        _ia.signDoc(false, caller, sigHash);

    }

    function _createAlongDeal(
        IInvestmentAgreement _ia,
        DTClaims.Claim memory claim,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share
    ) private {
        deal.head = DealsRepo.Head({
            typeOfDeal: claim.typeOfClaim == 0 
                ? uint8(DealsRepo.TypeOfDeal.DragAlong) 
                : uint8(DealsRepo.TypeOfDeal.TagAlong),
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

        _ia.regDeal(deal);

        _getGK().getROS().decreaseCleanPaid(share.head.seqOfShare, claim.paid);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfShares _ros = _gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        SharesRepo.Share memory tShare = _ros.getShare(seqOfShare);

        require(caller == tShare.head.shareholder, "SHAK.execAD: not shareholder");
        require(!_ia.isInitSigner(caller), "SHAK.execAD: is InitSigner");

        require(_gk.getROA().getHeadOfFile(ia).state == 
            uint8(FilesRepo.StateOfFile.Circulated), "SHAK.execAD: wrong file state");

        IRegisterOfMembers _rom = _gk.getROM();

        IAntiDilution _ad = IAntiDilution(_gk.getSHA().getTerm(
            uint8(IShareholdersAgreement.TitleOfTerm.AntiDilution)
        ));

        uint64 giftPaid = _ad.getGiftPaid(ia, seqOfDeal, tShare.head.seqOfShare);
        uint256[] memory obligors = _ad.getObligorsOfAD(tShare.head.class);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);
        
        deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.FreeGift);
        deal.head.preSeq = deal.head.seqOfDeal;
        deal.head.seqOfDeal = 0;
        deal.head.priceOfPaid = 0;
        deal.head.priceOfPar = 0;

        deal.body.buyer = tShare.head.shareholder;
        deal.body.groupOfBuyer = _rom.groupRep(tShare.head.shareholder);
        deal.body.state = uint8(DealsRepo.StateOfDeal.Locked);

        for (uint256 i = 0; i < obligors.length; i++) {
            bytes32[] memory sharesInHand = _rom.sharesInHand(obligors[i]);

            for (uint256 j = 0; j < sharesInHand.length; j++) {

                giftPaid = _createGift(
                    _ia,
                    deal,
                    uint(sharesInHand[j]) >> 224,
                    giftPaid,
                    _ros
                );

                if (giftPaid == 0) break;
            }
            if (giftPaid == 0) break;
        }

        _ia.signDoc(false, deal.body.buyer, sigHash);
    }

    function _createGift(
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        uint256 seqOfShare,
        uint64 giftPaid,
        IRegisterOfShares _ros
    ) private returns (uint64 result) {        
        SharesRepo.Share memory cShare = _ros.getShare(seqOfShare);

        uint64 lockAmount;

        if (cShare.body.cleanPaid > 0) {

            lockAmount = (cShare.body.cleanPaid < giftPaid) ? cShare.body.cleanPaid : giftPaid;

            deal.head.classOfShare = cShare.head.class;
            deal.head.seqOfShare = cShare.head.seqOfShare;
            deal.head.seller = cShare.head.shareholder;

            deal.body.paid = lockAmount;
            deal.body.par = lockAmount;
            
            _ia.regDeal(deal);
            _ia.regSig(deal.head.seller, uint48(block.timestamp), bytes32(uint(deal.head.seqOfShare)));

            _ros.decreaseCleanPaid(cShare.head.seqOfShare, lockAmount);
        }
        result = giftPaid - lockAmount;
    }

    function takeGiftShares(
        address ia,
        uint256 seqOfDeal,
        uint caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfShares _ros = _gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "caller is not buyer");

        if (_ia.takeGift(seqOfDeal))
            _gk.getROA().setStateOfFile(ia, uint8(FilesRepo.StateOfFile.Closed));

        _ros.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _ros.transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, deal.body.buyer, 0, 0);
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(!_ia.isSeller(true, caller), 
            "SHAK.EFR: frClaimer is seller");

        DealsRepo.Head memory headOfDeal = 
            _ia.getHeadOfDeal(seqOfDeal);
        
        RulesParser.FirstRefusalRule memory rule = 
            _gk.getSHA().getRule(seqOfFRRule).firstRefusalRuleParser();

        require(rule.typeOfDeal == headOfDeal.typeOfDeal, 
            "SHAK.EFR: rule and deal are not same type");

        require(
            (rule.membersEqual && _gk.getROM().isMember(caller)) || 
            rule.rightholders[seqOfRightholder] == caller,
            "SHAK.EFR: caller NOT rightholder"
        );

        _gk.getROA().claimFirstRefusal(ia, seqOfDeal, caller, sigHash);

        _ia.terminateDeal(seqOfDeal); 
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfMembers _rom = _gk.getROM();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        (,, bytes32 sigHashOfSeller) = _ia.getSigOfParty(true, deal.head.seller);

        require(_rom.isMember(caller), "SHAKeeper.computeFR: not member");

        FRClaims.Claim[] memory cls = 
            _gk.getROA().computeFirstRefusal(ia, seqOfDeal);

        uint256 len = cls.length;

        while (len > 0) {
            _createFRDeal(_ia, deal, cls[len-1], _rom);
            len--;
        }

        _ia.signDoc(false, deal.head.seller, sigHashOfSeller);
    }

    function _createFRDeal(
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        FRClaims.Claim memory cl,
        IRegisterOfMembers _rom
    ) private {
        if (deal.head.seqOfShare != 0) {
            deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.FirstRefusal);
        } else  deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.PreEmptive);
        
        deal.head.preSeq = deal.head.seqOfDeal;
        
        deal.body.buyer = cl.claimer;
        deal.body.groupOfBuyer = _rom.groupRep(cl.claimer);
        deal.body.paid = (deal.body.paid * cl.ratio) / 10000;
        deal.body.par = (deal.body.par * cl.ratio) / 10000;
        deal.body.state = uint8(DealsRepo.StateOfDeal.Locked);

        _ia.regDeal(deal);
        _ia.regSig(cl.claimer, cl.sigDate, cl.sigHash);
    }
}
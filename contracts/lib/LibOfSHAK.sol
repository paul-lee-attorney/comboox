// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "./RulesParser.sol";
import "./InterfacesHub.sol";
import "./DTClaims.sol";

library LibOfSHAK {
    using RulesParser for bytes32;
    using InterfacesHub for address;
    using DTClaims for bytes32;

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        uint caller,
        address ia,
        bytes32 snOfClaim,
        bytes32 sigHash
    ) external {

        DTClaims.Head memory head = snOfClaim.snParser();
        
        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(head.seqOfDeal);
        SharesRepo.Share memory share = address(this).getROS().getShare(head.seqOfShare);

        _checkCaller(head.dragAlong, ia, deal, share, caller);

        _checkFRClaimAndMockIA(ia, caller, share);

        IAlongs _al = _getAlongTerm(head.dragAlong);

        _isTriggered(_al, ia, deal, share);

        _checkAmt(_al, deal, share, head.paid, head.par);

        head.caller = uint40(caller);
        snOfClaim = DTClaims.codifyHead(head);

        _execAlongRight(ia, snOfClaim, sigHash);
    }

    function _checkCaller(
        bool dragAlong,
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint caller
    ) private view {
        if (dragAlong) {
            require(caller == deal.head.seller, "SHAK.checkAlongs: not drager");
        } else {
            require(caller == share.head.shareholder,
                "SHAK.checkAlongs: not follower");
            require(!ISigPage(ia).isBuyer(true, caller),
                "SHAK.checkAlongs: caller is Buyer");
        }
    }

    function _checkFRClaimAndMockIA(
        address ia,
        uint256 caller,
        SharesRepo.Share memory share
    ) private {
        IRegisterOfAgreements _roa = address(this).getROA();        
        require(!_roa.isFRClaimer(ia, caller), 
            "SHAK.execAlongs: caller is frClaimer");
        require(!_roa.isFRClaimer(ia, share.head.shareholder), 
            "SHAK.execAlongs: shareholder is frClaimer");
        _roa.createMockOfIA(ia);            
    }

    function _getAlongTerm(
        bool dragAlong
    ) private view returns(IAlongs) {
        address gk = address(this);
        return dragAlong
            ? IAlongs(gk.getSHA().
                getTerm(uint8(IShareholdersAgreement.TitleOfTerm.DragAlong)))
            : IAlongs(gk.getSHA().
                getTerm(uint8(IShareholdersAgreement.TitleOfTerm.TagAlong)));
    }

    function _isTriggered(
        IAlongs _al,
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share
    ) private view {
        require(deal.body.state == uint8(DealsRepo.StateOfDeal.Locked), 
            "SHAK.execAlongs: state not Locked");
        require(
            _al.isFollower(deal.head.seller, share.head.shareholder),
            "SHAK.checkAlongs: NOT linked"
        );
        require(_al.isTriggered(ia, deal), "SHAK.checkAlongs: not triggered");
    }

    function _checkAmt(
        IAlongs _al,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint paid,
        uint par
    ) private view {
        address gk = address(this);
        uint subjectVW = gk.getROS().getShare(deal.head.seqOfShare).head.votingWeight;

        if(_al.getLinkRule(deal.head.seller).proRata) {
            IRegisterOfMembers _rom = gk.getROM();
            
            if (_rom.basedOnPar())
                require ( par <= 
                subjectVW * deal.body.par * share.body.par / _rom.votesOfGroup(deal.head.seller) / 100 , 
                "SHAKeeper.checkAlong: par overflow");
            else require ( paid <=
                 subjectVW * deal.body.paid * share.body.paid / _rom.votesOfGroup(deal.head.seller) / 100,
                "SHAKeeper.checkAlong: paid overflow");
        }
    }

    function _execAlongRight(
        address ia,
        bytes32 snOfClaim,
        bytes32 sigHash
    ) private {
        IRegisterOfAgreements _roa = address(this).getROA();
        _roa.execAlongRight(ia, snOfClaim, sigHash);
    }

    function acceptAlongDeal(
        uint caller,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external  {
        
        address gk = address(this);
        IRegisterOfAgreements _roa = gk.getROA();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "SHAK.AAD: not buyer");

        DTClaims.Claim[] memory claims = _roa.acceptAlongClaims(ia, seqOfDeal);

        uint len = claims.length;
        while(len > 0) {
            DTClaims.Claim memory claim = claims[len - 1];

            SharesRepo.Share memory share = 
                gk.getROS().getShare(claim.seqOfShare);

            _createAlongDeal(gk, _ia, claim, deal, share);

            _ia.regSig(share.head.shareholder, claim.sigDate, claim.sigHash);
            _ia.regSig(caller, uint48(block.timestamp), sigHash);

            len--;
        }

    }

    function _createAlongDeal(
        address gk,
        IInvestmentAgreement _ia,
        DTClaims.Claim memory claim,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share
    ) private {
        DealsRepo.Deal memory aDeal;
        aDeal.head = DealsRepo.Head({
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
            votingWeight: share.head.votingWeight
        });

        aDeal.body = DealsRepo.Body({
            buyer: deal.body.buyer,
            groupOfBuyer: deal.body.groupOfBuyer,
            paid: claim.paid,
            par: claim.par,
            state: uint8(DealsRepo.StateOfDeal.Locked),
            para: 0,
            distrWeight: deal.body.distrWeight,
            flag: false
        });

        _ia.regDeal(aDeal);

        gk.getROS().decreaseCleanPaid(share.head.seqOfShare, claim.paid);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        uint caller,
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external  {        
        address gk = address(this);

        IRegisterOfShares _ros = gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        SharesRepo.Share memory tShare = _ros.getShare(seqOfShare);

        require(caller == tShare.head.shareholder, "SHAK.execAD: not shareholder");
        require(!_ia.isInitSigner(caller), "SHAK.execAD: is InitSigner");

        require(gk.getROA().getHeadOfFile(ia).state == 
            uint8(FilesRepo.StateOfFile.Circulated), "SHAK.execAD: wrong file state");

        _ia.requestPriceDiff(seqOfDeal, seqOfShare);

        IAntiDilution _ad = IAntiDilution(gk.getSHA().getTerm(
            uint8(IShareholdersAgreement.TitleOfTerm.AntiDilution)
        ));

        uint64 giftPaid = _ad.getGiftPaid(ia, seqOfDeal, tShare.head.seqOfShare);
        uint256[] memory obligors = _ad.getObligorsOfAD(tShare.head.class);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);
        
        deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.FreeGift);
        deal.head.preSeq = deal.head.seqOfDeal;
        deal.head.seqOfDeal = 0;
        deal.head.priceOfPar = tShare.head.seqOfShare;

        deal.body.buyer = tShare.head.shareholder;
        deal.body.state = uint8(DealsRepo.StateOfDeal.Locked);

        _deductShares(gk, obligors, _ia, deal, giftPaid, _ros, sigHash);

    }

    function _deductShares(
        address gk,
        uint[] memory obligors,
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        uint64 giftPaid,
        IRegisterOfShares _ros,
        bytes32 sigHash
    ) private {

        IRegisterOfMembers _rom = gk.getROM();

        deal.body.groupOfBuyer = _rom.groupRep(deal.body.buyer);

        uint i = obligors.length;

        while (i > 0) {
            
            uint[] memory sharesInHand = _rom.sharesInHand(obligors[i - 1]);

            uint j = sharesInHand.length;

            while (j > 0) {

                if (!_ros.notLocked(sharesInHand[j-1], deal.head.closingDeadline)) {
                    j--;
                    continue;
                }

                giftPaid = _createGift(
                    _ia,
                    deal,
                    sharesInHand[j - 1],
                    giftPaid,
                    _ros,
                    sigHash
                );

                if (giftPaid == 0) break;
                j--;
            }

            if (giftPaid == 0) break;
            i--;
        }
    }


    function _createGift(
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        uint256 seqOfShare,
        uint64 giftPaid,
        IRegisterOfShares _ros,
        bytes32 sigHash
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
            _ia.regSig(deal.body.buyer, uint48(block.timestamp), sigHash);

            _ros.decreaseCleanPaid(cShare.head.seqOfShare, lockAmount);
        }
        result = giftPaid - lockAmount;
    }

    function takeGiftShares(
        uint caller,
        address ia,
        uint256 seqOfDeal
    ) external {        
        address gk = address(this);
        
        IRegisterOfShares _ros = gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "caller is not buyer");
        require(_ros.notLocked(deal.head.seqOfShare, block.timestamp),
            "SHAK.takeGift: share locked");

        if (_ia.takeGift(seqOfDeal))
            gk.getROA().setStateOfFile(ia, uint8(FilesRepo.StateOfFile.Closed));

        _ros.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _ros.transferShare(
            deal.head.seqOfShare, 
            deal.body.paid, 
            deal.body.par, 
            deal.body.buyer, 
            deal.head.priceOfPaid, 
            deal.head.priceOfPaid
        );

        SharesRepo.Share memory tShare = _ros.getShare(deal.head.priceOfPar);
        if (tShare.head.priceOfPaid > deal.head.priceOfPaid)
            _ros.updatePriceOfPaid(tShare.head.seqOfShare, deal.head.priceOfPaid);
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        uint caller,
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external  {        
        address gk = address(this);
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(!_ia.isSeller(true, caller), 
            "SHAK.EFR: frClaimer is seller");

        DealsRepo.Head memory headOfDeal = 
            _ia.getDeal(seqOfDeal).head;
        
        RulesParser.FirstRefusalRule memory rule = 
            gk.getSHA().getRule(seqOfFRRule).firstRefusalRuleParser();

        require(rule.typeOfDeal == headOfDeal.typeOfDeal, 
            "SHAK.EFR: rule and deal are not same type");

        require(
            (rule.membersEqual && gk.getROM().isMember(caller)) || 
            rule.rightholders[seqOfRightholder] == caller,
            "SHAK.EFR: caller NOT rightholder"
        );

        gk.getROA().claimFirstRefusal(ia, seqOfDeal, caller, sigHash);

        if (_ia.getDeal(seqOfDeal).body.state != 
            uint8(DealsRepo.StateOfDeal.Terminated))
                _ia.terminateDeal(seqOfDeal); 
    }

    function computeFirstRefusal(
        uint caller,
        address ia,
        uint256 seqOfDeal
    ) external {
        address gk = address(this);

        IRegisterOfMembers _rom = gk.getROM();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        (,, bytes32 sigHashOfSeller) = _ia.getSigOfParty(true, deal.head.seller);

        require(_rom.isMember(caller), "SHAKeeper.computeFR: not member");

        if (deal.head.seqOfShare != 0) {
            deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.FirstRefusal);
        } else  deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.PreEmptive);

        deal.head.preSeq = deal.head.seqOfDeal;
        deal.body.state = uint8(DealsRepo.StateOfDeal.Locked);

        FRClaims.Claim[] memory cls = 
            gk.getROA().computeFirstRefusal(ia, seqOfDeal);

        uint256 len = cls.length;
        DealsRepo.Deal memory frDeal;
        uint paid = deal.body.paid;
        uint par = deal.body.par;
        while (len > 0) {
            frDeal = _createFRDeal(deal, cls[len-1], _rom);
            if (len > 1) {
                paid -= frDeal.body.paid;
                par -= frDeal.body.par;
            } else {
                frDeal.body.paid = uint64(paid);
                frDeal.body.par = uint64(par);
            }
            _regFRDeal(_ia, frDeal, cls[len-1], sigHashOfSeller);
            len--;
        }
        
    }

    function _createFRDeal(
        DealsRepo.Deal memory deal,
        FRClaims.Claim memory cl,
        IRegisterOfMembers _rom
    ) private view returns(DealsRepo.Deal memory frDeal) {

        frDeal = deal;

        frDeal.body.buyer = cl.claimer;
        frDeal.body.groupOfBuyer = _rom.groupRep(cl.claimer);
        frDeal.body.paid = (deal.body.paid * cl.ratio) / 10000;
        frDeal.body.par = (deal.body.par * cl.ratio) / 10000;
    }

    function _regFRDeal(
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        FRClaims.Claim memory cl,
        bytes32 sigHashOfSeller
    ) private {
        _ia.regDeal(deal);
        _ia.regSig(cl.claimer, cl.sigDate, cl.sigHash);

        if (deal.head.seller > 0)
            _ia.regSig(deal.head.seller, uint48(block.timestamp), sigHashOfSeller);
    }
}

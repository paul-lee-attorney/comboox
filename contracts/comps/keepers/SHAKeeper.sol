// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

pragma solidity ^0.8.8;

import "../common/access/RoyaltyCharge.sol";

import "./ISHAKeeper.sol";

contract SHAKeeper is ISHAKeeper, RoyaltyCharge {
    using RulesParser for bytes32;

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        uint256 seqOfDeal,
        bool dragAlong,
        uint256 seqOfShare,
        uint paid,
        uint par,
        address msgSender,
        bytes32 sigHash
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 88000);
        
        IRegisterOfAgreements _roa = _gk.getROA();
        IRegisterOfShares _ros = _gk.getROS();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);
        SharesRepo.Share memory share = _ros.getShare(seqOfShare);

        require(deal.body.state == uint8(DealsRepo.StateOfDeal.Locked), 
            "SHAK.execAlongs: state not Locked");

        require(!_roa.isFRClaimer(ia, caller), 
            "SHAK.execAlongs: caller is frClaimer");

        require(!_roa.isFRClaimer(ia, share.head.shareholder), 
            "SHAK.execAlongs: shareholder is frClaimer");

        _roa.createMockOfIA(ia);

        _checkAlongDeal(dragAlong, ia, deal, share, caller, paid, par, _ros.getShare(deal.head.seqOfShare).head.votingWeight);

        _roa.execAlongRight(ia, dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);
    }

    function _checkAlongDeal(
        bool dragAlong,
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint caller,
        uint paid,
        uint par,
        uint subjectVW
    ) private view {
        

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
            IRegisterOfMembers _rom = _gk.getROM();
            
            if (_rom.basedOnPar())
                require ( par <= 
                subjectVW * deal.body.par * share.body.par / _rom.votesOfGroup(deal.head.seller) / 100 , 
                "SHAKeeper.checkAlong: par overflow");
            else require ( paid <=
                 subjectVW * deal.body.paid * share.body.paid / _rom.votesOfGroup(deal.head.seller) / 100,
                "SHAKeeper.checkAlong: paid overflow");
        }
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        address msgSender,
        bytes32 sigHash
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);
        
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

            _ia.regSig(share.head.shareholder, claim.sigDate, claim.sigHash);
            _ia.regSig(caller, uint48(block.timestamp), sigHash);

            len--;
        }

    }

    function _createAlongDeal(
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

        _gk.getROS().decreaseCleanPaid(share.head.seqOfShare, claim.paid);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        address msgSender,
        bytes32 sigHash
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);
        
        IRegisterOfShares _ros = _gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        SharesRepo.Share memory tShare = _ros.getShare(seqOfShare);

        require(caller == tShare.head.shareholder, "SHAK.execAD: not shareholder");
        require(!_ia.isInitSigner(caller), "SHAK.execAD: is InitSigner");

        require(_gk.getROA().getHeadOfFile(ia).state == 
            uint8(FilesRepo.StateOfFile.Circulated), "SHAK.execAD: wrong file state");

        _ia.requestPriceDiff(seqOfDeal, seqOfShare);

        IAntiDilution _ad = IAntiDilution(_gk.getSHA().getTerm(
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

        _deductShares(obligors, _ia, deal, giftPaid, _ros, sigHash);

    }

    function _deductShares(
        uint[] memory obligors,
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        uint64 giftPaid,
        IRegisterOfShares _ros,
        bytes32 sigHash
    ) private {

        IRegisterOfMembers _rom = _gk.getROM();

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
        address ia,
        uint256 seqOfDeal,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);
        
        IRegisterOfShares _ros = _gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "caller is not buyer");
        require(_ros.notLocked(deal.head.seqOfShare, block.timestamp),
            "SHAK.takeGift: share locked");

        if (_ia.takeGift(seqOfDeal))
            _gk.getROA().setStateOfFile(ia, uint8(FilesRepo.StateOfFile.Closed));

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
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        address msgSender,
        bytes32 sigHash
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);
        
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(!_ia.isSeller(true, caller), 
            "SHAK.EFR: frClaimer is seller");

        DealsRepo.Head memory headOfDeal = 
            _ia.getDeal(seqOfDeal).head;
        
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

        if (_ia.getDeal(seqOfDeal).body.state != 
            uint8(DealsRepo.StateOfDeal.Terminated))
                _ia.terminateDeal(seqOfDeal); 
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);
        
        IRegisterOfMembers _rom = _gk.getROM();
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
            _gk.getROA().computeFirstRefusal(ia, seqOfDeal);

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

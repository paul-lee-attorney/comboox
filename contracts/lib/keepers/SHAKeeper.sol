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

import "../InterfacesHub.sol";
import "../utils/RoyaltyCharge.sol";
import "../books/RulesParser.sol";
import "../books/DTClaims.sol";

library SHAKeeper {
    using InterfacesHub for address;
    using RoyaltyCharge for address;
    using RulesParser for bytes32;
    using DTClaims for bytes32;

    // uint32(uint(keccak256("SHAKeeper")));
    uint public constant TYPE_OF_DOC = 0x2beb4fa1;
    uint public constant VERSION = 1;

    // #######################
    // ##   Error & Event   ##
    // #######################
    
    error SHAK_WrongParty(bytes32 reason);

    error SHAK_WrongState(bytes32 reason);

    error SHAK_AmtOverflow(bytes32 reason);

    error SHAK_ShareLocked(bytes32 reason);

    error SHAK_WrongTypeOfDeal(bytes32 reason);


    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        bytes32 snOfClaim,
        bytes32 sigHash
    ) external {
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION, 88000
        );

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
            if(caller != deal.head.seller) 
                revert SHAK_WrongParty(bytes32("SHAK_NotSeller"));
        } else {
            if(caller != share.head.shareholder)
                revert SHAK_WrongParty(bytes32("SHAK_NotShareholder"));
            if(ISigPage(ia).isBuyer(true, caller))
                revert SHAK_WrongParty(bytes32("SHAK_BuyerNotAllowed"));
        }
    }

    function _checkFRClaimAndMockIA(
        address ia,
        uint256 caller,
        SharesRepo.Share memory share
    ) private {
        IRegisterOfAgreements _roa = address(this).getROA();
        if(_roa.isFRClaimer(ia, caller))
            revert SHAK_WrongParty(bytes32("SHAK_CallerIsFRClaimer"));
        if(_roa.isFRClaimer(ia, share.head.shareholder))
            revert SHAK_WrongParty(bytes32("SHAK_ShareholderIsFRClaimer"));
        _roa.createMockOfIA(ia);            
    }

    function _getAlongTerm(
        bool dragAlong
    ) private view returns(IAlongs) {
        address _gk = address(this);
        return dragAlong
            ? IAlongs(_gk.getSHA().
                getTerm(uint8(IShareholdersAgreement.TitleOfTerm.DragAlong)))
            : IAlongs(_gk.getSHA().
                getTerm(uint8(IShareholdersAgreement.TitleOfTerm.TagAlong)));
    }

    function _isTriggered(
        IAlongs _al,
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share
    ) private view {
        if(deal.body.state != uint8(DealsRepo.StateOfDeal.Locked))
            revert SHAK_WrongState(bytes32("SHAK_NotLocked"));
        if(!_al.isFollower(deal.head.seller, share.head.shareholder))
            revert SHAK_WrongParty(bytes32("SHAK_NotLinked"));
        if(!_al.isTriggered(ia, deal))
            revert SHAK_WrongState(bytes32("SHAK_AlongsNotTriggered"));
    }

    function _checkAmt(
        IAlongs _al,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint paid,
        uint par
    ) private view {
        address _gk = address(this);
        uint subjectVW = _gk.getROS().getShare(deal.head.seqOfShare).head.votingWeight;

        if(_al.getLinkRule(deal.head.seller).proRata) {
            IRegisterOfMembers _rom = _gk.getROM();
            
            if (_rom.basedOnPar()) {
                if( par > 
                subjectVW * deal.body.par * share.body.par / _rom.votesOfGroup(deal.head.seller) / 100 )
                    revert SHAK_AmtOverflow(bytes32("SHAK_ParOverflow"));
            } else {
                if ( paid > 
                 subjectVW * deal.body.paid * share.body.paid / _rom.votesOfGroup(deal.head.seller) / 100 )
                revert SHAK_AmtOverflow(bytes32("SHAK_PaidOverflow"));
            }
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
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION,36000
        );
        
        IRegisterOfAgreements _roa = _gk.getROA();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        if(caller != deal.body.buyer)
            revert SHAK_WrongParty(bytes32("SHAK_NotBuyer"));

        DTClaims.Claim[] memory claims = _roa.acceptAlongClaims(ia, seqOfDeal);

        uint len = claims.length;
        while(len > 0) {
            DTClaims.Claim memory claim = claims[len - 1];

            SharesRepo.Share memory share = 
                _gk.getROS().getShare(claim.seqOfShare);

            _createAlongDeal(_gk, _ia, claim, deal, share);

            _ia.regSig(share.head.shareholder, claim.sigDate, claim.sigHash);
            _ia.regSig(caller, uint48(block.timestamp), sigHash);

            len--;
        }
    }

    function _createAlongDeal(
        address _gk,
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

    // ======== Anti-Dilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION,88000
        );

        IRegisterOfShares _ros = _gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        SharesRepo.Share memory tShare = _ros.getShare(seqOfShare);

        if(caller != tShare.head.shareholder)
            revert SHAK_WrongParty(bytes32("SHAK_NotShareholder"));
        
        if(_ia.isInitSigner(caller))
            revert SHAK_WrongParty(bytes32("SHAK_IsInitSigner"));

        if( _gk.getROA().getHeadOfFile(ia).state != 
            uint8(FilesRepo.StateOfFile.Circulated)
        ) revert SHAK_WrongState(bytes32("SHAK_WrongFileState"));

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
        address _gk = address(this);
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
        uint256 seqOfDeal
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION,58000
        );

        IRegisterOfShares _ros = _gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        if(caller != deal.body.buyer)
            revert SHAK_WrongParty(bytes32("SHAK_NotBuyer"));

        if(!_ros.notLocked(deal.head.seqOfShare, block.timestamp))
            revert SHAK_ShareLocked(bytes32("SHAK_ShareLocked"));

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

    // ==== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION,88000
        );

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        if(_ia.isSeller(true, caller))
            revert SHAK_WrongParty(bytes32("SHAK_frClaimerIsSeller"));

        DealsRepo.Head memory headOfDeal = 
            _ia.getDeal(seqOfDeal).head;
        
        RulesParser.FirstRefusalRule memory rule = 
            _gk.getSHA().getRule(seqOfFRRule).firstRefusalRuleParser();

        if(rule.typeOfDeal != headOfDeal.typeOfDeal)
            revert SHAK_WrongTypeOfDeal(bytes32("SHAK_WrongTypeOfDeal"));

        if(
            rule.membersEqual && 
            !_gk.getROM().isMember(caller)
        ) revert SHAK_WrongParty(bytes32("SHAK_NotMember"));

        if (
            !rule.membersEqual && 
            rule.rightholders[seqOfRightholder] != caller
        ) revert SHAK_WrongParty(bytes32("SHAK_NotRightholder"));

        _gk.getROA().claimFirstRefusal(ia, seqOfDeal, caller, sigHash);

        if (_ia.getDeal(seqOfDeal).body.state != 
            uint8(DealsRepo.StateOfDeal.Terminated))
                _ia.terminateDeal(seqOfDeal); 

    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION,18000
        );

        IRegisterOfMembers _rom = _gk.getROM();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        (,, bytes32 sigHashOfSeller) = _ia.getSigOfParty(true, deal.head.seller);

        if(!_rom.isMember(caller))
            revert SHAK_WrongParty(bytes32("SHAK_NotMember"));

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

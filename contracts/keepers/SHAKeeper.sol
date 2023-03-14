// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boh/terms/IAntiDilution.sol";
import "../books/boh/terms/ITerm.sol";
import "../books/boh/terms/IAlongs.sol";

import "../books/boh/IShareholdersAgreement.sol";

import "../books/bos/IBookOfShares.sol";
import "../books/boa/IInvestmentAgreement.sol";
// import "../books/boa/IFirstRefusalDeals.sol";

// import "../books/boa/IMockResults.sol";

import "../common/components/IRepoOfDocs.sol";

import "../common/components/ISigPage.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/BOASetting.sol";
import "../common/ruting/BOHSetting.sol";
import "../common/ruting/BOSSetting.sol";
// import "../common/ruting/IIASetting.sol";
import "../common/ruting/ROMSetting.sol";

// import "../common/ruting/ISigPageSetting.sol";

import "../common/lib/RulesParser.sol";
import "../common/lib/SigsRepo.sol";
// import "../common/lib/SNParser.sol";
// import "../common/lib/SNFactory.sol";
import "../common/lib/FRClaims.sol";

import "./ISHAKeeper.sol";

contract SHAKeeper is
    ISHAKeeper,
    BOASetting,
    BOHSetting,
    BOSSetting,
    ROMSetting,
    AccessControl
{
    using RulesParser for bytes32;
    // using SNFactory for bytes;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier withinExecPeriod(address ia) {
        require(
            _getBOA().getHeadOfDoc(ia).shaExecDeadline > block.timestamp,
            "missed review period"
        );
        _;
    }

    modifier afterExecPeriod(address ia) {
        require(
            _getBOA().getHeadOfDoc(ia).shaExecDeadline <= block.timestamp,
            "still within review period"
        );
        _;
    }

    modifier beforeProposeDeadline(address ia) {
        require(
            _getBOA().getHeadOfDoc(ia).proposeDeadline >= block.timestamp,
            "still within review period"
        );
        _;
    }

    modifier onlyEstablished(address ia) {
        require(
            _getBOA().getHeadOfDoc(ia).state ==
                uint8(IRepoOfDocs.RODStates.Established),
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

        IInvestmentAgreement.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);
        IBookOfShares.Share memory share = _getBOS().getShare(seqOfShare);

        require(deal.head.state != uint8(IInvestmentAgreement.StateOfDeal.Terminated), 
            "SHAK.EAR: deal terminated");

        _getBOA().createMockOfIA(ia);
        _checkAlongDeal(dragAlong, ia, deal, share, caller);

        _getBOA().execAlongRight(ia, dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);
    }

    function _checkAlongDeal(
        bool dragAlong,
        address ia,
        IInvestmentAgreement.Deal memory deal,
        IBookOfShares.Share memory share,
        uint256 caller
    ) private {

        require(!_getBOA().isFRClaimer(ia, caller), 
            "SHAK.CAD: caller is frClaimer");

        require(!_getBOA().isFRClaimer(ia, share.head.shareholder), 
            "SHAK.CAD: shareholder is frClaimer");

        address term = dragAlong
            ? _getSHA().getTerm(
                uint8(IShareholdersAgreement.TermTitle.DragAlong)
            )
            : _getSHA().getTerm(
                uint8(IShareholdersAgreement.TermTitle.TagAlong)
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

        IInvestmentAgreement.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "SHAK.AAD: not buyer");


        if (deal.head.state != uint8(IInvestmentAgreement.StateOfDeal.Terminated))
        {
            DTClaims.Claim memory claim = _getBOA().getClaimOfDT(ia, seqOfDeal, seqOfShare);
            IBookOfShares.Share memory share = _getBOS().getShare(seqOfShare);

            uint256 seqOfAlongDeal = _createAlongDeal(ia, claim, deal, share, caller);

            ISigPage(ia).regSig(seqOfAlongDeal, claim.claimer, claim.sigDate, claim.sigHash);
            ISigPage(ia).regSig(seqOfAlongDeal, caller, uint48(block.timestamp), sigHash);
        }        

    }

    function _createAlongDeal(
        address ia,
        DTClaims.Claim memory claim,
        IInvestmentAgreement.Deal memory deal,
        IBookOfShares.Share memory share
    ) private returns (uint256 seqOfAlongDeal) {
        deal.head = IInvestmentAgreement.Head({
            typeOfDeal: claim.typeOfClaim == 0 ? 
                uint8(IInvestmentAgreement.TypeOfDeal.DragAlong) : 
                uint8(IInvestmentAgreement.TypeOfDeal.TagAlong),
            classOfShare: share.head.class,
            seqOfShare: share.head.seq,
            seller: share.head.shareholder,
            price: deal.head.price,
            seq: 0,
            preSeq: deal.head.seq,
            closingDate: deal.head.closingDate,
            state: uint8(IInvestmentAgreement.StateOfDeal.Locked)
        });

        deal.body = IInvestmentAgreement.Body({
            buyer: deal.body.buyer,
            groupOfBuyer: deal.body.groupOfBuyer,
            paid: claim.paid,
            par: claim.par
        });

        seqOfAlongDeal = IInvestmentAgreement(ia).regDeal(deal);

        IInvestmentAgreement(ia).lockDealSubject(seqOfAlongDeal);
        _getBOS().decreaseCleanAmt(share.head.seq, claim.paid, claim.par);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyEstablished(ia) withinExecPeriod(ia) {

        IBookOfShares.Share memory share = _getBOS().getShare(seqOfShare);

        require(caller == share.head.shareholder,
                "SHAK.EAD: caller is not shareholder");

        require(!ISigPage(ia).isSigner(true, caller),
                "SHAK.EAD: caller is an InitSigner");

        address ad = _getSHA().getTerm(
            uint8(IShareholdersAgreement.TermTitle.AntiDilution)
        );

        uint64 giftPar = IAntiDilution(ad).giftPar(seqOfDeal, seqOfShare);
        uint256[] memory obligors = IAntiDilution(ad).obligors(share.head.class);

        _createGiftDeals(ia, seqOfDeal, giftPar, obligors, caller, sigHash);
    }

    function _createGiftDeals(
        address ia,
        uint256 seqOfDeal,
        uint64 giftPar,
        uint256[] memory obligors,
        uint256 caller,
        bytes32 sigHash
    ) private {
        for (uint256 i = 0; i < obligors.length; i++) {
            uint256[] memory sharesInHand = _getROM().sharesInHand(obligors[i]);

            for (uint256 j = 0; j < sharesInHand.length; j++) {
                (bytes32 snOfGiftDeal, uint64 result) = _createGift(
                    ia,
                    seqOfDeal,
                    sharesInHand[j],
                    giftPar,
                    caller
                );

                ISigPage(ia).signDeal(
                    snOfGiftDeal.seqOfDeal(),
                    caller,
                    sigHash
                );

                giftPar = result;
                if (giftPar == 0) break;
            }
            if (giftPar == 0) break;
        }
        require(giftPar == 0, "obligors have not enough parValue");
    }

    function _createGift(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint64 giftPar,
        uint256 caller
    ) private returns (uint256 seqOfGiftDeal, uint64 result) {
        uint64 targetCleanPaid = _getBOS().getShare(seqOfShare).body.cleanPaid;

        uint64 lockAmount;

        if (targetCleanPaid != 0) {
            snOfGiftDeal = _createGiftDealSN(ia, seqOfDeal, shareNumber, caller);

            uint48 closingDate = IInvestmentAgreement(ia).getDeal(
                sn.seqOfDeal()
            ).closingDate;

            lockAmount = (targetCleanPaid < giftPar) ? targetCleanPaid : giftPar;

            IInvestmentAgreement(ia).createDeal(
                snOfGiftDeal,
                lockAmount,
                lockAmount,
                closingDate
            );

            if (
                IInvestmentAgreement(ia).lockDealSubject(
                    snOfGiftDeal.seqOfDeal()
                )
            ) {
                _getBOS().decreaseCleanAmt(shareNumber.ssn(), lockAmount, lockAmount);
            }
        }
        result = giftPar - lockAmount;
    }

    function _createGiftDealSN(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) private view returns (bytes32) {
        return
            createDealSN(
                shareNumber.class(),
                IInvestmentAgreement(ia).counterOfDeals() + 1,
                uint8(IInvestmentAgreement.TypeOfDeal.FreeGift),
                shareNumber.shareholder(),
                caller,
                _getROM().groupRep(caller),
                shareNumber.ssn(),
                0,
                sn.seqOfDeal()
            );
    }

    function takeGiftShares(
        address ia,
        bytes32 sn,
        uint40 caller
    ) external onlyDirectKeeper {
        require(caller == sn.buyerOfDeal(), "caller is not buyer");

        uint16 seq = sn.seqOfDeal();

        IInvestmentAgreement(ia).takeGift(seq);

        IInvestmentAgreement.Deal memory deal = IInvestmentAgreement(ia).getDeal(seq);

        uint32 ssn = sn.ssnOfDeal();

        _getBOS().increaseCleanAmt(ssn, deal.paid, deal.par);

        _getBOS().transferShare(ssn, deal.paid, deal.par, sn.buyerOfDeal(), 0);
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

        IInvestmentAgreement.Head memory headOfDeal = IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);
        
        RulesParser.FirstRefusalRule memory rule = _getSHA().getRule(seqOfFRRule).firstRefusalRuleParser();

        require(rule.typeOfDeal == headOfDeal.typeOfDeal, 
            "SHAK.EFR: rule and deal are not same type");

        require(
            (rule.membersEqual && _getROM().isMember(caller)) || 
            rule.rightholders[seqOfRightholder] == caller,
            "SHAK.EFR: caller NOT rightholder"
        );

        if (_getBOA().execFirstRefusalRight(ia, seqOfDeal, caller, sigHash)) {
            IInvestmentAgreement(ia).terminateDeal(seqOfDeal);
        }
    }

    function acceptFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper afterExecPeriod(ia) {

        IInvestmentAgreement.Head memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        if (deal.head.typeOfDeal == uint8(IInvestmentAgreement.TypeOfDeal.CapitalIncrease)
        ) require( _getROM().groupRep(caller) == _getROM().controllor(), 
            "SHAK.AFR: not controller");
        else require(caller == deal.head.seller, "SHAK.AFR: not sellerOfDeal");

        FRClaims.Claim[] memory cls = _getBOA().acceptFirstRefusalClaims(ia, seqOfDeal);

        uint256 len = cls.length;

        while (len > 0) {
            _createFRDeal(ia, deal, cls[len-1]);
            len--;
        }

        ISigPage(ia).signDoc(false, caller, sigHash);
    }

    function _createFRDeal(
        address ia,
        IInvestmentAgreement.Deal memory deal,
        FRClaims.Claim memory cl
    ) private {

        if (deal.head.seqOfShare != 0) {
            deal.head.typeOfDeal = uint8(IInvestmentAgreement.TypeOfDeal.FirstRefusal);
        }   deal.head.typeOfDeal = uint8(IInvestmentAgreement.TypeOfDeal.PreEmptive);
        
        deal.head.preSeq = deal.head.seq;
        deal.head.state = uint8(IInvestmentAgreement.StateOfDeal.Drafting);

        deal.body.buyer = cl.rightholder;
        deal.body.groupOfBuyer = _getROM().groupRep(cl.rightholder);
        deal.paid = (deal.paid * cl.ratio) / 10000;
        deal.par = (deal.par * cl.ratio) / 10000;

        IInvestmentAgreement(ia).lockDealSubject(IInvestmentAgreement(ia).regDeal(deal));

        ISigPage(ia).signDoc(false, cl.rightholder, cl.sigHash);
    }
}

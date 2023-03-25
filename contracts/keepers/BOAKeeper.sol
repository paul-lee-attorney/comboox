// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOAKeeper.sol";

import "../books/boa/IInvestmentAgreement.sol";

import "../common/access/AccessControl.sol";

import "../common/components/IRepoOfDocs.sol";
import "../common/components/ISigPage.sol";

import "../common/lib/RulesParser.sol";
import "../common/lib/SharesRepo.sol";

import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOGSetting.sol";
import "../common/ruting/BOHSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/ROMSetting.sol";

contract BOAKeeper is 
    IBOAKeeper, 
    BOASetting, 
    BOGSetting, 
    BODSetting, 
    BOHSetting, 
    BOSSetting, 
    ROMSetting, 
    AccessControl 
{

    using RulesParser for uint256;

    IShareholdersAgreement.TermTitle[] private _termsForCapitalIncrease = [
        IShareholdersAgreement.TermTitle.AntiDilution
    ];

    IShareholdersAgreement.TermTitle[] private _termsForShareTransfer = [
        IShareholdersAgreement.TermTitle.LockUp,
        IShareholdersAgreement.TermTitle.TagAlong,
        IShareholdersAgreement.TermTitle.DragAlong
    ];

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint256 caller) {
        require(
            IAccessControl(body).getOwner() == caller,
            "NOT Owner of Doc"
        );
        _;
    }

    modifier onlyPartyOf(address ia, uint256 caller) {
        require(ISigPage(ia).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function setTempOfIA(address temp, uint256 typeOfDoc) external onlyDirectKeeper {
        _boa.setTemplate(temp, typeOfDoc);
    }

    function createIA(uint256 typOfIA, uint256 caller) external onlyDirectKeeper {
        require(_rom.isMember(caller), "caller not MEMBER");

        address ia = _boa.createDoc(typOfIA, caller);

        IAccessControl(ia).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );
    }

    function removeIA(address ia, uint256 caller)
        external
        onlyDirectKeeper
        onlyOwnerOf(ia, caller)
    {
        _boa.removeDoc(ia);
    }

    // ======== Circulate IA ========

    function circulateIA(
        address ia,
        uint256 caller,
        bytes32 docUrl,
        bytes32 docHash
    ) external onlyDirectKeeper onlyOwnerOf(ia, caller) {
        IAccessControl(ia).lockContents();
        IAccessControl(ia).setOwner(0);

        _boa.circulateIA(ia, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyPartyOf(ia, caller) {
        require(
            _boa.getHeadOfDoc(ia).state == uint8(IRepoOfDocs.RODStates.Circulated),
            "IA not in Circulated State"
        );

        _lockDealsOfParty(ia, caller);

        ISigPage(ia).signDoc(true, caller, sigHash);

        if (ISigPage(ia).established())
            _boa.setStateOfDoc(ia, uint8(IRepoOfDocs.RODStates.Established));
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
                    _bos.decreaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
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
            _boa.getHeadOfDoc(ia).state == uint8(IRepoOfDocs.RODStates.Voted),
            "wrong state of BOD"
        );

        require(
            closingDate <= uint48(ISigPage(ia).getParasOfPage(true).blocknumber),
            "closingDate LATER than deadline"
        );

        DealsRepo.Head memory head = 
            IInvestmentAgreement(ia).getHeadOfDeal(seqOfDeal);

        // uint16 seq = sn.seqOfDeal();

        bool isST = (head.seqOfShare != 0);

        if (isST) require(caller == head.seller, "BOAK.PTC: not seller");
        else require(_bod.isDirector(caller), "BOAK.PTC: not director");

        _vrAndSHACheck(ia, seqOfDeal, isST);

        IInvestmentAgreement(ia).clearDealCP(seqOfDeal, hashLock, closingDate);
    }

    function _vrAndSHACheck(address ia, uint256 seqOfDeal, bool isST) private view {
        uint256 typeOfIA = IInvestmentAgreement(ia).getTypeOfIA();

        RulesParser.VotingRule memory vr = _getSHA().getRule(typeOfIA).votingRuleParser();

        if (vr.amountRatio > 0 || vr.headRatio > 0) {
            if (vr.authority == 1)
                require(_bog.isPassed(uint256(uint160(ia))), 
                    "BOAK.ptc:  GM Motion NOT passed");
            else if (vr.authority == 2)
                require(_bod.isPassed(uint256(uint160(ia))), 
                    "BOAK.ptc:  Board Motion NOT passed");
            else if (vr.authority == 3)
                require(_bog.isPassed(uint256(uint160(ia))) && 
                    _bod.isPassed(uint256(uint160(ia))), 
                    "BOAK.ptc: Board and GM not BOTH passed");
            else revert("BOAK.ptc: wrong decision power setting");
        }

        if (isST) _checkSHA(_termsForShareTransfer, ia, seqOfDeal);
        else _checkSHA(_termsForCapitalIncrease, ia, seqOfDeal);
    }

    function _checkSHA(
        IShareholdersAgreement.TermTitle[] memory terms,
        address ia,
        uint256 seqOfDeal
    ) private view {
        uint256 len = terms.length;

        while (len > 0) {
            if (_getSHA().hasTitle(uint8(terms[len - 1])))
                require(
                    _getSHA().termIsExempted(uint8(terms[len - 1]), ia, seqOfDeal),
                    "BOAK.PTC: SHA obligation not exempted"
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
            _boa.getHeadOfDoc(ia).state == uint8(IRepoOfDocs.RODStates.Voted),
            "BOAKeeper.closeDeal: InvestmentAgreement NOT in voted state"
        );

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        //交易发起人为买方;
        require(
            deal.body.buyer == caller,
            "BOAKeeper.closeDeal: caller is NOT buyer"
        );

        //验证hashKey, 执行Deal
        if (IInvestmentAgreement(ia).closeDeal(seqOfDeal, hashKey))
            _boa.setStateOfDoc(ia, uint8(IRepoOfDocs.RODStates.Executed));

        // uint32 ssn = sn.ssnOfDeal();

        if (deal.head.seqOfShare > 0) {
            _shareTransfer(ia, seqOfDeal);
        } else issueNewShare(ia, seqOfDeal);
    }

    function _shareTransfer(address ia, uint256 seqOfDeal) private {
        // uint16 seq = sn.seqOfDeal();
        // uint32 ssn = sn.ssnOfDeal();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        // uint32 unitPrice = sn.priceOfDeal();
        // uint40 buyer = sn.buyerOfDeal();

        _bos.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _bos.transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, deal.body.buyer, deal.head.priceOfPaid);
    }

    function issueNewShare(address ia, uint256 seqOfDeal) public onlyDirectKeeper {
        // uint16 seq = sn.seqOfDeal();

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

        _bos.regShare(share);
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
            _boa.getHeadOfDoc(ia).state == uint8(IRepoOfDocs.RODStates.Voted),
            "BOAKeeper.revokeDeal: wrong State"
        );

        // uint16 seq = sn.seqOfDeal();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "BOAK.RD: NOT seller"
        );

        if (IInvestmentAgreement(ia).revokeDeal(seqOfDeal, hashKey))
            _boa.setStateOfDoc(ia, uint8(IRepoOfDocs.RODStates.Executed));

        if (IInvestmentAgreement(ia).releaseDealSubject(seqOfDeal))
            _bos.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
    }

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external onlyDirectKeeper {
        require(
            _boa.getHeadOfDoc(ia).state >= uint8(IRepoOfDocs.RODStates.Circulated),
            "BOAK.TD: wrong State"
        );

        require(
            _boa.getHeadOfDoc(ia).state < uint8(IRepoOfDocs.RODStates.Executed),
            "BOAK.TD: wrong State"
        );

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "BOAK.TD: NOT seller"
        );

        if (IInvestmentAgreement(ia).terminateDeal(seqOfDeal))
        {
            _boa.setStateOfDoc(ia, uint8(IRepoOfDocs.RODStates.Executed));
            _bos.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        }

    }

}

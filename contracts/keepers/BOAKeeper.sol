// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boa/InvestmentAgreement.sol";
import "../books/boa/IInvestmentAgreement.sol";
import "../books/boh/ShareholdersAgreement.sol";

import "../common/access/IAccessControl.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/IBookSetting.sol";
import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BOHSetting.sol";
import "../common/ruting/ROMSetting.sol";

import "../common/lib/SNFactory.sol";
import "../common/lib/SNParser.sol";

import "./IBOAKeeper.sol";

contract BOAKeeper is
    IBOAKeeper,
    BOASetting,
    BODSetting,
    BOHSetting,
    BOMSetting,
    BOSSetting,
    ROMSetting
{
    using SNFactory for bytes;
    using SNParser for bytes32;

    IShareholdersAgreement.TermTitle[] private _termsForCapitalIncrease = [
        IShareholdersAgreement.TermTitle.ANTI_DILUTION
    ];

    IShareholdersAgreement.TermTitle[] private _termsForShareTransfer = [
        IShareholdersAgreement.TermTitle.LOCK_UP,
        IShareholdersAgreement.TermTitle.TAG_ALONG,
        IShareholdersAgreement.TermTitle.DRAG_ALONG
    ];

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier notEstablished(address body) {
        require(!_boa.established(body), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint40 caller) {
        require(
            IAccessControl(body).getOwner() == caller,
            "NOT Owner of Doc"
        );
        _;
    }

    modifier onlyPartyOf(address ia, uint40 caller) {
        require(_boa.isParty(ia, caller), "NOT Owner of Doc");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function setTempOfIA(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
        _boa.setTemplate(temp, typeOfDoc);
    }

    function createIA(uint8 typOfIA, uint40 caller) external onlyDirectKeeper {
        require(_rom.isMember(caller), "caller not MEMBER");

        address ia = _boa.createDoc(typOfIA, caller);

        IAccessControl(ia).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );

        IBookSetting(ia).setBOS(address(_bos));
        IBookSetting(ia).setROM(address(_rom));
        IBookSetting(ia).setROD(address(_boa));
    }

    function removeIA(address ia, uint40 caller)
        external
        onlyDirectKeeper
        onlyOwnerOf(ia, caller)
    {
        _boa.removeDoc(ia);
    }

    // ======== Circulate IA ========

    function circulateIA(
        address ia,
        uint40 caller,
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
        uint40 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyPartyOf(ia, caller) {
        require(
            _boa.getHeadOfDoc(ia).state == uint8(IRepoOfDocs.RODStates.Circulated),
            "IA not in Circulated State"
        );

        _lockDealsOfParty(ia, caller);

        _boa.signDoc(ia, caller, sigHash);

        if (_boa.established(ia)) {
            _boa.pushToNextState(ia);
        }
    }

    function _lockDealsOfParty(address ia, uint40 caller) private {
        bytes32[] memory snList = IInvestmentAgreement(ia).dealsList();
        uint256 len = snList.length;
        while (len != 0) {
            bytes32 sn = snList[len - 1];
            len--;

            uint16 seq = sn.seqOfDeal();

            if (sn.sellerOfDeal() == caller) {
                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    _bos.decreaseCleanPar(sn.ssnOfDeal(), IInvestmentAgreement(ia).getDeal(seq).par);
                }
            } else if (
                sn.buyerOfDeal() == caller &&
                sn.typeOfDeal() ==
                uint8(IInvestmentAgreement.TypeOfDeal.CapitalIncrease)
            ) IInvestmentAgreement(ia).lockDealSubject(seq);
        }
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint48 closingDate,
        uint40 caller
    ) external onlyDirectKeeper {
        require(
            _boa.getHeadOfDoc(ia).state == uint8(IRepoOfDocs.RODStates.Voted),
            "wrong state of BOD"
        );

        require(
            closingDate <= _boa.closingDeadline(ia),
            "closingDate LATER than deadline"
        );

        uint16 seq = sn.seqOfDeal();

        bool isST = (sn.ssnOfDeal() != 0);

        if (isST) require(caller == sn.sellerOfDeal(), "BOAKeeper.pushToCoffer: NOT seller");
        else require(_bod.isDirector(caller), "BOAKeeper.pushToCoffer: caller is not director");

        _vrAndSHACheck(ia, sn, isST);

        IInvestmentAgreement(ia).clearDealCP(seq, hashLock, closingDate);
    }

    function _vrAndSHACheck(address ia, bytes32 sn, bool isST) private view {
        uint256 typeOfIA = IInvestmentAgreement(ia).typeOfIA();

        bytes32 vr = _getSHA().getRule(typeOfIA);

        if (vr.ratioAmountOfVR() != 0 || vr.ratioHeadOfVR() != 0) {

            if (vr.authorityOfVR() == 1)
                require(_bog.isPassed(uint256(uint160(ia))), "BOAKeeper.ptc:  GM Motion NOT passed");
            else if (vr.authorityOfVR() == 2)
                require(_bod.isPassed(uint256(uint160(ia))), "BOAKeeper.ptc:  Board Motion NOT passed");
            else if (vr.authorityOfVR() == 3)
                require(_bod.isPassed(uint256(uint160(ia))) && _bog.isPassed(uint256(uint160(ia))), "BOAKeeper.ptc: Board and GM not BOTH passed");
            else revert("BOAKeeper.ptc: wrong decision power setting");
        }

        if (isST) _checkSHA(_termsForShareTransfer, ia, sn);
        else _checkSHA(_termsForCapitalIncrease, ia, sn);
    }

    function _checkSHA(
        IShareholdersAgreement.TermTitle[] memory terms,
        address ia,
        bytes32 sn
    ) private view {
        uint256 len = terms.length;

        while (len > 0) {
            if (_getSHA().hasTitle(uint8(terms[len - 1])))
                require(
                    _getSHA().termIsExempted(uint8(terms[len - 1]), ia, sn),
                    "BOAKeeper.ptc: SHA obligation not exempted"
                );
            len--;
        }
    }

    function closeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey,
        uint40 caller
    ) external onlyDirectKeeper {
        require(
            _boa.getHeadOfDoc(ia).state == uint8(IRepoOfDocs.RODStates.Voted),
            "BOAKeeper.closeDeal: InvestmentAgreement NOT in voted state"
        );

        //交易发起人为买方;
        require(
            sn.buyerOfDeal() == caller,
            "BOAKeeper.closeDeal: caller is NOT buyer"
        );

        uint16 seq = sn.seqOfDeal();

        //验证hashKey, 执行Deal
        if (IInvestmentAgreement(ia).closeDeal(seq, hashKey))
            _boa.pushToNextState(ia);

        uint32 ssn = sn.ssnOfDeal();

        if (ssn > 0) {
            _shareTransfer(ia, sn);
        } else issueNewShare(ia, sn);
    }

    function _shareTransfer(address ia, bytes32 sn) private {
        uint16 seq = sn.seqOfDeal();
        uint32 ssn = sn.ssnOfDeal();

        IInvestmentAgreement.Deal memory deal = IInvestmentAgreement(ia).getDeal(seq);

        uint32 unitPrice = sn.priceOfDeal();
        uint40 buyer = sn.buyerOfDeal();

        _bos.increaseCleanPar(ssn, deal.paid);
        _bos.transferShare(ssn, deal.paid, deal.par, buyer, unitPrice);
    }

    function issueNewShare(address ia, bytes32 sn) public onlyDirectKeeper {
        uint16 seq = sn.seqOfDeal();

        IInvestmentAgreement.Deal memory deal = IInvestmentAgreement(ia).getDeal(seq);

        bytes32 shareNumber = _createShareNumber(
            sn.classOfDeal(),
            sn.buyerOfDeal(),
            sn.priceOfDeal()
        );

        uint48 paidInDeadline;


        paidInDeadline = uint48(block.timestamp) + 43200;

        _bos.issueShare(shareNumber, deal.paid, deal.par, paidInDeadline);
    }

    function _createShareNumber(
        uint16 class,
        uint40 shareholder,
        uint32 unitPrice
    ) private pure returns (bytes32) {
        bytes memory _sn = new bytes(32);

        _sn = _sn.seqToSN(0, class);
        _sn = _sn.acctToSN(12, shareholder);
        _sn = _sn.ssnToSN(17, unitPrice);

        return _sn.bytesToBytes32();
    }

    function transferTargetShare(
        address ia,
        bytes32 sn,
        uint40 caller
    ) public onlyDirectKeeper {
        require(
            caller == sn.sellerOfDeal(),
            "BOAKeeper.transferTargetShare: caller not seller of Deal"
        );

        _vrAndSHACheck(ia, sn, true);

        _shareTransfer(ia, sn);
    }

    function revokeDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        string memory hashKey
    ) external onlyDirectKeeper {
        require(
            _boa.getHeadOfDoc(ia).state == uint8(IRepoOfDocs.RODStates.Voted),
            "BOAKeeper.revokeDeal: wrong State"
        );

        uint16 seq = sn.seqOfDeal();

        require(
            caller == sn.sellerOfDeal(),
            "BOAKeeper.revokeDeal: NOT seller"
        );

        if (IInvestmentAgreement(ia).revokeDeal(seq, hashKey))
            _boa.pushToNextState(ia);

        if (IInvestmentAgreement(ia).releaseDealSubject(seq))
            _bos.increaseCleanPar(sn.ssnOfDeal(), IInvestmentAgreement(ia).getDeal(seq).par);
    }
}

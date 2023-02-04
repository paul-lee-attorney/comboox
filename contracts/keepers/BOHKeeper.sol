// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boh/ShareholdersAgreement.sol";
import "../books/boh/IShareholdersAgreement.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/BOASetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/ROMSetting.sol";
import "../common/ruting/BOHSetting.sol";
import "../common/ruting/IBookSetting.sol";

import "../common/access/IAccessControl.sol";

import "../common/lib/SNParser.sol";

import "./IBOHKeeper.sol";

contract BOHKeeper is
    IBOHKeeper,
    BOASetting,
    BODSetting,
    BOMSetting,
    BOOSetting,
    BOSSetting,
    ROMSetting,
    BOHSetting
{
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint40 caller) {
        require(
            caller != 0 && IAccessControl(body).getManager(0) == caller,
            "not Owner"
        );
        _;
    }

    modifier onlyPartyOf(address body, uint40 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function setTempOfSHA(address temp, uint8 typeOfDoc) external onlyDK {
        _boh.setTemplate(temp, typeOfDoc);
    }

    function setTermTemplate(uint8 title, address body) external onlyDK {
        _boh.setTermTemplate(title, body);
    }

    function createSHA(uint8 docType, uint40 caller) external onlyDK {
        require(_rom.isMember(caller), "not MEMBER");
        address sha = _boh.createDoc(docType, caller);

        IAccessControl(sha).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );

        IBookSetting(sha).setBOA(address(_boa));
        IBookSetting(sha).setBOH(address(_boh));
        IBookSetting(sha).setBOM(address(_bom));
        IBookSetting(sha).setBOS(address(_bos));
        IBookSetting(sha).setROM(address(_rom));
    }

    function removeSHA(address sha, uint40 caller)
        external
        onlyDK
        onlyOwnerOf(sha, caller)
        notEstablished(sha)
    {
        _boh.removeDoc(sha);
    }

    function circulateSHA(
        address sha,
        uint40 caller,
        bytes32 docHash
    ) external onlyDK onlyOwnerOf(sha, caller) {
        IShareholdersAgreement(sha).finalizeTerms();

        IAccessControl(sha).setManager(0, 0);

        _boh.circulateDoc(sha, bytes32(0), docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDK onlyPartyOf(sha, caller) {
        require(
            _boh.currentState(sha) == uint8(DocumentsRepo.BODStates.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(caller, sigHash);

        if (ISigPage(sha).established()) _boh.pushToNextState(sha);
    }

    function effectiveSHA(address sha, uint40 caller)
        external
        onlyDK
        onlyPartyOf(sha, caller)
    {
        require(
            _boh.currentState(sha) ==
                uint8(DocumentsRepo.BODStates.Established),
            "SHA not executed yet"
        );

        uint40[] memory members = _rom.membersList();
        uint256 len = members.length;
        while (len != 0) {
            require(
                ISigPage(sha).isParty(members[len - 1]),
                "left member for SHA"
            );
            len--;
        }

        _boh.changePointer(sha);

        _rom.setAmtBase(IShareholdersAgreement(sha).basedOnPar());

        _rom.setVoteBase(IShareholdersAgreement(sha).basedOnPar());

        _bod.setMaxQtyOfDirectors(
            IShareholdersAgreement(sha).maxNumOfDirectors()
        );

        if (
            IShareholdersAgreement(sha).hasTitle(
                uint8(ShareholdersAgreement.TermTitle.OPTIONS)
            )
        ) {
            _boo.registerOption(
                IShareholdersAgreement(sha).getTerm(
                    uint8(ShareholdersAgreement.TermTitle.OPTIONS)
                )
            );
        }

        if (IShareholdersAgreement(sha).lengthOfOrders() > 0) {
            bytes32[] memory guo = IShareholdersAgreement(sha).groupOrders();
            len = guo.length;
            while (len != 0) {
                bytes32 order = guo[len - 1];
                if (order.addMemberOfGUO())
                    _rom.addMemberToGroup(
                        order.memberOfGUO(),
                        order.groupNoOfGUO()
                    );
                else
                    _rom.removeMemberFromGroup(
                        order.memberOfGUO(),
                        order.groupNoOfGUO()
                    );
                len--;
            }
        }
    }

    function acceptSHA(bytes32 sigHash, uint40 caller) external onlyDK {
        ISigPage(_boh.pointer()).acceptDoc(sigHash, caller);
    }
}

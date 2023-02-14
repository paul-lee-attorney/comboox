// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
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
        require(!_boh.established(body), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint40 caller) {
        require(
            caller != 0 && IAccessControl(body).getOwner() == caller,
            "not Owner"
        );
        _;
    }

    modifier onlyPartyOf(address body, uint40 caller) {
        require(_boh.isParty(body, caller), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function setTempOfSHA(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
        _boh.setTemplate(temp, typeOfDoc);
    }

    function setTermTemplate(uint8 title, address body) external onlyDirectKeeper {
        _boh.setTermTemplate(title, body);
    }

    function createSHA(uint8 docType, uint40 caller) external onlyDirectKeeper {
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
        onlyDirectKeeper
        onlyOwnerOf(sha, caller)
        notEstablished(sha)
    {
        _boh.removeDoc(sha);
    }

    function circulateSHA(
        address sha,
        uint40 caller,
        bytes32 rule,
        bytes32 docUrl,
        bytes32 docHash
    ) external onlyDirectKeeper onlyOwnerOf(sha, caller) {
        IShareholdersAgreement(sha).finalizeTerms();

        IAccessControl(sha).setOwner(0);

        _boh.circulateDoc(sha, rule, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external onlyDirectKeeper onlyPartyOf(sha, caller) {
        require(
            _boh.currentState(sha) == uint8(RepoOfDocs.RODStates.Circulated),
            "SHA not in Circulated State"
        );

        _boh.signDoc(sha, caller, sigHash);

        if (_boh.established(sha)) _boh.pushToNextState(sha);
    }

    function effectiveSHA(address sha, uint40 caller)
        external
        onlyDirectKeeper
        onlyPartyOf(sha, caller)
    {
        require(
            _boh.currentState(sha) ==
                uint8(RepoOfDocs.RODStates.Established),
            "BOHKeeper.es: SHA not executed yet"
        );

        require(_allMembersSigned(sha) || _reachedEffectiveThreshold(sha), 
            "BOHKeeper.es: SHA effective conditions not reached");

        _boh.changePointer(sha);

        bytes32 governingRule = IShareholdersAgreement(sha).getRule(0);

        _rom.setAmtBase(governingRule.basedOnPar());

        _rom.setVoteBase(governingRule.basedOnPar());

        _bod.setMaxQtyOfDirectors(
            governingRule.maxNumOfDirectors()
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

        bytes32 groupUpdateOrder = IShareholdersAgreement(sha).getRule(768);
        uint256 len = groupUpdateOrder.qtyOfSubRule();
        uint256 i;
        while (i < len) {
            bytes32 order = IShareholdersAgreement(sha).getRule(768+i);
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
            i++;
        }
    }

    function _allMembersSigned(address sha) private view returns (bool) {
        uint40[] memory members = _rom.membersList();
        uint256 len = members.length;
        while (len > 0) {            
            if (!_boh.isParty(sha, members[len - 1]))
                return false;
            len--;
        }
        return true;
    }

    function _reachedEffectiveThreshold(address sha) private view returns (bool) {
        uint40[] memory parties = _boh.partiesOfDoc(sha);
        uint256 len = parties.length;
        
        bytes32 rule = _getSHA().getRule(0);
        uint64 threashold = uint64(rule.shaEffectiveRatio()) * _rom.totalVotes() / 10000;
        
        uint64 supportWeight;        
        while (len > 0) {
            supportWeight += _rom.votesInHand(parties[len-1]);
            if (supportWeight > threashold) return true;
            len --;
        }
        return false;
    }

    function acceptSHA(bytes32 sigHash, uint40 caller) external onlyDirectKeeper {
        _boh.acceptDoc(_boh.pointer(), sigHash, caller);
    }
}

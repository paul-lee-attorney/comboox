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

import "../../comps/books/rom/IRegisterOfMembers.sol";

/// @title WaterfallsRepo
/// @notice Waterfall distribution repository for funds and members.
library WaterfallsRepo {

    uint public constant TWO_TO_40 = 1 << 40 - 1;
    uint public constant TWO_TO_16 = 1 << 16 - 1;
    uint public constant TWO_TO_32 = 1 << 32 - 1;

    /// @notice Distribution drop record.
    struct Drop {
        uint24 seqOfDistr;
        uint40 member;
        uint16 class;
        uint48 distrDate;
        uint64 principal;
        uint64 income;
    }

    /// @notice Flow of drops for shares.
    struct Flow {
        // seqOfShare => drop
        mapping(uint => Drop) drops;
        uint[] shares;
    }

    /// @notice Creek of flows per class.
    struct Creek {
        // class => Flow
        mapping(uint => Flow) flows;
        uint[] classes;
    }

    /// @notice Stream of creeks per member.
    struct Stream {
        // member => Creek
        mapping(uint => Creek) creeks;
        uint[] members;
    }

    /// @notice Repository of distribution streams.
    struct Repo {
        // seqOfDistr => Stream
        mapping(uint => Stream) streams;
    }

    //####################
    //##     Error      ##
    //####################

    error WR_WrongInput(bytes32 reason);
    error WR_WrongState(bytes32 reason);
    error WR_Overflow(bytes32 reason);
    error WR_WrongParty(bytes32 reason);

    //####################
    //##     Write      ##
    //####################

    /// @notice Initialize a class with principal.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param principal Principal amount.
    function initClass(
        Repo storage repo, uint class, uint principal
    ) public returns(Drop memory info) {
        info = repo.streams[0].creeks[0].flows[class].drops[0];

        if (info.distrDate != 0) 
            revert WR_WrongState(bytes32("WR_ClassAlreadyInitialized"));

        if (principal == 0)
            revert WR_WrongInput(bytes32("WR_ZeroPrincipal"));

        info.class = uint16(class);
        info.distrDate = uint48(block.timestamp);
        info.principal = uint64(principal);

        repo.streams[0].creeks[0].flows[class].drops[0] = info; // seaInfo
        repo.streams[0].creeks[TWO_TO_40].flows[class].drops[0] = info; // initSeaInfo
        repo.streams[0].creeks[1].flows[class].drops[0].distrDate = info.distrDate; // gulfInfo

        Creek storage counter = repo.streams[0].creeks[0]; // counterOfClasses
        counter.classes.push(info.class);
    }

    /// @notice Redeem principal for a class.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param principal Principal amount.
    function redeemClass(
        Repo storage repo, uint class, uint principal
    ) public {
        Drop memory info = repo.streams[0].creeks[0].flows[class].drops[0];

        if (info.distrDate > 0) {
            
            if (principal == 0) 
                revert WR_WrongInput(bytes32("WR_ZeroPrincipal"));

            if (info.principal <= principal) 
                revert WR_WrongInput(bytes32("WR_RedeemPrincipalExceeds"));

            info.principal = uint64(principal);

            repo.streams[0].creeks[0].flows[class].drops[0].principal -= info.principal; // seaInfo
            repo.streams[0].creeks[TWO_TO_40].flows[class].drops[0].principal -= info.principal; // initSeaInfo
        }
    }

    // ==== Distribution ====

    // ---- ProRata ----

    /// @notice Distribute pro-rata by member points or shares.
    /// @param repo Storage repo.
    /// @param amt Amount to distribute.
    /// @param _rom Register of members.
    /// @param _ros Register of shares.
    /// @param refundPrincipal True to refund principal.
    function proRataDistr(
        Repo storage repo, uint amt, IRegisterOfMembers _rom, 
        IRegisterOfShares _ros, bool refundPrincipal
    ) public returns(
        Drop memory drop,
        Drop[] memory mList, 
        Drop[] memory sList
    ){

        uint totalPoints = _rom.ownersPoints().points;
        uint[] memory members = _rom.membersList();

        drop = _createDrop(repo);

        drop.class = uint16(TWO_TO_16);
        drop.principal = 0;

        if (refundPrincipal) {
            _allocateAmongShares(repo, members, drop, _rom, _ros, amt, totalPoints);
            sList = getDropsOfStream(repo, drop.seqOfDistr);
        } else {
            _allocateAmongMembers(repo, members, drop, _rom, amt, totalPoints);
        }

        mList = getCreeksOfStream(repo, drop.seqOfDistr);
    }

    function _allocateAmongShares(
        Repo storage repo, uint[] memory members, Drop memory drop,
        IRegisterOfMembers _rom, IRegisterOfShares _ros, uint amt,
        uint totalPoints
    ) private {
        uint len = members.length;
        uint sum = 0;

        while (len > 0) {
            drop.member = uint40(members[len-1]);

            uint[] memory seqs = _rom.sharesInHand(drop.member);
            uint qty = seqs.length;
            
            SharesRepo.Share memory share;

            while((len > 1 && qty > 0) || (len == 1 && qty > 1)) {
                share = _ros.getShare(seqs[qty-1]);
                drop.class = share.head.class;
                drop.income = 
                    uint64(amt * share.body.paid * share.body.distrWeight / 100 / totalPoints);
                drop.principal = share.body.paid * 100;
                if (drop.income >= drop.principal) {
                    drop.income -= drop.principal;
                }else {
                    drop.principal = drop.income;
                    drop.income = 0;
                }
                _addDrop(repo, drop, seqs[qty-1]);

                sum += drop.income + drop.principal;

                qty--;
            }

            if (len == 1 && qty == 1) {
                share = _ros.getShare(seqs[0]);
                drop.class = share.head.class;
                drop.income = uint64(amt - sum);
                drop.principal = share.body.paid * 100;
                if (drop.income >= drop.principal) {
                    drop.income -= drop.principal;
                }else {
                    drop.principal = drop.income;
                    drop.income = 0;
                }
                _addDrop(repo, drop, seqs[0]);                    
            }

            len--;
        }

    }

    function _allocateAmongMembers(
        Repo storage repo, uint[] memory members, Drop memory drop,
        IRegisterOfMembers _rom, uint amt,uint totalPoints
    ) private {
        uint len = members.length;
        uint sum = 0;

        while (len > 1) {
            drop.member = uint40(members[len-1]);
            drop.income = 
                uint64(amt * _rom.pointsOfMember(drop.member).points / totalPoints);

            sum += drop.income;
            
            _addDrop(repo, drop, TWO_TO_32);

            len--;
        }

        drop.member = uint40(members[0]);
        drop.income = uint64(amt - sum);
        _addDrop(repo, drop, TWO_TO_32);
    }

    // ---- IntFrontDistr ----

    /// @notice Distribute interest-first by tiers.
    /// @param repo Storage repo.
    /// @param amt Amount to distribute.
    /// @param _ros Register of shares.
    /// @param rule Distribution rule.
    function intFrontDistr(
        Repo storage repo, uint amt, IRegisterOfShares _ros, 
        RulesParser.DistrRule memory rule
    ) public returns(
        Drop memory drop,
        Drop[] memory mList, 
        Drop[] memory sList
    ) {
        drop = _createDrop(repo);

        uint i = 0;
        while (amt > 0 && i < rule.numOfTiers) {
            drop.class = rule.tiers[i];
            amt = _intFrontDistr(repo, rule, rule.rates[i], amt, _ros, drop);
            i++;
        }

        mList = getCreeksOfStream(repo, drop.seqOfDistr);
        sList = getDropsOfStream(repo, drop.seqOfDistr);
    }

    function _updateGulfInfo (
        Drop storage gulfInfo,
        uint interests,
        uint interestsBalance,
        uint principal,
        uint distrDate
    ) private {
        gulfInfo.income += uint64(interests + interestsBalance);
        gulfInfo.principal += uint64(principal);
        gulfInfo.distrDate = uint48(distrDate);
    }

    function _intFrontDistr(
        Repo storage repo, RulesParser.DistrRule memory rule, uint rate, uint amt, 
        IRegisterOfShares _ros, Drop memory drop
    ) private returns(uint balance) {

        Drop memory seaInfo = getSeaInfo(repo, drop.class);
        Drop storage gulfInfo = 
            repo.streams[0].creeks[1].flows[drop.class].drops[0];

        uint principal = seaInfo.principal;

        uint secs = rule.isCumulative 
            ? drop.distrDate - gulfInfo.distrDate 
            : drop.distrDate - (drop.seqOfDistr > 1 
                ? getStreamInfo(repo, drop.seqOfDistr - 1).distrDate
                : gulfInfo.distrDate) ;

        uint interests = rate * principal * secs / (365 * 10000 * 86400);
        uint interestsBalance = (seaInfo.income - gulfInfo.income);

        if (rule.isCumulative) interests -= interestsBalance;
        
        if (rate == 0) {
            if (rule.refundPrincipal) {
                if (amt >= principal) {
                    interests = amt - principal;
                } else principal = amt;
            } else {
                interests = amt;
                principal = 0;
            }
            _updateGulfInfo(gulfInfo, interests, interestsBalance, principal, drop.distrDate);
        } else {            
            if (rule.refundPrincipal) {
                if (amt < interests) {
                    interests = amt;
                    principal = 0;
                } else {
                    if (amt < interests + principal){
                        principal = amt - interests;
                    } else {
                        balance = amt - (principal + interests);
                    }
                    _updateGulfInfo(gulfInfo, interests, interestsBalance, principal, drop.distrDate);
                }
            } else {
                principal = 0;
                if (amt < interests) {
                    interests = amt;
                } else {
                    _updateGulfInfo(gulfInfo, interests, interestsBalance, principal, drop.distrDate);
                    balance = amt - interests;
                }
            }
        }

        _distrAmongShares(repo, _ros, drop, principal, interests);
    }

    // ---- PrinFrontDistr ----

    /// @notice Distribute principal-first by tiers.
    /// @param repo Storage repo.
    /// @param amt Amount to distribute.
    /// @param _ros Register of shares.
    /// @param rule Distribution rule.
    function prinFrontDistr(
        Repo storage repo, uint amt, IRegisterOfShares _ros, 
        RulesParser.DistrRule memory rule
    ) public returns(
        Drop memory drop,
        Drop[] memory mList, 
        Drop[] memory sList
    ) {
        drop = _createDrop(repo);

        uint i = 0;
        while (amt > 0 && i < rule.numOfTiers) {
            drop.class = rule.tiers[i];
            amt= _prinFrontDistr(repo, rule.rates[i], amt, drop);
            _distrAmongShares(repo, _ros, drop, drop.principal, drop.income);
            i++;
        }

        mList = getCreeksOfStream(repo, drop.seqOfDistr);
        sList = getDropsOfStream(repo, drop.seqOfDistr);
    }

    function _getInterestsPayable(
        Repo storage repo, uint class, uint rate
    ) private view returns(uint interests) {
        Drop memory initSeaInfo = getInitSeaInfo(repo, class);
        uint[] memory distrList = repo.streams[0].creeks[0].flows[class].shares;
        uint len = distrList.length;
        while(len > 0 && rate > 0) {
            Drop memory drop = 
                repo.streams[distrList[len-1]].creeks[0].flows[class].drops[0];
            if (drop.principal > 0) {
                interests += (drop.principal * rate * (drop.distrDate - initSeaInfo.distrDate) / (365 * 10000 * 86400) - drop.income);
            }
            len--; 
        }
    }

    function _updateIsland(
        Repo storage repo, Drop memory drop
    ) private {
        Flow storage island = repo.streams[drop.seqOfDistr].creeks[0].flows[drop.class];

        if (island.drops[0].seqOfDistr == 0) {
            island.drops[0].seqOfDistr = drop.seqOfDistr;
            island.drops[0].class = drop.class;
            island.drops[0].distrDate = drop.distrDate;
            repo.streams[0].creeks[0].flows[drop.class].shares.push(drop.seqOfDistr);        
        }

        island.drops[0].principal += drop.principal;
        island.drops[0].income += drop.income;
    }

    function _prinFrontDistr(
        Repo storage repo, uint rate, uint amt, Drop memory drop
    ) private returns(uint balance) {

        Drop memory initSeaInfo = getInitSeaInfo(repo, drop.class);
        Drop memory seaInfo = getSeaInfo(repo, drop.class);
        Drop memory islandInfo = getIslandInfo(repo, drop.class, drop.seqOfDistr);
        
        drop.principal = seaInfo.principal - islandInfo.principal;
        drop.income = uint64(_getInterestsPayable(repo, drop.class, rate));
        
        if (drop.principal > 0 && rate > 0) {
            drop.income += uint64(drop.principal * rate * (drop.distrDate - initSeaInfo.distrDate) / (365 * 10000 * 86400));
        }
        
        if (amt < drop.principal) {
            drop.principal = uint64(amt);
            drop.income = 0;
        } else {
            if (amt < drop.principal + drop.income || rate == 0){
                drop.income = uint64(amt - drop.principal);
            } else {
                balance = amt - (drop.principal + drop.income);
            }
        }
        
        _updateIsland(repo, drop);
    }

    // ---- HurdleCarry ----

    /// @notice Distribute with hurdle carry to fund manager.
    /// @param repo Storage repo.
    /// @param amt Amount to distribute.
    /// @param _ros Register of shares.
    /// @param rule Distribution rule.
    /// @param fundManager Manager user number.
    function hurdleCarryDistr(
        Repo storage repo, uint amt, IRegisterOfShares _ros, 
        RulesParser.DistrRule memory rule, uint fundManager
    ) public returns(
        Drop memory drop,
        Drop[] memory mList, 
        Drop[] memory sList
    ) {

        drop = _createDrop(repo);

        drop.class = rule.tiers[0];
        uint i = 0;

        uint principal;
        uint interests;
        uint bonus;

        uint balance;

        while(amt > 0 && i <= rule.numOfTiers) {

            uint ratio = rule.tiers[i+1];
            uint dvd = amt * ratio / 10000;

            balance = _prinFrontDistr(repo, rule.rates[i], dvd, drop);

            uint carry = balance > 0
                ? (dvd - balance) * (10000 - ratio) / ratio 
                : amt - dvd;

            amt -= (dvd - balance + carry);

            principal += drop.principal;
            interests += drop.income;
            bonus += carry;

            i++;
        }

        _distrAmongShares(repo, _ros, drop, principal, interests);
        _assignCarryToManager(repo, drop, fundManager, bonus);

        mList = getCreeksOfStream(repo, drop.seqOfDistr);
        sList = getDropsOfStream(repo, drop.seqOfDistr);
    }

    // ---- Private Funcs ----

    function _createDrop(
        Repo storage repo
    ) private view returns(
        Drop memory drop    
    ) {
        drop.seqOfDistr = getOceanInfo(repo).seqOfDistr + 1;
        drop.distrDate = uint48(block.timestamp);
    }

    function _removeTail(Drop memory drop, SharesRepo.Share memory share)private pure {
        if (drop.principal/100 > share.body.paid) {
            drop.principal = share.body.paid * 100;
        } else if ((drop.principal / 100 < share.body.paid) &&
            (share.body.paid * 100 - drop.principal <= 100)) {
            drop.principal = share.body.paid * 100;
        }
    }

    function _distrAmongShares(
        Repo storage repo, IRegisterOfShares _ros, Drop memory drop,
        uint principal, uint interests
    ) private {

        SharesRepo.Share[] memory shares = 
            _ros.getSharesOfClass(drop.class);

        uint sum = _ros.getInfoOfClass(drop.class).body.par;

        uint len = shares.length;
        uint i = 1;
        uint totalPrincipal = 0;
        uint totalInterests = 0;
        SharesRepo.Share memory share;

        while (i < len) {
            share = shares[i];
            drop.member = share.head.shareholder;
            drop.income = uint64(interests * share.body.par / sum);
            drop.principal = uint64(principal * share.body.par / sum);
            
            _removeTail(drop, share);

            totalPrincipal += drop.principal;
            totalInterests += drop.income;

            _addDrop(repo, drop, share.head.seqOfShare);

            i++;
        }
        share = shares[0];
        drop.member = share.head.shareholder;
        drop.income = uint64(interests - totalInterests);
        drop.principal = uint64(principal - totalPrincipal);

        _removeTail(drop, share);

        _addDrop(repo, drop, share.head.seqOfShare);
    }

    function _assignCarryToManager(
        Repo storage repo, Drop memory drop, uint fundManager, uint carry
    ) private {
        drop.member = uint40(fundManager);
        drop.principal = 0;
        drop.income = uint64(carry);

        _addDrop(repo, drop, TWO_TO_32);
    }

    // ---- Update Water Fall ----

    function _addDrop(Repo storage repo, Drop memory drop, uint seqOfShare) private {

        // ==== Sum Info ====

        Drop storage ocean = 
            repo.streams[0].creeks[0].flows[0].drops[0];

        if (ocean.seqOfDistr < drop.seqOfDistr) {
            ocean.seqOfDistr = drop.seqOfDistr;
            ocean.distrDate = drop.distrDate;
        }

        ocean.principal += drop.principal;
        ocean.income += drop.income;

        // ==== Class Centered ====

        Drop storage sea = 
            repo.streams[0].creeks[0].flows[drop.class].drops[0];

        if (sea.seqOfDistr < drop.seqOfDistr) {
            sea.seqOfDistr = drop.seqOfDistr;
            sea.distrDate = drop.distrDate;
        }

        if (sea.principal >= drop.principal) {
            sea.principal -= drop.principal;
        } else revert("WR.addDrop: principal overflow");

        sea.income += drop.income;

        // ==== Distribution Centered ====

        Stream storage stream = 
            repo.streams[drop.seqOfDistr];

        Creek storage creek = 
            stream.creeks[drop.member];

        Flow storage flow = 
            creek.flows[drop.class];

        Drop storage d = 
            flow.drops[seqOfShare];

        if (d.distrDate == 0) {
            flow.drops[seqOfShare] = drop;
            d.distrDate = uint32(seqOfShare);
            flow.shares.push(d.distrDate);
        } else {
            d.principal += drop.principal;
            d.income += drop.income;
        }

        if (flow.drops[0].distrDate == 0) {
            flow.drops[0] = drop;
            creek.classes.push(drop.class);
        } else {
            flow.drops[0].principal += drop.principal;
            flow.drops[0].income += drop.income;
        }

        if (creek.flows[0].drops[0].distrDate == 0) {
            creek.flows[0].drops[0] = drop;
            stream.members.push(drop.member);
            creek.flows[0].drops[0].seqOfDistr = 1;
        } else {
            creek.flows[0].drops[0].seqOfDistr ++;
            creek.flows[0].drops[0].principal += drop.principal;
            creek.flows[0].drops[0].income += drop.income;
        }

        if (stream.creeks[0].flows[0].drops[0].distrDate == 0) {
            stream.creeks[0].flows[0].drops[0] = drop;
            stream.creeks[0].flows[0].drops[0].seqOfDistr = 1;
        } else {
            stream.creeks[0].flows[0].drops[0].seqOfDistr ++;
            stream.creeks[0].flows[0].drops[0].principal += drop.principal;
            stream.creeks[0].flows[0].drops[0].income += drop.income;
        }

        // ==== Member Centered ====

        Creek storage lake = 
            repo.streams[0].creeks[drop.member];

        Drop storage pool = 
            lake.flows[drop.class].drops[0];

        if (pool.distrDate == 0) {
            lake.flows[drop.class].drops[0] = drop;
            lake.classes.push(drop.class);
        } else {
            pool.principal += drop.principal;
            pool.income += drop.income;
        }

        if (lake.flows[0].drops[0].distrDate == 0) {
            lake.flows[0].drops[0] = drop;
            repo.streams[0].members.push(drop.member);
        } else {
            lake.flows[0].drops[0].principal += drop.principal;
            lake.flows[0].drops[0].income += drop.income;
        }

    }

    //####################
    //##     Read       ##
    //####################

    // ==== Distribution ====

    // ---- Drop ----

    /// @notice Get a specific drop by path.
    /// @param repo Storage repo.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    /// @param class Share class.
    /// @param seqOfShare Share sequence.
    function getDrop(
        Repo storage repo, uint seqOfDistr, uint member, uint class, uint seqOfShare
    ) public view returns(Drop memory drop) {
        drop = repo.streams[seqOfDistr].creeks[member].flows[class].drops[seqOfShare];
    }

    // ---- Flow ----

    /// @notice Get flow summary info.
    /// @param repo Storage repo.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    /// @param class Share class.
    function getFlowInfo(
        Repo storage repo, uint seqOfDistr, uint member, uint class
    ) public view returns(Drop memory info) {
        info = repo.streams[seqOfDistr].creeks[member].flows[class].drops[0];
    }

    /// @notice Get drops in a flow.
    /// @param repo Storage repo.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    /// @param class Share class.
    function getDropsOfFlow(
        Repo storage repo, uint seqOfDistr, uint member, uint class
    ) public view returns(Drop[] memory drops) {
        Flow storage flow = repo.streams[seqOfDistr].creeks[member].flows[class];
        uint len = flow.shares.length;
        drops = new Drop[](len);
        uint i = 0;
        while (i < len) {
            drops[i] = flow.drops[flow.shares[i]];
            i++;
        }
    }

    // ---- Creek ----

    /// @notice Get creek summary info.
    /// @param repo Storage repo.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    function getCreekInfo(
        Repo storage repo, uint seqOfDistr, uint member
    ) public view returns(Drop memory info) {
        info = repo.streams[seqOfDistr].creeks[member].flows[0].drops[0];
    }

    /// @notice Get all drops in a creek.
    /// @param repo Storage repo.
    /// @param seqOfDistr Distribution sequence.
    /// @param member Member user number.
    function getDropsOfCreek(
        Repo storage repo, uint seqOfDistr, uint member
    ) public view returns(Drop[] memory list) {
        Creek storage creek = repo.streams[seqOfDistr].creeks[member];
        Drop memory info = getCreekInfo(repo, seqOfDistr, member);
        list = new Drop[](info.seqOfDistr);
        uint[] memory ls = creek.classes;
        uint len = ls.length;
        uint i;
        while(len > 0) {
            Drop[] memory lsOfFlow = 
                getDropsOfFlow(repo, seqOfDistr, member, ls[len-1]);
            uint lenOfFlow = lsOfFlow.length;
            
            while(lenOfFlow > 0) {
                list[i] = lsOfFlow[lenOfFlow - 1];
                lenOfFlow--;
                i++;
            }

            len--;
        }
    }

    // ---- Stream ----

    /// @notice Get stream summary info.
    /// @param repo Storage repo.
    /// @param seqOfDistr Distribution sequence.
    function getStreamInfo(
        Repo storage repo, uint seqOfDistr
    ) public view returns(Drop memory info) {
        info = repo.streams[seqOfDistr].creeks[0].flows[0].drops[0];
    }

    /// @notice Get creeks in a stream.
    /// @param repo Storage repo.
    /// @param seqOfDistr Distribution sequence.
    function getCreeksOfStream(
        Repo storage repo, uint seqOfDistr
    ) public view returns(Drop[] memory list) {
        Stream storage stream = repo.streams[seqOfDistr];
        uint[] memory ls = stream.members;
        uint len = ls.length;
        list = new Drop[](len);
        uint i;
        while(i < len) {
            Drop memory info = 
                getCreekInfo(repo, seqOfDistr, ls[i]);
            list[i] = info;
            i++;
        }
    }

    /// @notice Get all drops in a stream.
    /// @param repo Storage repo.
    /// @param seqOfDistr Distribution sequence.
    function getDropsOfStream(
        Repo storage repo, uint seqOfDistr
    ) public view returns(Drop[] memory list) {
        Stream storage stream = repo.streams[seqOfDistr];
        Drop memory info = getStreamInfo(repo, seqOfDistr);
        list = new Drop[](info.seqOfDistr);
        uint[] memory ls = stream.members;
        uint len = ls.length;
        uint i;
        while(len > 0) {
            Drop[] memory lsOfCreek = 
                getDropsOfCreek(repo, seqOfDistr, ls[len-1]);
            uint lenOfCreek = lsOfCreek.length;
            
            while(lenOfCreek > 0) {
                list[i] = lsOfCreek[lenOfCreek - 1];
                lenOfCreek--;
                i++;
            }

            len--;
        }
    }

    // ==== Member ====

    /// @notice Get pool info for member/class.
    /// @param repo Storage repo.
    /// @param member Member user number.
    /// @param class Share class.
    function getPoolInfo(
        Repo storage repo, uint member, uint class
    ) public view returns(Drop memory info) {
        info = repo.streams[0].creeks[member].flows[class].drops[0];
    }

    /// @notice Get lake info for member.
    /// @param repo Storage repo.
    /// @param member Member user number.
    function getLakeInfo(
        Repo storage repo, uint member
    ) public view returns(Drop memory info) {
        info = repo.streams[0].creeks[member].flows[0].drops[0];
    }

    // ==== Class ====

    /// @notice Get initial sea info for class.
    /// @param repo Storage repo.
    /// @param class Share class.
    function getInitSeaInfo(
        Repo storage repo, uint class
    ) public view returns(Drop memory info) {
        info = repo.streams[0].creeks[TWO_TO_40].flows[class].drops[0];
    }

    /// @notice Get sea info for class.
    /// @param repo Storage repo.
    /// @param class Share class.
    function getSeaInfo(
        Repo storage repo, uint class
    ) public view returns(Drop memory info) {
        info = repo.streams[0].creeks[0].flows[class].drops[0];
    }

    /// @notice Get gulf info for class.
    /// @param repo Storage repo.
    /// @param class Share class.
    function getGulfInfo(
        Repo storage repo, uint class
    ) public view returns(Drop memory info) {
        info = repo.streams[0].creeks[1].flows[class].drops[0];
    }

    /// @notice Get island info for class and distribution.
    /// @param repo Storage repo.
    /// @param class Share class.
    /// @param seqOfDistr Distribution sequence.
    function getIslandInfo(
        Repo storage repo, uint class, uint seqOfDistr
    ) public view returns(Drop memory info) {
        info = repo.streams[seqOfDistr].creeks[0].flows[class].drops[0];
    }

    /// @notice Get list of classes in sea.
    /// @param repo Storage repo.
    function getListOfClasses(
        Repo storage repo
    ) public view returns(uint[] memory list) {
        list = repo.streams[0].creeks[0].classes;
    }

    /// @notice Get sea info list for all classes.
    /// @param repo Storage repo.
    function getAllSeasInfo(
        Repo storage repo
    ) public view returns(Drop[] memory list) {
        uint[] memory ls = getListOfClasses(repo);
        uint len = ls.length;
        list = new Drop[](len);
        uint i=0;

        while (i<len) {
            uint class = ls[i];
            list[i] = getSeaInfo(repo, class);
            i++;
        }
    }

    // ==== Sum ====

    /// @notice Get ocean info summary.
    /// @param repo Storage repo.
    function getOceanInfo(
        Repo storage repo
    ) public view returns(Drop memory info) {
        info = repo.streams[0].creeks[0].flows[0].drops[0];
    }

}

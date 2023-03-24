// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boa/IInvestmentAgreement.sol";

import "./DealsRepo.sol";


library TopChain {
    struct Node {
        uint40 prev;
        uint40 next;
        uint40 ptr;
        uint64 amt;
        uint64 sum;
        uint8 cat;
    }

    struct Chain {
        // usrNo => Node
        mapping(uint256 => Node) nodes;
    }

    /* Node[0] {
        prev: tail;
        next: head;
        ptr: qtyOfMembers;
        amt: maxQtyOfMembers;
        sum: totalVotes;
        cat: basedOnPar;
    } */

    //#################
    //##    修饰器    ##
    //#################

    modifier memberExist(Chain storage chain, uint256 acct) {
        require(isMember(chain, acct), "TC.memberExist: acct not member");
        _;
    }

    //#################
    //##    写接口    ##
    //#################

    // ==== Setting ====

    function setMaxQtyOfMembers(Chain storage chain, uint32 max) public {
        chain.nodes[0].amt = max;
    }

    function setVoteBase(Chain storage chain, bool onPar)
        public
        returns (bool flag)
    {
        if (onPar != basedOnPar(chain)) {
            chain.nodes[0].cat = onPar ? 1 : 0;
            flag = true;
        }
    }

    // ==== Node ====

    function addNode(Chain storage chain, uint256 acct)
        public
        returns (bool flag)
    {
        Node storage n = chain.nodes[acct];

        if (n.ptr == 0) {
            require(
                qtyOfMembers(chain) < maxQtyOfMembers(chain),
                "TC.addNode: qtyOfMembers overflow"
            );

            _increaseQtyOfMembers(chain);

            n.ptr = uint40(acct);

            // append to tail
            n.prev = chain.nodes[0].prev;
            chain.nodes[n.prev].next = uint40(acct);
            chain.nodes[0].prev = uint40(acct);

            flag = true;
        }
    }

    function delNode(Chain storage chain, uint256 acct)
        public
        returns (bool flag)
    {
        if (_carveOut(chain, acct)) {
            delete chain.nodes[acct];
            _decreaseQtyOfMembers(chain);
            flag = true;
        }
    }

    // ==== ChangeAmt ====

    function changeAmt(Chain storage chain, uint256 acct, uint64 deltaAmt, bool increase) 
        public memberExist(chain, acct) returns (bool flag) 
    {
        Node storage n = chain.nodes[acct];

        if (increase) {
            n.amt += deltaAmt;
            n.sum += deltaAmt;

            _increaseTotalVotes(chain, deltaAmt);
        } else {
            n.amt -= deltaAmt;
            n.sum -= deltaAmt;

            _decreaseTotalVotes(chain, deltaAmt);
        }

        if (n.cat == 2) {
            Node storage r = chain.nodes[n.ptr];

            if (increase) r.sum += deltaAmt;
            else r.sum -= deltaAmt;

            flag = _move(chain, n.ptr, increase);
        } else flag = _move(chain, uint40(acct), increase);
    }

    // ==== jumpChain ====

    function top2Sub(
        Chain storage chain,
        uint256 acct,
        uint256 root
    )
        public
        memberExist(chain, acct)
        memberExist(chain, root)
        returns (bool flag)
    {
        require(acct != root, "TC.T2S: self grouping");

        require(chain.nodes[acct].cat == 0, "TC.T2S: already in a branch");

        require(chain.nodes[root].cat < 2, "TC.T2S: leaf as root");

        flag = _carveOut(chain, acct) && _vInsert(chain, uint40(acct), uint40(root));
    }

    function sub2Top(Chain storage chain, uint256 acct)
        public
        memberExist(chain, acct)
        returns (bool flag)
    {
        Node storage n = chain.nodes[acct];

        require(n.cat > 0, "TC.S2T: not in a branch");

        if (_carveOut(chain, acct)) {
            n.cat = 0;
            n.sum = n.amt;

            (uint256 prev, uint256 next) = getPos(
                chain,
                n.sum,
                chain.nodes[0].prev,
                0,
                true
            );

            flag = _hInsert(chain, uint40(acct), uint40(prev), uint40(next));
        }
    }

    // ==== restoreChain ====

    function restoreChain(Chain storage chain, Node[] memory snapshot)
        public
    {
        // copy parasOfTopChain
        chain.nodes[0] = snapshot[0];

        uint256 acct = snapshot[0].next;
        uint256 i = 1;

        while (acct > 0) {
            chain.nodes[acct] = snapshot[i];
            acct = nextNode(chain, acct);
            i++;
        }
    }

    // ==== CarveOut ====

    function _branchOff(Chain storage chain, uint256 root)
        private
        returns (bool flag)
    {
        Node storage r = chain.nodes[root];

        chain.nodes[r.prev].next = r.next;
        chain.nodes[r.next].prev = r.prev;

        flag = true;
    }

    function _carveOut(Chain storage chain, uint256 acct)
        private
        memberExist(chain, acct)
        returns (bool flag)
    {
        Node storage n = chain.nodes[acct];

        if (n.cat == 0) {
            flag = _branchOff(chain, acct);
        } else if (n.cat == 1) {
            chain.nodes[n.prev].next = n.ptr;
            chain.nodes[n.next].prev = n.ptr;

            Node storage d = chain.nodes[n.ptr];

            d.ptr = d.next;
            d.prev = n.prev;
            d.next = n.next;
            d.cat = 1;

            d.sum = n.sum - n.amt;

            uint40 cur = d.ptr;
            while (cur > 0) {
                chain.nodes[cur].ptr = n.ptr;
                cur = chain.nodes[cur].next;
            }

            _move(chain, n.ptr, false);

            flag = true;
        } else if (n.cat == 2) {
            Node storage u = chain.nodes[n.prev];

            if (n.next > 0) chain.nodes[n.next].prev = n.prev;

            if (u.cat == 2) u.next = n.next;
            else if (n.next > 0) {
                u.ptr = n.next;
            } else {
                u.ptr = n.ptr;
                u.cat = 0;
            }

            chain.nodes[n.ptr].sum -= n.amt;

            _move(chain, n.ptr, false);

            flag = true;
        }
    }

    // ==== Insert ====

    function _hInsert(
        Chain storage chain,
        uint40 acct,
        uint40 prev,
        uint40 next
    ) private returns (bool flag) {
        Node storage n = chain.nodes[acct];

        chain.nodes[prev].next = acct;
        n.prev = prev;

        chain.nodes[next].prev = acct;
        n.next = next;

        flag = true;
    }

    function _vInsert(
        Chain storage chain,
        uint40 acct,
        uint40 root
    ) private returns (bool flag) {
        Node storage n = chain.nodes[acct];
        Node storage r = chain.nodes[root];

        if (r.cat == 0) {
            r.cat = 1;

            n.next = 0;
        } else if (r.cat == 1) {
            n.next = r.ptr;
            chain.nodes[n.next].prev = acct;
        }

        n.prev = root;
        n.ptr = root;
        n.cat = 2;

        r.ptr = acct;
        r.sum += n.amt;

        _move(chain, root, true);

        flag = true;
    }

    // ==== Move ====

    function _move(
        Chain storage chain,
        uint40 acct,
        bool increase
    ) private returns (bool flag) {
        Node storage n = chain.nodes[acct];

        (uint256 prev, uint256 next) = getPos(
            chain,
            n.sum,
            n.prev,
            n.next,
            increase
        );

        if (next != n.next || prev != n.prev) {
            flag = _branchOff(chain, acct) && _hInsert(chain, acct, uint40(prev), uint40(next));
        }
    }

    // ==== node[0] setting ====

    function _increaseQtyOfMembers(Chain storage chain) private {
        chain.nodes[0].ptr++;
    }

    function _decreaseQtyOfMembers(Chain storage chain) private {
        chain.nodes[0].ptr--;
    }

    function _increaseTotalVotes(Chain storage chain, uint64 deltaAmt) private {
        chain.nodes[0].sum += deltaAmt;
    }

    function _decreaseTotalVotes(Chain storage chain, uint64 deltaAmt) private {
        chain.nodes[0].sum -= deltaAmt;
    }

    //##################
    //##    读接口    ##
    //##################

    function isMember(Chain storage chain, uint256 acct)
        public
        view
        returns (bool)
    {
        return acct > 0 && chain.nodes[acct].ptr != 0;
    }

    // ==== Zero Node ====

    function tail(Chain storage chain) public view returns (uint40) {
        return chain.nodes[0].prev;
    }

    function head(Chain storage chain) public view returns (uint40) {
        return chain.nodes[0].next;
    }

    function qtyOfMembers(Chain storage chain) public view returns (uint32) {
        return uint32(chain.nodes[0].ptr);
    }

    function maxQtyOfMembers(Chain storage chain)
        public
        view
        returns (uint32)
    {
        return uint32(chain.nodes[0].amt);
    }

    function totalVotes(Chain storage chain) public view returns (uint64) {
        return chain.nodes[0].sum;
    }

    function basedOnPar(Chain storage chain) public view returns (bool) {
        return chain.nodes[0].cat == 1;
    }

    // ==== locate position ====

    function getPos(
        Chain storage chain,
        uint256 amount,
        uint256 prev,
        uint256 next,
        bool increase
    ) public view returns (uint256, uint256) {
        if (increase)
            while (prev > 0 && chain.nodes[prev].sum < amount) {
                next = prev;
                prev = chain.nodes[prev].prev;
            }
        else
            while (next > 0 && chain.nodes[next].sum > amount) {
                prev = next;
                next = chain.nodes[next].next;
            }

        return (prev, next);
    }

    function nextNode(Chain storage chain, uint256 acct)
        public
        view
        returns (uint256 next)
    {
        Node storage n = chain.nodes[acct];

        if (n.cat == 0) {
            next = n.next;
        } else if (n.cat == 1) {
            next = n.ptr;
        } else if (n.cat == 2) {
            next = (n.next > 0) ? n.next : chain.nodes[n.ptr].next;
        }
    }

    function getNode(Chain storage chain, uint256 acct)
        public
        view
        returns (Node memory n)
    {
        n = chain.nodes[acct];
    }

    // ==== group ====

    function rootOf(Chain storage chain, uint256 acct)
        public
        view
        memberExist(chain, acct)
        returns (uint40 group)
    {
        Node storage n = chain.nodes[acct];
        group = (n.cat < 2) ? uint40(acct) : n.ptr;
    }

    function qtyOfBranches(Chain storage chain)
        public
        view
        returns (uint256 len)
    {
        uint256 cur = head(chain);

        while (cur > 0) {
            len++;
            cur = chain.nodes[cur].next;
        }
    }

    function deepOfBranch(Chain storage chain, uint256 acct)
        public
        view
        memberExist(chain, acct)
        returns (uint256 deep)
    {
        Node storage n = chain.nodes[acct];

        if (n.cat == 0) deep = 1;
        else if (n.cat == 1) deep = _deepOfBranch(chain, acct);
        else deep = _deepOfBranch(chain, n.ptr);
    }

    function _deepOfBranch(Chain storage chain, uint256 root)
        private
        view
        returns (uint256 deep)
    {
        deep = 1;

        uint40 next = chain.nodes[root].ptr;

        while (next > 0) {
            deep++;
            next = chain.nodes[next].next;
        }
    }

    function votesOfGroup(Chain storage chain, uint256 acct)
        public
        view
        returns (uint64 votes)
    {
        uint256 group = rootOf(chain, acct);
        votes = chain.nodes[group].sum;
    }

    function membersOfGroup(Chain storage chain, uint256 acct)
        public
        view
        returns (uint256[] memory)
    {
        uint256 start = rootOf(chain, acct);
        uint256 len = deepOfBranch(chain, acct);

        return _subList(chain, start, len);
    }

    function affiliated(
        Chain storage chain,
        uint256 acct1,
        uint256 acct2
    )
        public
        view
        memberExist(chain, acct1)
        memberExist(chain, acct2)
        returns (bool)
    {
        Node storage n1 = chain.nodes[acct1];
        Node storage n2 = chain.nodes[acct2];

        return n1.ptr == n2.ptr || n1.ptr == acct2 || n2.ptr == acct1;
    }

    // ==== members ====

    function membersList(Chain storage chain)
        public
        view
        returns (uint256[] memory)
    {
        uint256 len = qtyOfMembers(chain);
        uint256 start = chain.nodes[0].next;

        return _subList(chain, start, len);
    }

    function _subList(
        Chain storage chain,
        uint256 start,
        uint256 len
    ) private view returns (uint256[] memory) {
        uint256[] memory list = new uint256[](len);
        uint256 i = 0;

        uint256 next = start;

        while (i < len) {
            list[i] = next;
            next = nextNode(chain, next);
            i++;
        }

        return list;
    }

    // ==== backup ====

    function getSnapshot(Chain storage chain)
        public
        view
        returns (Node[] memory)
    {
        uint256 len = qtyOfMembers(chain);

        Node[] memory list = new Node[](len + 1);

        list[0] = chain.nodes[0];

        uint256 cur = chain.nodes[0].next;
        uint256 i = 1;

        while (i <= len) {
            list[i] = chain.nodes[cur];
            cur = nextNode(chain, cur);
            i++;
        }

        return list;
    }

    // ==== MockDeals ====

    function mockDealsOfIA(
        Chain storage chain,
        IInvestmentAgreement _ia
    ) public {
        uint256[] memory snList = _ia.getSNList();

        uint256 len = snList.length;

        while (len > 0) {
            DealsRepo.Deal memory deal = _ia.getDeal(snList[len-1]);

            uint64 amount = basedOnPar(chain) ? deal.body.par : deal.body.paid;

            if (deal.head.seller > 0) {
                mockDealOfSell(chain, deal.head.seller, amount);
            }

            mockDealOfBuy(chain, deal.body.buyer, deal.body.groupOfBuyer, amount);

            len--;
        }
    }

    function mockDealOfSell(
        Chain storage chain, 
        uint256 seller, 
        uint64 amount
    ) public returns (bool flag)
    {
        changeAmt(chain, seller, amount, false);
        
        if (chain.nodes[seller].amt == 0)
            delNode(chain, seller);
        flag = true;
    }

    function mockDealOfBuy(
        Chain storage chain, 
        uint256 buyer, 
        uint256 group,
        uint64 amount
    ) public returns (bool flag) {
        if (!isMember(chain, buyer))
            addNode(chain, buyer);

        changeAmt(chain, buyer, amount, true);

        if (rootOf(chain, buyer) != group)
            top2Sub(chain, buyer, group);

        flag = true;
    }

}

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

library GoldChain_2 {

    struct Node {
        uint32 prev;
        uint32 next;
        uint40 issuer;
        uint64 paid;
        uint32 price;
        uint48 expireDate;
        bool isOffer;
    }

    struct Data {
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 groupRep;
        uint16 votingWeight;
        uint16 distrWeight;
        uint64 centPriceInWei;
        uint40 buyer;
        uint32 seq;
    }

    struct Order {
        Node node;
        Data data;
    }
    
    /* node[0] {
        prev: tail;
        next: head;
        price: counter;
    } */

   /* data[0] {
        seq: length;
   }*/

    struct Chain {
        mapping (uint => Order) orders;
    }

    //#################
    //##  Modifier   ##
    //#################

    // modifier nodeExist(Chain storage chain,uint seq) {
    //     require(isNode(chain, seq),"GC.nodeExist: not");
    //     _;
    // }

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Node ====

    function parseNode(
        bytes32 sn
    ) public pure returns(Node memory node) {

        uint _sn = uint(sn);

        node.prev = uint32(_sn >> 224);
        node.next = uint32(_sn >> 192);
        node.issuer = uint40(_sn >> 152);
        node.paid = uint64(_sn >> 88);
        node.price = uint32(_sn >> 56);
        node.expireDate = uint48(_sn >> 8);
        node.isOffer = uint8(_sn) == 1;
    }

    function codifyNode(
        Node memory node
    ) public pure returns(bytes32 sn) {

        bytes memory _sn = 
            abi.encodePacked(
                node.prev,
                node.next,
                node.issuer,
                node.paid,
                node.price,
                node.expireDate,
                uint8(node.isOffer ? 1 : 0)
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }                
    }

    // ==== Data ====

    function parseData(
        bytes32 sn
    ) public pure returns(Data memory data) {

        uint _sn = uint(sn);

        data.classOfShare = uint16(_sn >> 240);
        data.seqOfShare = uint32(_sn >> 208);
        data.groupRep = uint40(_sn >> 168);
        data.votingWeight = uint16(_sn >> 152);
        data.distrWeight = uint16(_sn >> 136);
        data.centPriceInWei = uint64(_sn >> 72);
        data.buyer = uint40(_sn >> 32);
        data.seq = uint32(_sn);
    }

    function codifyData(
        Data memory data
    ) public pure returns(bytes32 sn) {
        bytes memory _sn = 
            abi.encodePacked(
                data.classOfShare,
                data.seqOfShare,
                data.groupRep,
                data.votingWeight,
                data.distrWeight,
                data.centPriceInWei,
                data.buyer,
                data.seq
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }                        
    }

    // ==== Node ====

    function createNode(
        Chain storage chain,
        uint issuer,
        uint paid,
        uint price,
        uint execHours,
        bool isOffer,
        Data memory data
    ) public {

        require (uint64(paid) > 0, 'GC.createNode: zero paid');
        require (data.classOfShare > 0, "GC.addData: zero class");
        require (data.centPriceInWei > 0, "GC.addData: zero centPrice");

        data.seq = _increaseCounter(chain);

        chain.orders[data.seq].node = Node({
            prev:0,
            next:0,
            issuer: uint40(issuer),
            paid: uint64(paid),
            price: uint32(price),
            expireDate: uint48(block.timestamp + 3600 * execHours),
            isOffer: isOffer
        });
        
        chain.orders[data.seq].data = data;

        _increaseLength(chain);
        _upChain(chain, data.seq);
    }

    function _abs(uint32 a, uint32 b) private pure returns(uint32 c) {
        c = a > b ? a - b : b - a;
    }

    function _upChain(Chain storage chain,uint32 seq) private {

        Node storage node = chain.orders[seq].node;

        bool sortFromHead = 
            _abs(chain.orders[tail(chain)].node.price, node.price) > 
            _abs(chain.orders[head(chain)].node.price, node.price);

        (uint prev, uint next) = 
            _getPos(
                chain,
                node.price,
                sortFromHead ? 0 : tail(chain),
                sortFromHead ? head(chain) : 0,
                sortFromHead,
                node.isOffer
            );

        node.prev = uint32(prev);
        node.next = uint32(next);

        chain.orders[prev].node.next = seq;
        chain.orders[next].node.prev = seq;
    }

    function _getPos(
        Chain storage chain,
        uint price,
        uint prev,
        uint next,
        bool sortFromHead,
        bool isAscedning
    ) public view returns(uint, uint) {
        if (sortFromHead) {
            if (isAscedning) {
                while(next > 0 && chain.orders[next].node.price <= price) {
                    prev = next;
                    next = chain.orders[next].node.next;
                }
            } else {
                while(next > 0 && chain.orders[next].node.price >= price) {
                    prev = next;
                    next = chain.orders[next].node.next;
                }                
            }
        } else {
            if (isAscedning) {
                while(prev > 0 && chain.orders[prev].node.price > price) {
                    next = prev;
                    prev = chain.orders[prev].node.prev;
                }
            } else {
                while(prev > 0 && chain.orders[prev].node.price < price) {
                    next = prev;
                    prev = chain.orders[prev].node.prev;
                }
            }
        }
        return (prev, next);
    }
    
    function offChain(
        Chain storage chain, uint seq
    ) public returns(Order memory order) {

        require(isNode(chain, seq), "GC.offChain: Node not exist");

        order = chain.orders[seq];

        chain.orders[order.node.prev].node.next = order.node.next;
        chain.orders[order.node.next].node.prev = order.node.prev;

        delete chain.orders[seq];

        _decreaseLength(chain);
    }

    function _increaseCounter(
        Chain storage chain
    ) private returns (uint32 out) { 

        Node storage node = chain.orders[0].node;
        out = node.price;

        do {
            unchecked {
                out++;    
            }
        } while(isNode(chain, out) ||
            out == 0);

        node.price = out;
    }

    function _increaseLength(
        Chain storage chain
    ) private {
        chain.orders[0].data.seq++;
    }

    function _decreaseLength(
        Chain storage chain
    ) private {
        chain.orders[0].data.seq--;
    }

    //#################
    //##   Read I/O  ##
    //#################

    // ==== Node[0] ====

    function counter(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.orders[0].node.price;
    }

    function length(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.orders[0].data.seq;
    }

    function head(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.orders[0].node.next;
    }

    function tail(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.orders[0].node.prev;
    }

    // ==== Node ====
    
    function isNode(
        Chain storage chain, uint seq
    ) public view returns(bool) {
        return chain.orders[seq].node.expireDate > 0;
    } 

    function getNode(
        Chain storage chain, uint seq
    ) public view returns(Node memory node) {
        node = chain.orders[seq].node;
    }

    function getData(
        Chain storage chain, uint seq
    ) public view returns(Data memory data) {
        data = chain.orders[seq].data;
    }

    function getOrder(
        Chain storage chain, uint seq
    ) public view returns(Order memory order) {
        order = chain.orders[seq];
    }

    // ==== Chain ====

    function getSeqList(
        Chain storage chain
    ) public view returns (uint[] memory) {
        uint len = length(chain);
        uint[] memory list = new uint[](len);

        Node memory node = chain.orders[0].node;

        while (len > 0) {
            list[len-1] = node.prev;
            node = chain.orders[node.prev].node;
            len--;
        }

        return list;
    }

    function getChain(
        Chain storage chain
    ) public view returns (Order[] memory) {
        uint len = length(chain);
        Order[] memory list = new Order[](len);

        Node memory node = chain.orders[0].node;

        while (len > 0) {
            list[len-1] = chain.orders[node.prev];
            node = chain.orders[node.prev].node;
            len--;
        }

        return list;
    }
}

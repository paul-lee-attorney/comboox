// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library GoldChain {

    enum StateOfOrder {
        Active,
        Closed,
        Terminated
    }

    struct Order {
        uint32 seqOfOrder;
        uint32 prev;
        uint32 next;
        uint32 seqOfShare;
        uint16 classOfShare;
        uint40 offeror;
        uint64 paid;
        uint32 price;
        uint16 execHours;
        uint48 expireDate;
        uint32 seqOfDeal;
        uint8 state;
    }

    /* Orders[0] {
        seqOfOrder: counter;
        prev: tail;
        next: head;
        seqOfShare: lengthOfList;
    } */

    struct Chain {
        mapping (uint => Order) orders;
    }

    //#################
    //##  Write I/O  ##
    //#################

    function codifyOrder(Order memory order) public pure returns(bytes32 sn)
    {
        bytes memory _sn = abi.encodePacked(
            order.seqOfOrder,
            order.seqOfShare,
            order.classOfShare,
            order.offeror,
            order.paid,
            order.price
        );

        assembly {
            sn := mload(add(_sn, 0x20))
        }                
    }

    function createOrder(
        Chain storage chain,
        uint seqOfShare,
        uint classOfShare,
        uint offeror,
        uint execHours,
        uint paid,
        uint price
    ) public returns (uint32 seqOfOrder) {

        Order memory order = Order({
            seqOfOrder: _increaseCounterOfOrders(chain),
            prev: 0,
            next: 0,
            seqOfShare: uint32(seqOfShare),
            classOfShare: uint16(classOfShare),
            offeror: uint40(offeror),
            paid: uint64(paid),
            price: uint32(price),
            execHours: uint16(execHours),
            expireDate: uint48(block.timestamp) + uint48(execHours) * 3600,
            seqOfDeal: 0,
            state: 0            
        });

        // require (order.offeror > 0, 'GC.createOrder: zero offeror');
        require (order.paid > 0, 'GC.createOrder: zero paid');
        // require (order.price > 0, 'GC.createOrder: zero price');

        chain.orders[seqOfOrder] = order;
    }

    function _increaseCounterOfOrders(
        Chain storage chain
    ) public returns (uint32) {
        chain.orders[0].seqOfOrder++;
        return chain.orders[0].seqOfOrder;
    }

    function upList(
        Chain storage chain,
        bool isPutOrder,
        uint32 seqOfOrder
    ) public returns(Order memory listedOrder) {

        Order storage order = chain.orders[seqOfOrder];

        uint32 seqOfNode = getHeadSeqOfList(chain);
        Order memory node = chain.orders[seqOfNode];

        if (seqOfNode == 0) {

            chain.orders[0].next = seqOfOrder;
            chain.orders[0].prev = seqOfOrder;

        } else {

            do {
                if (isPutOrder) {
                    if (node.price > order.price) break;
                } else {
                    if (node.price < order.price) break;
                }
                node = chain.orders[node.next];
            } while (node.offeror > 0);

            order.prev = node.prev;
            order.next = chain.orders[node.prev].next;

            chain.orders[node.prev].next = seqOfOrder;
            chain.orders[order.next].prev = seqOfOrder;
        }

        chain.orders[0].seqOfShare++;

        listedOrder = chain.orders[seqOfOrder];
    }

    function offList(
        Chain storage chain,
        uint32 seqOfOrder
    ) public returns(uint32 next){

        Order storage order = chain.orders[seqOfOrder];

        require(order.state > uint8(StateOfOrder.Active), 
            "GC.offChain: wrong state");

        next = order.next;

        chain.orders[order.prev].next = next;
        chain.orders[next].prev = order.prev;

        order.prev = 0;
        order.next = 0;

        chain.orders[0].seqOfShare--;
    }

    //#################
    //##  Read I/O  ##
    //#################

    // ==== List ====

    function getHeadSeqOfList(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.orders[0].next;
    }

    function getTailSeqOfList(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.orders[0].prev;
    }

    function getLengthOfList(
        Chain storage chain
    ) public view returns (uint) {
        return chain.orders[0].seqOfShare;
    }

    function getList(
        Chain storage chain
    ) public view returns (Order[] memory) {
        uint len = getLengthOfList(chain);
        Order[] memory output = new Order[](len);

        Order memory node = chain.orders[getTailSeqOfList(chain)];

        while (len > 0) {
            output[len-1] = node;
            len--;
            node = chain.orders[node.prev];
        }

        return output;
    }

    // ==== Order ====

    function getCounterOfOrders(
        Chain storage chain
    ) public view returns (uint32) {
        return chain.orders[0].seqOfOrder;
    }
    
    function getOrder(
        Chain storage chain,
        uint seqOfOrder
    ) public view returns (Order memory ) {
        return chain.orders[seqOfOrder];
    }

    function getChain(
        Chain storage chain
    ) public view returns (Order[] memory) {
        uint len = getCounterOfOrders(chain);
        Order[] memory output = new Order[](len);

        while (len > 0) {
            output[len-1] = chain.orders[len];
            len--;
        }

        return output;
    }

}

// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */


function parseDrop(arr) {
    return {
        seqOfDistr: arr[0],
        member: arr[1],
        class: arr[2],
        distrDate: arr[3],
        principal: Number(arr[4].toString()),
        income: Number(arr[5].toString())
    };
}
    
module.exports = {
    parseDrop,
};


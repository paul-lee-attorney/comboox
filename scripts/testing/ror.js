// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseTimestamp, longDataParser, parseHexToBigInt } = require("./utils");

const parseRequest = (arr) => {
  return {
    class: arr[0],
    seqOfShare: arr[1],
    navPrice: Number(ethers.utils.formatUnits(arr[2], 4)),
    shareholder: arr[3],
    paid: Number(ethers.utils.formatUnits(arr[4], 4)),
    value: Number(ethers.utils.formatUnits(arr[5], 4)),
    seqOfPacks: arr[6],
  };
}



module.exports = {
    parseRequest,
};

  
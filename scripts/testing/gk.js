// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseTimestamp } = require("./utils");

const parseCompInfo = (arr) => {
  const info = {
    regNum: arr[0],
    regDate: parseTimestamp(arr[1]),
    currency: arr[2],
    state: arr[3],
    symbol: ethers.utils.toUtf8String(arr[4]),
    name: arr[5],
  }

  return info;
}

module.exports = {
  parseCompInfo,
};

  
// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseTimestamp } = require("./utils");

const currencies = [
  'USD', 'GBP', 'EUR', 'JPY', 'KRW', 'CNY',
  'AUD', 'CAD', 'CHF', 'ARS', 'PHP', 'NZD', 
  'SGD', 'NGN', 'ZAR', 'RUB', 'INR', 'BRL'
]



const parseCompInfo = (arr) => {
  const info = {
    regNum: arr[0],
    regDate: parseTimestamp(arr[1]),
    currency: currencies[arr[2]],
    state: arr[3],
    symbol: ethers.utils.toUtf8String(arr[4]).replace(/\x00/g, ""),
    name: arr[5],
  }

  return info;
}

module.exports = {
  parseCompInfo,
};

  
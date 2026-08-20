// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { formatUnits } from "ethers";

const parseRequest = (arr) => {
  return {
    class: arr[0],
    seqOfShare: arr[1],
    navPrice: Number(formatUnits(arr[2], 4)),
    shareholder: arr[3],
    paid: Number(formatUnits(arr[4], 4)),
    value: Number(formatUnits(arr[5], 4)),
    seqOfPacks: arr[6],
  };
}

export {
    parseRequest,
};

  
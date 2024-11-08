// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const printMembers = async (rom) => {
  const members = (await rom.membersList()).map(v => v.toString());
  console.log('Members of the Comp:', members, '\n');
}

module.exports = {
    printMembers,
};

  
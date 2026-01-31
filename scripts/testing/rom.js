// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const getAllMembers = async (rom) => {
  const membersList = (await rom.membersList()).map(v => Number(v));  
  return membersList;
}

const printMembers = async (rom) => {
  const members = await getAllMembers(rom);
  console.log('Members of the Comp:', members, '\n');
}

export {
    getAllMembers,
    printMembers,
};

  
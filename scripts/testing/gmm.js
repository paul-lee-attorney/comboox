// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { BigNumber } = require("ethers");
const { getAllMembers } = require("./rom");
const { Bytes32Zero, parseTimestamp, parseUnits } = require("./utils");

const typeOfMotion = [
  'ZeroPoint', 'Elect Officer', 'Remove Officer', 'Approve Doc',
  'Apporove Action', 'Transfer Fund', 'Distribute Profits', 'Deprecate GK'
];

const stateOfMotion = [
  'ZeroPoint', 'Created', 'Proposed', 'Passed', 'Rejected', 
  'Rejected_NotToBuy', 'Rejected_ToBuy', 'Executed'
];

const parseMotion = (arr) => {
  return {
    head: {
      typeOfMotion: typeOfMotion[arr[0][0]],
      seqOfMotion: arr[0][1],
      seqOfVR: arr[0][2],
      creator: arr[0][3],
      executor: arr[0][4],
      createDate: parseTimestamp(arr[0][5]),
      data: arr[0][5],
    },
    body: {
      proposer: arr[1][0],
      proposeDate: parseTimestamp(arr[1][1]),
      shareRegDate: parseTimestamp(arr[1][2]),
      voteStartDate: parseTimestamp(arr[1][3]),
      voteEndDate: parseTimestamp(arr[1][4]),
      para: arr[1][5],
      state: stateOfMotion[arr[1][6]],
    },
    votingRule: arr[2][0],
    contents: parseUnits(arr[3], 0),
  };
}

function motionSnParser(sn) {
  let head = {
    typeOfMotion: parseInt(sn.substring(2, 6), 16),
    seqOfMotion: BigNumber.from(`0x${sn.substring(6, 22)}`),
    seqOfVR: parseInt(sn.substring(22, 26), 16),
    creator: parseInt(sn.substring(26, 36), 16),
    executor: parseInt(sn.substring(36, 46), 16),
    createDate: parseInt(sn.substring(46, 58), 16),
    data: parseInt(sn.substring(58, 66), 16),
  }
  return head;
}

const getMotionsList = async (gmm) => {
  const motionsList = (await gmm.getSeqList()).map(v => Number(v));
  console.log('MotionsList:', motionsList, '\n');
  return motionsList;
}

const getLatestSeqOfMotion = async (gmm) => {
  const motionsList = await getMotionsList(gmm);
  const lastOne = motionsList[motionsList.length - 1];
  console.log('Last One:', lastOne, '\n');
  return lastOne;
}

const castSupportVote = async (gk, signer, seqOfMotion) => {
  await gk.connect(signer).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
}

const allSupportMotion = async (gk, rom, seqOfMotion) => {

  const signers = await hre.ethers.getSigners();

  const membersList = await getAllMembers(rom);
  let len = membersList.length;
  while (len > 0) {
    const userNo = membersList[len - 1];
    if (userNo < 3) {
      await castSupportVote(gk, signers[userNo - 1], seqOfMotion);
    } else {
      await castSupportVote(gk, signers[userNo], seqOfMotion);
    }
    len--;
  }
}

const allSupportLatestMotion = async (gk, rom, gmm) => {
  const seqOfMotion = await getLatestSeqOfMotion(gmm);
  await allSupportMotion(gk, rom, seqOfMotion);
}

module.exports = {
    motionSnParser,
    parseMotion,
    getLatestSeqOfMotion,
    getMotionsList,
    castSupportVote,
    allSupportMotion,
    allSupportLatestMotion,
    allSupportMotion,
};


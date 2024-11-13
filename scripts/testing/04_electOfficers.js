// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { getGK, getBMM, getGMM, getROD } = require('./boox');
const { positionParser } = require('./sha');
const { Bytes32Zero, increaseTime, parseTimestamp } = require('./utils');

async function main() {

    console.log('********************************');
    console.log('**        Elect Officers      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const bmm = await getBMM();
    const gmm = await getGMM();
    const rod = await getROD();
    
    // ==== Chairman ====

    await gk.nominateDirector(1, 1);
    const gmmList = (await gmm.getSeqList()).map(v => Number(v));
    console.log('obtained GMM List:', gmmList, "\n");

    let seqOfMotion = gmmList[gmmList.length - 1];

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);
    console.log('motion', seqOfMotion, 'is proposed ?', await gmm.isProposed(seqOfMotion), '\n');

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_1 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 1), '\n');

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_2 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 2), '\n');

    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_3 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 3), '\n');

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_4 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 4), '\n');

    await gk.voteCountingOfGM(seqOfMotion);
    console.log('Motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');
   
    await gk.takeSeat(seqOfMotion, 1);
    console.log('Chairman Position:', positionParser(await rod.getPosition(1)), "\n");    

    // ==== CEO ====

    await gk.nominateOfficer(2, 2);
    let bmmList = (await bmm.getSeqList()).map(v => Number(v));
    console.log('obtained BMM List:', bmmList, "\n");

    seqOfMotion = bmmList[bmmList.length - 1];

    await gk.proposeMotionToBoard(seqOfMotion);
    console.log('motion', seqOfMotion, 'is proposed ?', await bmm.isProposed(seqOfMotion), '\n');

    await gk.castVote(seqOfMotion, 1, Bytes32Zero);
    console.log('Chairman has voted for Motion', seqOfMotion, '?', await bmm.isVoted(seqOfMotion, 1), '\n');

    await gk.voteCounting(seqOfMotion);
    console.log('Motion', seqOfMotion, 'is passed ?', await bmm.isPassed(seqOfMotion), '\n');
    
    await gk.connect(signers[1]).takePosition(seqOfMotion, 2);
    console.log('CEO Position:', positionParser(await rod.getPosition(2)), "\n");
    
    // ==== Manager ====

    await gk.connect(signers[1]).nominateOfficer(3, 3);
    bmmList = (await bmm.getSeqList()).map(v => Number(v));
    console.log('obtained BMM List:', bmmList, "\n");

    seqOfMotion = bmmList[bmmList.length - 1];

    await gk.proposeMotionToBoard(seqOfMotion);
    console.log('motion', seqOfMotion, 'is proposed ?', await bmm.isProposed(seqOfMotion), '\n');

    await gk.castVote(seqOfMotion, 1, Bytes32Zero);
    console.log('User_1 has voted for Motion', seqOfMotion, '?', await bmm.isVoted(seqOfMotion, 1), '\n');

    await gk.voteCounting(seqOfMotion);
    console.log('Motion', seqOfMotion, 'is passed ?', await bmm.isPassed(seqOfMotion), '\n');
    
    await gk.connect(signers[3]).takePosition(seqOfMotion, 3);
    console.log('Manager Position:', positionParser(await rod.getPosition(3)), "\n");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  

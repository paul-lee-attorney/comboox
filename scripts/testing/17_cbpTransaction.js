// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { getGK, getRC, getGMM, getROM, getFT, } = require("./boox");
const { increaseTime, parseUnits, Bytes32Zero, now, } = require("./utils");
const { getLatestSeqOfMotion, allSupportLatestMotion, allSupportMotion, parseMotion } = require("./gmm");

async function main() {

    console.log('********************************');
    console.log('**       CBP Transactions     **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const ft = await getFT();
    const gk = await getGK();
    const rom = await getROM();
    const gmm = await getGMM();
    
    // ==== Motion for Mint CBP to DAO ====

    // selector of function mint(): 40c10f19
    let selector = ethers.utils.id("mint(address,uint256)").substring(0, 10);
    let firstInput = gk.address.substring(2).padStart(64, "0"); 
    let secondInput = parseUnits('88', 18).padStart(64, '0');
    let payload = selector + firstInput + secondInput;

    await gk.createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));
    console.log('motion for mint 88 cbp to GK is created:', motion, '\n');

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);
    motion = parseMotion(await gmm.getMotion(seqOfMotion));    
    console.log('motion:', seqOfMotion, 'proposed \n');

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);
    console.log('latest motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');

    // ---- Mint CBP to GK ----

    console.log('CBP balance of GK before:', ethers.utils.formatUnits((await rc.balanceOf(gk.address)).toString(), 18), '\n');
    await gk.execActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), seqOfMotion)
    console.log('minted 88 CBP to GK. \n');
    console.log('CBP balance of GK:', ethers.utils.formatUnits((await rc.balanceOf(gk.address)).toString(), 18), '\n');

    // ==== Motion for Transfer CBP to Fuel Tank ====
    const today = await now();
    const expireDate = today + 86400 * 3;
    
    await gk.proposeToTransferFund(false, ft.address, true, ethers.utils.parseUnits("88", 18) , expireDate, 9, 1);

    seqOfMotion = await getLatestSeqOfMotion(gmm);
    motion = parseMotion(await gmm.getMotion(seqOfMotion));
    console.log('motion for transfer 88 cbp to FT is proposed:', motion, '\n');

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    console.log('latest motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');
    await gk.voteCountingOfGM(seqOfMotion);
    console.log('latest motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');

    // ---- Transfer CBP to Fuel Tank ----

    console.log('CBP balance of FT before:', ethers.utils.formatUnits((await rc.balanceOf(ft.address)).toString(), 18), '\n');
    await gk.transferFund(false, ft.address, true, ethers.utils.parseUnits("88", 18), expireDate, seqOfMotion);
    console.log('transfer 88 CBP from GK to FT. \n');
    console.log('CBP balance of FT after:', ethers.utils.formatUnits((await rc.balanceOf(ft.address)).toString(), 18), '\n');
    console.log('CBP balance of GK after:', ethers.utils.formatUnits((await rc.balanceOf(gk.address)).toString(), 18), '\n');

    // ==== User-3 refuel gas from Fuel Tank ====
    console.log('CBP balance of User-3 before:', ethers.utils.formatUnits((await rc.balanceOf(signers[3].address)).toString(), 18), '\n');
    await ft.connect(signers[3]).refuel({value: ethers.utils.parseUnits("80", 18)});
    console.log('User-3 refuel 80 CBP from Fuel Tank.\n');
    console.log('CBP balance of User-3 after:', ethers.utils.formatUnits((await rc.balanceOf(signers[3].address)).toString(), 18), '\n');

    // ==== Pickup Income 80 ETH from Fuel Tank ====

    // ---- Motion for Pickup Income ----

    // selector of function withdrawIncome(uint256): 9273bbb6
    selector = ethers.utils.id("withdrawIncome(uint256)").substring(0, 10);
    firstInput = parseUnits("80", 18).padStart(64, '0');  // 80 ETH
    payload = selector + firstInput;

    await gk.createActionOfGM(9, [ft.address], [0], [payload], ethers.utils.id('9'+ft.address+payload), 1);

    seqOfMotion = await getLatestSeqOfMotion(gmm);
    console.log('motion for withdraw income from Fuel Tank is created:', seqOfMotion, '\n');

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);   
    console.log('motion proposed:', seqOfMotion, '\n');

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);
    console.log('latest motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');
    
    // ---- Pickup Income ----

    console.log('ETH balance of FT before:', ethers.utils.formatUnits((await ethers.provider.getBalance(ft.address)).toString(), 18), '\n');
    await gk.execActionOfGM(9, [ft.address], [0], [payload], ethers.utils.id('9'+ft.address+payload), seqOfMotion)
    console.log('collect 80 ETH from FT. \n');
    console.log('ETH balance of FT after:', ethers.utils.formatUnits((await ethers.provider.getBalance(ft.address)).toString(), 18), '\n');

    // ==== Withdraw Fuel 8 CBP from Fuel Tank ====

    // ---- Motion for Withdraw Fuel ----

    // selector of function withdrawFuel(uint256): bbc446ac
    selector = ethers.utils.id("withdrawFuel(uint256)").substring(0, 10);
    firstInput = parseUnits("8", 18).padStart(64, '0');  // 8 CBP
    payload = selector + firstInput;

    await gk.createActionOfGM(9, [ft.address], [0], [payload], ethers.utils.id('9'+ft.address+payload), 1);

    seqOfMotion = await getLatestSeqOfMotion(gmm);
    console.log('motion for withdraw fuel from Fuel Tank is created:', seqOfMotion, '\n');

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);
    console.log('motion proposed:', seqOfMotion, '\n');

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);
    console.log('latest motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');
    
    // ---- Withdraw Fuel ----

    console.log('CBP balance of FT before:', ethers.utils.formatUnits((await rc.balanceOf(ft.address)).toString(), 18), '\n');
    await gk.execActionOfGM(9, [ft.address], [0], [payload], ethers.utils.id('9'+ft.address+payload), seqOfMotion)
    console.log('collect 8 CBP from FT. \n');
    console.log('CBP balance of FT after:', ethers.utils.formatUnits((await rc.balanceOf(ft.address)).toString(), 18), '\n');

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  

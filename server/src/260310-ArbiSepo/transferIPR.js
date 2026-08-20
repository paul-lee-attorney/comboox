// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { expect } from "chai";
import { readTool } from "../../../scripts/readTool";
import { getTypeByName } from "../../../scripts/testing/boox";


async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**    Transfer IPR of Temps   **');
    console.log('********************************');
    console.log('\n');
    
    const rc = await readTool(
        "RegCenter", 
        "0xC78Cf69CEe2E015630C39EB0a1D65Eb799db8f03"
    );

    const userComp = BigInt(0x349fa3d960);

    const transferIPR = async (nameOfTemp)=>{
      const typeOfDoc = getTypeByName(nameOfTemp);

      let tx = await rc.transferIPR(typeOfDoc, 1, userComp);
      await tx.wait();
      
      await expect(tx).to.emit(rc, "TransferIPR").withArgs(typeOfDoc, 1, userComp);
      console.log(' \u2714 Passed Event Test for rc.transferIPR() with ', nameOfTemp, ' version 1. \n');
    }

    // await transferIPR("GeneralKeeper");
    // await transferIPR("ROCKeeper");
    // await transferIPR("RODKeeper");
    // await transferIPR("BMMKeeper");
    // await transferIPR("ROMKeeper");
    // await transferIPR("GMMKeeper");
    // await transferIPR("ROAKeeper");
    // await transferIPR("ROOKeeper");
    // await transferIPR("ROPKeeper");
    // await transferIPR("SHAKeeper");
    // await transferIPR("Accountant");
    // await transferIPR("ROIKeeper");
    // await transferIPR("LOOKeeper");

    // await transferIPR("RegisterOfConstitution");
    // await transferIPR("RegisterOfDirectors");
    // await transferIPR("MeetingMinutes");
    await transferIPR("RegisterOfMembers");
    await transferIPR("RegisterOfAgreements");
    await transferIPR("RegisterOfOptions");
    await transferIPR("RegisterOfPledges");
    await transferIPR("RegisterOfInvestors");
    await transferIPR("ListOfOrders");
    await transferIPR("Cashier");
    await transferIPR("RegisterOfRedemptions");

    await transferIPR("InvestmentAgreement");
    await transferIPR("ShareholdersAgreement");

    await transferIPR("AntiDilution");
    await transferIPR("LockUp");
    await transferIPR("Options");
    await transferIPR("Alongs");

    await transferIPR("FundROCKeeper");
    await transferIPR("FundGMMKeeper");
    await transferIPR("FundLOOKeeper");
    await transferIPR("FundROIKeeper");
    await transferIPR("FundRORKeeper");
    await transferIPR("FundAccountant");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


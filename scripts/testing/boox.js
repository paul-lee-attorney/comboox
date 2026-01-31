// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { join } from "path";
import { readFileSync } from "fs";
const __dirname = import.meta.dirname;

const tempsDir = join(__dirname, "..", "..", "server", "src", "contracts");

import { readTool } from "../readTool"; 

const fileNameOfTemps = join(tempsDir, "contracts-address.json");
const Temps = JSON.parse(readFileSync(fileNameOfTemps,"utf-8"));

const fileNameOfBoox = join(__dirname, "boox.json");
let Boox = JSON.parse(readFileSync(fileNameOfBoox));

const refreshBoox = () => {
  Boox = JSON.parse(readFileSync(fileNameOfBoox));
}

// ==== RegCenter ====

const getRC = async () => {
  return await readTool("RegCenter", Temps.RegCenter);
}

const getCNC = async () => {
  return await readTool("CreateNewComp", Temps.CreateNewComp);
}

// const getCNF = async () => {
//   return await readTool("CreateNewFund", Temps.CreateNewFund);
// }

// const getCNCUSD = async () => {
//   return await readTool("CreateNewCompUSD", Temps.CreateNewCompUSD);
// }

const getFT = async () => {
  return await readTool("UsdFuelTank", Temps.UsdFuelTank);
}

const getBR = async () => {
  return await readTool("BooksRepo", Temps.BooksRepo);
}

// ==== Boox ====

const getGK = async (addr) => {
  if (!addr) addr = Boox.GK;
  return await readTool("CompKeeper", addr);
}

const getFK = async (addr) => {
  if (!addr) addr = Boox.FundKeeper;
  return await readTool("FundKeeper", addr);
}

const getBMM = async () => {
  return await readTool("MeetingMinutes", Boox.BMM);
}

const getGMM = async () => {
  return await readTool("MeetingMinutes", Boox.GMM);
}

const getLOO = async () => {
  return await readTool("ListOfOrders", Boox.LOO);
}

const getROA = async () => {
  return await readTool("RegisterOfAgreements", Boox.ROA);
}

const getROC = async () => {
  return await readTool("RegisterOfConstitution", Boox.ROC);
}

const getSHA = async () => {
  return await readTool("ShareholdersAgreement", Boox.SHA);
}

const getROD = async () => {
  return await readTool("RegisterOfDirectors", Boox.ROD);
}

const getROI = async () => {
  return await readTool("RegisterOfInvestors", Boox.ROI);
}

const getROM = async () => {
  return await readTool("RegisterOfMembers", Boox.ROM);
}

const getROO = async () => {
  return await readTool("RegisterOfOptions", Boox.ROO);
}

const getROP = async () => {
  return await readTool("RegisterOfPledges", Boox.ROP);
}

const getROR = async () => {
  return await readTool("RegisterOfRedemptions", Boox.ROR);
}

const getROS = async () => {
  return await readTool("RegisterOfShares", Boox.ROS);
}

const getUSDC = async () => {
  return await readTool("MockUSDC", Boox.USDC);
}

const getCashier = async () => {
  return await readTool("Cashier", Boox.Cashier);
}

const getFundAccountant = async () => {
  return await readTool("FundAccountant", Boox.Accountant);
}

const getGMMKeeper = async () => {
  return await readTool("GMMKeeper", Boox.GMMKeeper);
}

const getLOOKeeper = async () => {
  return await readTool("LOOKeeper", Boox.LOOKeeper);
}

const getROAKeeper = async () => {
  return await readTool("ROAKeeper", Boox.ROAKeeper);
}

const getROMKeeper = async () => {
  return await readTool("ROMKeeper", Boox.ROMKeeper);
}

const getROOKeeper = async () => {
  return await readTool("ROOKeeper", Boox.ROOKeeper);
}

export {
  refreshBoox,
  getRC,
  getCNC,
  getCNF,
  getFT,
  getGK,
  getFK,
  getBMM,
  getGMM,
  getLOO,
  getROA,
  getROC,
  getROD,
  getROI,
  getROM,
  getROO,
  getROP,
  getROR,
  getROS,
  getSHA,
  getUSDC,
  getCashier,
  getFundAccountant,
  getGMMKeeper,
  getLOOKeeper,
  getROAKeeper,
  getROMKeeper,
  getROOKeeper,
};

  
// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const path = require("path");
const fs = require("fs");
const tempsDir = path.join(__dirname, "..", "..", "server", "src", "contracts");

const { readContract } = require("../readTool"); 

const fileNameOfTemps = path.join(tempsDir, "contracts-address.json");
const Temps = JSON.parse(fs.readFileSync(fileNameOfTemps,"utf-8"));

const fileNameOfBoox = path.join(__dirname, "boox.json");
let Boox = JSON.parse(fs.readFileSync(fileNameOfBoox));

const refreshBoox = () => {
  Boox = JSON.parse(fs.readFileSync(fileNameOfBoox));
}

// ==== RegCenter ====

const getRC = async () => {
  return await readContract("RegCenter", Temps.RegCenter);
}

const getCNC = async () => {
  return await readContract("CreateNewComp", Temps.CreateNewComp);
}

const getCNF = async () => {
  return await readContract("CreateNewFund", Temps.CreateNewFund);
}

// const getCNCUSD = async () => {
//   return await readContract("CreateNewCompUSD", Temps.CreateNewCompUSD);
// }

const getFT = async () => {
  return await readContract("UsdFuelTank", Temps.UsdFuelTank);
}

// ==== Boox ====

const getGK = async (addr) => {
  if (!addr) addr = Boox.GK;
  return await readContract("GeneralKeeper", addr);
}

const getFK = async (addr) => {
  if (!addr) addr = Boox.FundKeeper;
  return await readContract("FundKeeper", addr);
}

const getBMM = async () => {
  return await readContract("MeetingMinutes", Boox.BMM);
}

const getGMM = async () => {
  return await readContract("MeetingMinutes", Boox.GMM);
}

const getLOO = async () => {
  return await readContract("ListOfOrders", Boox.LOO);
}

const getROA = async () => {
  return await readContract("RegisterOfAgreements", Boox.ROA);
}

const getROC = async () => {
  return await readContract("RegisterOfConstitution", Boox.ROC);
}

const getSHA = async () => {
  return await readContract("ShareholdersAgreement", Boox.SHA);
}

const getROD = async () => {
  return await readContract("RegisterOfDirectors", Boox.ROD);
}

const getROI = async () => {
  return await readContract("RegisterOfInvestors", Boox.ROI);
}

const getROM = async () => {
  return await readContract("RegisterOfMembers", Boox.ROM);
}

const getROO = async () => {
  return await readContract("RegisterOfOptions", Boox.ROO);
}

const getROP = async () => {
  return await readContract("RegisterOfPledges", Boox.ROP);
}

const getROR = async () => {
  return await readContract("RegisterOfRedemptions", Boox.ROR);
}

const getROS = async () => {
  return await readContract("RegisterOfShares", Boox.ROS);
}

const getUSDC = async () => {
  return await readContract("MockUSDC", Boox.USDC);
}

const getCashier = async () => {
  return await readContract("Cashier", Boox.Cashier);
}

const getFundAccountant = async () => {
  return await readContract("FundAccountant", Boox.Accountant);
}

const getGMMKeeper = async () => {
  return await readContract("GMMKeeper", Boox.GMMKeeper);
}

const getLOOKeeper = async () => {
  return await readContract("LOOKeeper", Boox.LOOKeeper);
}

const getROAKeeper = async () => {
  return await readContract("ROAKeeper", Boox.ROAKeeper);
}

const getROMKeeper = async () => {
  return await readContract("ROMKeeper", Boox.ROMKeeper);
}

const getROOKeeper = async () => {
  return await readContract("ROOKeeper", Boox.ROOKeeper);
}

module.exports = {
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

  
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

const getCNCUSD = async () => {
  return await readContract("CreateNewCompUSD", Temps.CreateNewCompUSD);
}

const getFT = async () => {
  return await readContract("FuelTank", Temps.FuelTank);
}

// ==== Boox ====

const getGK = async (addr) => {
  if (!addr) addr = Boox.GK;
  return await readContract("GeneralKeeper", addr);
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

const getROD = async () => {
  return await readContract("RegisterOfDirectors", Boox.ROD);
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

const getROS = async () => {
  return await readContract("RegisterOfShares", Boox.ROS);
}

const getUSDC = async () => {
  return await readContract("MockUSDC", Boox.USDC);
}

const getCashier = async () => {
  return await readContract("Cashier", Boox.Cashier);
}

const getUsdLOO = async () => {
  return await readContract("UsdListOfOrders", Boox.UsdLOO);
}

const getGMMKeeper = async () => {
  return await readContract("GMMKeeper", Boox.GMMKeeper);
}

const getLOOKeeper = async () => {
  return await readContract("LOOKeeper", Boox.LOOKeeper);
}

const getUsdKeeper = async () => {
  return await readContract("USDKeeper", Boox.UsdKeeper);
}

const getUsdLOOKeeper = async () => {
  return await readContract("UsdLOOKeeper", Boox.UsdLOOKeeper);
}

const getUsdROAKeeper = async () => {
  return await readContract("UsdROAKeeper", Boox.UsdROAKeeper);
}

const getUsdROMKeeper = async () => {
  return await readContract("UsdROMKeeper", Boox.UsdROMKeeper);
}

const getUsdROOKeeper = async () => {
  return await readContract("UsdROOKeeper", Boox.UsdROOKeeper);
}

module.exports = {
  refreshBoox,
  getRC,
  getCNC,
  getCNCUSD,
  getFT,
  getGK,
  getBMM,
  getGMM,
  getLOO,
  getROA,
  getROC,
  getROD,
  getROM,
  getROO,
  getROP,
  getROS,
  getUSDC,
  getCashier,
  getUsdLOO,
  getGMMKeeper,
  getLOOKeeper,
  getUsdLOOKeeper,
  getUsdROAKeeper,
  getUsdROMKeeper,
  getUsdROOKeeper,
  getUsdKeeper,
};

  
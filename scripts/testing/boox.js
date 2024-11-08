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
const Boox = JSON.parse(fs.readFileSync(fileNameOfBoox));

// ==== RegCenter ====

const getRC = async () => {
  return await readContract("RegCenter", Temps.RegCenter);
}

const getCNC = async () => {
  return await readContract("CreateNewComp", Temps.CreateNewComp);
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

module.exports = {
  getRC,
  getCNC,
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
};

  
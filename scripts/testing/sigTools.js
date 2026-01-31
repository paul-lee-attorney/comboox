// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { join } from "path";
import { readFileSync } from "fs";
import { keccak256, toUtf8Bytes, AbiCoder, solidityPacked, recoverAddress, 
  isAddress, parseUnits, hexlify, randomBytes} from "ethers";

import { network } from "hardhat";

// const { getUSDC } = require("./boox.js");

const __dirname = import.meta.dirname;

const fileNameOfBoox = join(__dirname, "boox.json");
let Boox = JSON.parse(readFileSync(fileNameOfBoox));


// ==== Create Signature ====

const parseSignature = (sig) => {
  const r = '0x' + sig.slice(2, 66);  // First 32 bytes
  const s = '0x' + sig.slice(66, 130); // Next 32 bytes
  const v = parseInt(sig.slice(130, 132), 16); // last byte

  let out = {};
  out.r = r;
  out.s = s;
  out.v = v;

  return out;
}

const domain = {
  name: "USD Coin",
  version: "2",
  chainId: "31337",
  verifyingContract: Boox.USDC,
  // verifyingContract: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
}

const DOMAIN_TYPEHASH = keccak256(
  toUtf8Bytes(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  )
);

const TRANSFER_WITH_AUTHORIZATION_TYPEHASH = keccak256(
  toUtf8Bytes(
    "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
  )
);

const getDataHash = (auth) => {
  return keccak256(
    AbiCoder.encode(
      ["bytes32", "address", "address", "uint256", "uint256", "uint256", "bytes32"],
      [TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
      auth.from,
      auth.to,
      auth.value,
      auth.validAfter,
      auth.validBefore,
      auth.nonce],
    )
  )
}

const getDomainSeparator = ()=>{

  const nameHash = keccak256(toUtf8Bytes(domain.name));
  const versionHash = keccak256(toUtf8Bytes(domain.version));
  const chainIdBigInt = BigInt(domain.chainId);
  const verifyingContractAddress = domain.verifyingContract.toLowerCase();

  let separator = keccak256(    
    AbiCoder.encode(
      ["bytes32", "bytes32", "bytes32", "uint256", "address"],
      [DOMAIN_TYPEHASH, nameHash, versionHash, chainIdBigInt, verifyingContractAddress]
    )
  )
  console.log("DomainSeparator: ", separator);
  return separator;
};

const toTypedDataHash = (auth) => {
  const domainSeparator = getDomainSeparator();
  const dataHash = getDataHash(auth);
  const encodedData = solidityPacked(
    ["bytes2", "bytes32", "bytes32"],
    ["0x1901", domainSeparator, dataHash],
  );

  const out = keccak256(encodedData);

  // console.log("Domain Separator:", domainSeparator);
  // console.log("Data Hash:", dataHash);
  // console.log("typedDataHash:", out);

  return out;
}

const recoverSigner = (auth) => {
  const digest = toTypedDataHash(auth);

  // Convert inputs to BigNumbers for validation
  const sBigNum = BigInt(auth.s);
  const MAX_VALID_S = BigInt("0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0");

  // Validate 's' value to prevent malleability
  if (sBigNum.gt(MAX_VALID_S)) {
      throw new Error("ECRecover: invalid signature 's' value");
  }

  // Validate 'v' value (must be 27 or 28)
  if (auth.v !== 27 && auth.v !== 28) {
      throw new Error("ECRecover: invalid signature 'v' value");
  }
  
  const v = auth.v;
  const r = auth.r;
  const s = auth.s;

  // Recover the signer’s address
  const signer = recoverAddress(digest, { v, r, s });

  // Ensure a valid address is returned
  if (!isAddress(signer)) {
      throw new Error("ECRecover: invalid signature");
  }

  // console.log("signer: ", signer);
  // console.log("auth.from: ", auth.from);

  return signer;
}

const generateAuth = async (signer, to, amt) => {

  const {ethers} = await network.connect();

  const types = {
    TransferWithAuthorization: [
      { name: "from", type: "address" },
      { name: "to", type: "address" },
      { name: "value", type: "uint256" },
      { name: "validAfter", type: "uint256" },
      { name: "validBefore", type: "uint256" },
      { name: "nonce", type: "bytes32" }
    ]
  };
  
  const blk = await ethers.provider.getBlock();

  // console.log('blk:', blk);
  
  const value = {
    from: signer.address,
    to: to,
    value: parseUnits(amt.toString(), 6), // USDC精度为6位
    validAfter: blk.timestamp - 1,
    validBefore: blk.timestamp + 3600, // 1小时有效期
    nonce: hexlify(randomBytes(32)), // 递增式nonce
  };

  // console.log('domain:', domain);
  // console.log('types:', types);
  // console.log('value:', value);
  
  const signature = await signer.signTypedData(domain, types, value);

  // console.log('signature:', signature);

  const sig = parseSignature(signature);

  value.v = sig.v;
  value.r = sig.r;
  value.s = sig.s;

  // console.log("sig: ", value);

  return value;  
}

export {
    TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
    recoverSigner,
    getDomainSeparator,
    generateAuth,
    parseSignature,
};
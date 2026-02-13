// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

/// @title TypesList
/// @notice Canonical list of typeOfDoc identifiers used across the system.
/// @dev Replaces JSON imports to keep Solidity compilation self-contained.

library TypesList {
    uint256 internal constant ArrayUtils = 0x01000101;
    uint256 internal constant InterfacesHub = 0x01000201;
    uint256 internal constant RolesRepo = 0x01000301;
    uint256 internal constant UsdLockersRepo = 0x01000401;
    uint256 internal constant FilesRepo = 0x01010101;
    uint256 internal constant RulesParser = 0x01010201;
    uint256 internal constant SigsRepo = 0x01010301;
    uint256 internal constant OfficersRepo = 0x01020101;
    uint256 internal constant Checkpoints = 0x01040101;
    uint256 internal constant MembersRepo = 0x01040201;
    uint256 internal constant TopChain = 0x01040301;
    uint256 internal constant BallotsBox = 0x01050101;
    uint256 internal constant DelegateMap = 0x01050201;
    uint256 internal constant MotionsRepo = 0x01050301;
    uint256 internal constant DealsRepo = 0x01060101;
    uint256 internal constant DTClaims = 0x01060201;
    uint256 internal constant FRClaims = 0x01060301;
    uint256 internal constant LinksRepo = 0x01060401;
    uint256 internal constant CondsRepo = 0x01070101;
    uint256 internal constant OptionsRepo = 0x01070201;
    uint256 internal constant SwapsRepo = 0x01070301;
    uint256 internal constant PledgesRepo = 0x01080101;
    uint256 internal constant LockersRepo = 0x01090101;
    uint256 internal constant SharesRepo = 0x01090201;
    uint256 internal constant GoldChain = 0x010a0101;
    uint256 internal constant OrdersRepo = 0x010a0201;
    uint256 internal constant UsdOrdersRepo = 0x010a0301;
    uint256 internal constant InvestorsRepo = 0x010b0101;
    uint256 internal constant UsersRepo = 0x010d0101;
    uint256 internal constant DocsRepo = 0x010e0101;
    uint256 internal constant WaterfallsRepo = 0x010f0101;
    uint256 internal constant RedemptionsRepo = 0x01100101;
    uint256 internal constant RegisterOfConstitution = 0x02010101;
    uint256 internal constant RegisterOfDirectors = 0x02020101;
    uint256 internal constant RegisterOfMembers = 0x02040101;
    uint256 internal constant MeetingsMinutes = 0x02050101;
    uint256 internal constant RegisterOfAgreements = 0x02060101;
    uint256 internal constant RegisterOfOptions = 0x02070101;
    uint256 internal constant RegisterOfPledges = 0x02080101;
    uint256 internal constant RegisterOfShares = 0x02090101;
    uint256 internal constant ListOfOrders = 0x020a0101;
    uint256 internal constant RegisterOfInvestors = 0x020b0101;
    uint256 internal constant RegCenter = 0x020e0101;
    uint256 internal constant Cashier = 0x020f0101;
    uint256 internal constant RegisterOfRedemptions = 0x02100201;
    uint256 internal constant ROCKeeper = 0x03010101;
    uint256 internal constant FundROCKeeper = 0x03010201;
    uint256 internal constant RODKeeper = 0x03020101;
    uint256 internal constant BMMKeeper = 0x03030101;
    uint256 internal constant ROMKeeper = 0x03040101;
    uint256 internal constant GMMKeeper = 0x03050101;
    uint256 internal constant FundGMMKeeper = 0x03050201;
    uint256 internal constant ROAKeeper = 0x03060101;
    uint256 internal constant ROOKeeper = 0x03070101;
    uint256 internal constant ROPKeeper = 0x03080101;
    uint256 internal constant SHAKeeper = 0x03090101;
    uint256 internal constant LOOKeeper = 0x030a0101;
    uint256 internal constant FundLOOKeeper = 0x030a0201;
    uint256 internal constant ROIKeeper = 0x030b0101;
    uint256 internal constant FundROIKeeper = 0x030b0201;
    uint256 internal constant Accountant = 0x030c0101;
    uint256 internal constant FundAccountant = 0x030c0201;
    uint256 internal constant PrivateComp = 0x030e0101;
    uint256 internal constant GrowingComp = 0x030e0102;
    uint256 internal constant ListedComp = 0x030e0103;
    uint256 internal constant GeneralComp = 0x030e0104;
    uint256 internal constant CloseFund = 0x030e0201;
    uint256 internal constant ListedCloseFund = 0x030e0202;
    uint256 internal constant OpenFund = 0x030e0203;
    uint256 internal constant ListedOpenFund = 0x030e0204;
    uint256 internal constant GeneralFund = 0x030e0205;
    uint256 internal constant FundRORKeeper = 0x03100201;
    uint256 internal constant ShareholdersAgreement = 0x04010101;
    uint256 internal constant InvestmentAgreement = 0x04060101;
    uint256 internal constant AntiDilution = 0x05010101;
    uint256 internal constant LockUp = 0x05020101;
    uint256 internal constant Alongs = 0x05030101;
    uint256 internal constant Options = 0x05040101;
    uint256 internal constant UsdFuelTank = 0x060e0101;
    uint256 internal constant CreateNewComp = 0x060e0201;
    uint256 internal constant CashLockers = 0x060e0301;
    uint256 internal constant LibOfROCK = 0x01810101;
    uint256 internal constant LibOfBMMK = 0x01830101;
    uint256 internal constant LibOfGMMK = 0x01850101;
    uint256 internal constant LibOfROAK = 0x01860101;
    uint256 internal constant LibOfSHAK = 0x01890101;
    uint256 internal constant LibOfLOOK = 0x018a0101;
}

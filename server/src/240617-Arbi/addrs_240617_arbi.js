const addrs = {
  "ArrayUtils": "0x56a6ebAcF52a1d0e972f716dB094F22b3de4D083",
  "BallotsBox": "0x4DadaEE346261e79614b972EfAA0d38F6f88e674",
  "Checkpoints": "0x9d7aed86D402a85C27b32FfA500376A23bD6DD14",
  "DelegateMap": "0x00674f9845FfA9b059505F84B2b472de78f6443d",
  "DocsRepo": "0x502f94AceeD8D354515765486b750c69C6835030",
  "EnumerableSet": "0xB479c459cF0d810Fa467a433964f0a9B745B4334",
  "FRClaims": "0xbB354bAaC30A5112e4330817997634043cE1264E",
  "GoldChain": "0x475051bbb99a21930700650315b5525d2844a8a5",
  "RolesRepo": "0x316F45e2d0fe5775Da819859a355De7377Bd32ed",
  "RulesParser": "0x2898Bce71797eb62E9a95B638D9fa86b7c46BC07",
  "SwapsRepo": "0xfaa8434C81b6ECD192439567738B26596EC668F0",
  "TopChain": "0x745c07C5d31e680D13C3E35EA0c31ddEaEA224db",
  "OrdersRepo": "0xE3154e5D881F7a9c6eFEDdA67F208381feF16296",
  "CondsRepo": "0x021C61f5B6c52F155aE388eBA558f3A71505B2d6",
  "DTClaims": "0xA302A43FA3C08b3C4fcC663477feFfBf59048491",
  "FilesRepo": "0x3b760aC580c83cC7E07C6fD21ba860F6E40c8e89",
  "LockersRepo": "0xa8713a8DE9b0FA4c5245680edC5f367D37C94788",
  "OfficersRepo": "0x988e3E998b796419bDA7bf639f818346674391b7",
  "PledgesRepo": "0x50d11De3A3F85206136451E2d0266277969E530b",
  "SigsRepo": "0x11266a17684582629B0485Ab2569235411E38C73",
  "SharesRepo": "0x6A04a48D0a6dD54eAb893CeC6CE639e76fB96243",
  "TeamsRepo": "0x2c133a8D5ea507eDa2aaF0E6f722C8cd0eee0CD8",
  "MembersRepo": "0x59a9FF67D16807C1feFFa3679978E7ca93097023",
  "MotionsRepo": "0x99e92069Bb845b365Ad53925C124c03834D7Ae25",
  "DealsRepo": "0xc7253045372CE685fe0614120A9C1B6546C0F713",
  "OptionsRepo": "0x0124CA2626B32fA20d970cCc6CDf1642B290F88c",
  "LinksRepo": "0x3f88067252AaB2D417bED2a48634A59782fe3a1D",
  "InvestmentAgreement": "0xB71D4F8617B15a58Ad9ba5E20265b95BAE054cda",
  "ShareholdersAgreement": "0xDF16aE20Cc8190dd21Afa59Fc55A0a794A9c6Ea4",
  "AntiDilution": "0x14B8485A272b5438a1F41d8b0A29d33912D0857B",
  "Alongs": "0x65075574B0b1DdAD4415FDa55ceFa9e33ba7F574",
  "Options": "0x8c4713231D8D230EF1B0c2D3Fff2Da92F6c09472",
  "GeneralKeeper": "0xB8aF08537F29e0dD206a0924DF3864AD58AB52b2",
  "ROMKeeper": "0x1dea5A9e5E9592D1d448A816c670254Bc6234Ee2",
  "RODKeeper": "0x3e46657A9012505E804bbBe67Cf6Ad30a8341eF9",
  "ROCKeeper": "0x2F9dAC0d139E49416c5eB88881962614946aB8ce",
  "RegisterOfAgreements": "0xeD2eC0d0960ebaBC9976A77031030cd07f61cC4d",
  "RegisterOfDirectors": "0x061E5ea6a2D419BAcbD85951fD3e8c963E5f8d2d",
  "MeetingMinutes": "0x220C9F6BAF0eB53F5E50b01C832208B0BA874350",
  "RegisterOfConstitution": "0x690Dd81103Ff47837117dfB62632A4f4dD3C5ebE",
  "RegisterOfOptions": "0x90179daA026e0Bd2456ed89401331EC325876491",
  "RegisterOfPledges": "0x5729CDf96e8Deaaf4aD213DF910Fb904CD64dfb5",
  "RegisterOfMembers": "0xeAA7F51974C1f8A549D72F56b6e9b44F3A047936",
  "ListOfOrders": "0x01ca3A863c07547f708004cEca05108f7b43e543",
  "ListOfProjects": "0x3b60F48Ea389D93AD21BC867005a796F18ab8b96",
  "UsersRepo": "0xE0Ae3e75ff10203AD0f7c06C3FFadFaf98eeE522",
  "RegCenter": "0xb91C1e3fD4e3C481c135dD414c106a25fD99f517",
  "CreateNewComp": "0x7D5dD83999efa266822a5ac7D45d8fAcCD1d9bD3",
  "LockUp": "0x1045082663216F059D02A51a5aB29A41410378D4",
  "ROOKeeper": "0x6Ad18cB722702fC4AeD891F0d1D54a687f87e95E",
  "SHAKeeper": "0x9af4F0F85624AEb8b6b80bEe63778dE4dC74d8F7",
  "GMMKeeper": "0x95D78d0bc57f5DF3A4F5a84445173C2253cC3634",
  "BMMKeeper": "0x5A0e2408FDd08d1aBc6B7fd72fB6e2fbEfD87EaD",
  "LOOKeeper": "0xf8768a13996Fac1BAB4bAd20743a6A72944b8F17",
  "ROAKeeper": "0x27885fe89812158f86204E8970C2e463592f6a48",
  "ROPKeeper": "0xA1b7E6abf8Df8B07016f70162E263b282D1977fD",
  "RegisterOfShares": "0x28B1f8cC6a13Fe7c3FF18ba6c289712D2d1cDC3C",
  "FuelTank": "0xc407520F842f6774900ea6846947304cfD59d7Ee"
}

module.exports = {
  addrs,
};
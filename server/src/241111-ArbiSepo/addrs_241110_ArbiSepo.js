const addrs = {
  "FuelTank": "0xD8f59415eFbA234BAEd3ffD86c024d23B3A3c317",
  "MotionsRepo": "0x2e7aEf8139245d92afdae56c86f958953bb60Ce5",
  "MeetingMinutes": "0x395Acb7792e7C48b6b26BC72c1febE8b55DF1fC6",
  "ArrayUtils": "0x2E93cc77D94890fd8305a65F0079Be990A0dB57b",
  "BallotsBox": "0xC225747873f2220914Db02d601F858b45A6C3e19",
  "Checkpoints": "0xf26DC260e796f60ebD7841E3B7f55bc0094c8B74",
  "DelegateMap": "0x3B638Fa308868520008aDc80F2EE419991D35679",
  "DocsRepo": "0xc722398897C32b0Ca3454524A2AD8A6A393ad6B6",
  "EnumerableSet": "0x8F36Bb4FaDB0E65627aff4BAa57A1ba24683E80F",
  "GoldChain": "0x5c79c3203B127cf3E4d79962D53D1b595Df08BF0",
  "RolesRepo": "0x88dE8b9770b1C567944d9fAF4D39D192064c821f",
  "RulesParser": "0xdCB15eaB64bE64F199b397D67c477B0212eAF283",
  "SwapsRepo": "0xe098f0B7dFDE7706e4272Ae7b3Ca7B935Da00fd2",
  "TopChain": "0xA360eAd80AD4FABb4a94EF8E452a47268f7aa0cd",
  "Address": "0xF71f5743d971904ec348e746EA34e3Da1d320Df7",
  "InvestorsRepo": "0x1E916293b0C6ac1641b58D50f2Afb9F40aD0f1A1",
  "OrdersRepo": "0xaf615AB17c0D6FaE172E0D7B327E98F985B5D5D2",
  "CondsRepo": "0x2f9d3ba68C7150bC71B6d935C50d7A9E10F99aA9",
  "DTClaims": "0xda5DD1326d46f2074491B3AC62389742340Cfb44",
  "FilesRepo": "0x82b3935BDC260Bf0c8B24eBeF467B164Da1513b3",
  "LockersRepo": "0x9A34295b74496946f91CC386099193859A28A55D",
  "OfficersRepo": "0x16510c9619697878B720B26Da8969f6d4a8ccE41",
  "PledgesRepo": "0x6c249AD906FA1eebf315710d73d79d3807558629",
  "SigsRepo": "0xb82C115A4EEBda20b95199dBeb6940942ee05A8A",
  "SharesRepo": "0xbA263a28D948eCdC6BbC87e532dbcA588F87B6A7",
  "TeamsRepo": "0x5BD25309179cE5195595137682DaFA9d4f5E83bb",
  "MembersRepo": "0x3B30437DED7cCE5523162B991B02896DA3205C88",
  "DealsRepo": "0xa2574008Dea608C6d9748491B88F11b0Bb17FFa7",
  "OptionsRepo": "0x4521E74224a446E68E2845dE207699a8dECCa5a2",
  "UsersRepo": "0x60451feA5c180ACE51a89BD1bE12F8de4d03232a",
  "LinksRepo": "0xaaD17c806A0eCEe8484F3D843d68A849D18335FD",
  "RegCenter": "0x23aA751EFCc6e87f7a3F923b12bcf28b0E59E594",
  "CreateNewComp": "0x2c1f854A581c6AF4c2F8F23eE452E557E46458d4",
  "InvestmentAgreement": "0x1187571669ec5A2bb7c8e9F3dfA481d2b1ff3376",
  "ShareholdersAgreement": "0x47816C4ca88A4Ce330410C562BAe46295303d6D3",
  "AntiDilution": "0xA65617F7699CcCa1fd5710a00c487Ca413430A6a",
  "LockUp": "0x161706B64EDcEfc13F995be13bF5c63C8c5ef6B7",
  "Alongs": "0x5D3f365346437C84BFfD771e345eEBF657408d50",
  "Options": "0x8E37ffe73cEee7353bBF236Ae30d29786f1fBd0a",
  "GeneralKeeper": "0x9A9F74cCC8cFC2cd72dEE23232990a8474e62913",
  "ROOKeeper": "0x2cbeC56632F4795bfd5aad3a572bdd98f93ff32c",
  "ROMKeeper": "0xD924F52708203897Fd43cc88277B70e72Cb43532",
  "RODKeeper": "0x7fA7F08Cb0cCf5aF3C86Ea7be4a733b667602808",
  "LOOKeeper": "0x358CD57368A6fF8a17C9FdB2cFFE696f6486B64E",
  "GMMKeeper": "0x0f32e86bB28bD75258A3cD1075971b207769AF0e",
  "BMMKeeper": "0x02FC3dd17af2A869D91E2231c5901D62A8911392",
  "ROCKeeper": "0x92A7EDD9e3366aF33A837A264C33395AD4f4fb55",
  "ROPKeeper": "0xacd55083BF242943760685Ba63023a99B6cb2a3A",
  "RegisterOfDirectors": "0x339C13b627a71851a6f04efCCe8F756259ac37Ec",
  "RegisterOfConstitution": "0x847c1EF11dF2e965512B1D98Af31C31742103601",
  "RegisterOfOptions": "0xcFF9b5aeC061432A303d30E2AaA2A4C38E19C9D4",
  "RegisterOfPledges": "0x4E3ef582563595C166087fBF5bAB4214078fbc8f",
  "RegisterOfShares": "0x6Cb546b72f60bEfa42F3fB9f3B86D6811347Ab71",
  "RegisterOfMembers": "0xDD678c52be5C8DbD8639B16da24083159835Ff47",
  "ListOfOrders": "0x130Ab192B6e661Dc1006B2FcEC4acae1746f1b0E",
  "ListOfProjects": "0x04485d90a6fea32F6c37aDeD7FFED8268B2F57cA",
  "PriceConsumer": "0xFEAcEB695b9715Bb12Eeed1E3F936FaF991C9446",
  "MockFeedRegistry": "0x7f92720D053990a2bda1350C741538a4b5f34735",
  "FRClaims": "0x24c4AbbbF6c69c5d91eA65D98A8781ebe88DC317",
  "RegisterOfAgreements": "0xA5f3a9E127160210866aE0376D4E259d5E7fB785",
  "ROAKeeper": "0x1B80f7a637F2046F713824b84e99D927CC226205",
  "SHAKeeper": "0xAFb759729f24Dc3396498066b35C2262753BD0ee"
}

module.exports = {
  addrs,
}
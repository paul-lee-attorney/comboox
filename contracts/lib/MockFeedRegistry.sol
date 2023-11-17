// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/Denominations.sol";

contract MockFeedRegistry {
    
    /**
     * Network: Ethereum Mainnet
     * Feed Registry: 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
     */

    function decimals(address base, address quote) external pure returns (uint8) {
        require(base == Denominations.ETH, "not based on ETH");
        require(quote != address(0), "zero quote");
        return 8;
    }

    function latestRoundData(address base, address quote) external 
        view returns (
            uint80 roundID,
            int    price,
            uint   startedAt,
            uint   timeStamp,
            uint80 answeredInRound
        ) 
    {
        roundID = 770919;
        startedAt = 1567958400;
        timeStamp = block.timestamp;
        answeredInRound = 190909;

        int[6] memory rates = [int(0), 166680000000, 130907250548, 153193742107, 24234983023517, 1212778000143];

        price = base != Denominations.ETH
            ? rates[0]
            : quote == Denominations.USD
                ?  rates[1]
                : quote == Denominations.GBP
                    ?  rates[2]
                    : quote == Denominations.EUR
                        ? rates[3]
                        : quote == Denominations.JPY
                            ? rates[4]
                            : quote == Denominations.CNY
                                ? rates[5]
                                : rates[0];
    }

}

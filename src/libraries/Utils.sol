// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Utils {
    enum Strategy {
        NotSupported,
        BuyCall,
        SellCall,
        BuyPut,
        SellPut,
        BuyCallSpread,
        SellCallSpread,
        BuyPutSpread,
        SellPutSpread
    }

    uint40 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int40 constant OFFSET19700101 = 2_440_588;

    // Option
    // underlyingAssetIndex - 16-bits
    // expiry - 40-bits
    // strategy - 4-bits

    // length - 2-bits (can be 1, 2, 3, 4)

    // isBuy - 1-bits
    // strikePrice - 46-bits
    // isCall - 1-bits

    // isBuy - 1-bits
    // strikePrice - 46-bits
    // isCall - 1-bits

    // isBuy - 1-bits
    // strikePrice - 46-bits
    // isCall - 1-bits

    // isBuy - 1-bits
    // strikePrice - 46-bits
    // isCall - 1-bits

    // vaultIndex - 2-bits (can be 0, 1, 2, 3)

    function formatOptionTokenId(
        uint16 underlyingAssetIndex,
        uint40 expiry,
        uint8 length,
        bool[4] memory isBuys,
        uint48[4] memory strikePrices,
        bool[4] memory isCalls,
        uint8 sourceVaultIndex
    ) internal pure returns (uint256 optionTokenId) {
        Utils.Strategy strategy;

        (
            strategy,
            isBuys,
            strikePrices,
            isCalls
        ) = determineStrategy(length, isBuys, strikePrices, isCalls);

        optionTokenId =
            (uint256(underlyingAssetIndex) << 240) + // // 16 bits
            (uint256(expiry) << 200) + // 40 bits
            (uint256(uint8(strategy)) << 196) + // 4 bits
            (uint256(length - 1) << 194) + // Updated to 2 bits for length
            (uint256(isBuys[0] ? 1 : 0) << 193) + // 1 bit
            (uint256(strikePrices[0]) << 147) + // 46 bits
            (uint256(isCalls[0] ? 1 : 0) << 146) + // 1 bit
            (uint256(isBuys[1] ? 1 : 0) << 145) + // 1 bit
            (uint256(strikePrices[1]) << 99) + // 46 bits
            (uint256(isCalls[1] ? 1 : 0) << 98) + // 1 bit
            (uint256(isBuys[2] ? 1 : 0) << 97) + // 1 bit
            (uint256(strikePrices[2]) << 51) + // 46 bits
            (uint256(isCalls[2] ? 1 : 0) << 50) + // 1 bit
            (uint256(isBuys[3] ? 1 : 0) << 49) + // 1 bit
            (uint256(strikePrices[3]) << 3) + // 46 bits
            (uint256(isCalls[3] ? 1 : 0) << 2) + // 1 bit
            uint256(sourceVaultIndex & 0x3); // Updated to 2 bits for sourceVaultIndex
    }

    function determineStrategy(
        uint8 length,
        bool[4] memory isBuys,
        uint48[4] memory strikePrices,
        bool[4] memory isCalls
    ) internal pure returns (
        Strategy,
        bool[4] memory,
        uint48[4] memory,
        bool[4] memory
    ) {
        // Sort the strikePrices array and adjust isBuys accordingly
        for (uint256 i = 0; i < strikePrices.length - 1;) {
            for (uint256 j = 0; j < strikePrices.length - i - 1;) {
                if ((strikePrices[j] > strikePrices[j + 1] && strikePrices[j + 1] != 0) || (strikePrices[j] == 0 && strikePrices[j + 1] != 0)) { // check shouldSwap
                    // Swap strikePrices
                    (strikePrices[j], strikePrices[j + 1]) = (strikePrices[j + 1], strikePrices[j]);
                    // Swap isBuys and isCalls
                    (isBuys[j], isBuys[j + 1]) = (isBuys[j + 1], isBuys[j]);
                    (isCalls[j], isCalls[j + 1]) = (isCalls[j + 1], isCalls[j]);
                }

                unchecked { j++; }
            }

            unchecked { i++; }
        }

        uint8 _length = 0;
        for (uint256 i = 0; i < strikePrices.length;) {
            if (strikePrices[i] != 0) {
                _length++;
            } else {
                break; // Terminate the loop early as the strikePrices are sorted
            }
            unchecked { i++; }
        }
        require(length == _length, "Utils: Length is not correct");

        Strategy strategy;

        if (length == 1) {
            if (isBuys[0] && isCalls[0]) {
                // Buy BTC-19JAN24-46000-C
                strategy = Strategy.BuyCall;
            } else if (!isBuys[0] && isCalls[0]) {
                // Sell BTC-19JAN24-48000-C
                strategy = Strategy.SellCall;
            } else if (isBuys[0] && !isCalls[0]) {
                // Buy BTC-19JAN24-46000-P
                strategy = Strategy.BuyPut;
            } else if (!isBuys[0] && !isCalls[0]) {
                // Sell BTC-19JAN24-48000-P
                strategy = Strategy.SellPut;
            } else {
                strategy = Strategy.NotSupported;
            }
        } else if (length == 2) {
            require(strikePrices[0] != strikePrices[1], "Utils: Strike prices are not unique");
            
            if (isCalls[0] == isCalls[1] && isBuys[0] != isBuys[1]) { // Spread
                if (isCalls[0]) { // Call 
                    if (isBuys[0]) { // Buy
                        // Buy BTC-19JAN24-46000-C
                        // Sell BTC-19JAN24-48000-C
                        strategy = Strategy.BuyCallSpread;
                    } else { // Sell
                        // Sell BTC-19JAN24-46000-C
                        // Buy BTC-19JAN24-48000-C
                        strategy = Strategy.SellCallSpread;
                    }
                } else { // Put
                    if (isBuys[1]) { // Buy
                        // Sell BTC-19JAN24-46000-P
                        // Buy BTC-19JAN24-48000-P
                        strategy = Strategy.BuyPutSpread;
                    } else { // Sell
                        // Buy BTC-19JAN24-46000-P
                        // Sell BTC-19JAN24-48000-P
                        strategy = Strategy.SellPutSpread;
                    }
                }
            } else {
                strategy = Strategy.NotSupported;
            }
        } else {
            strategy = Strategy.NotSupported;
        }

        return (strategy, isBuys, strikePrices, isCalls);
    }

    function parseOptionTokenId(uint256 optionTokenId) internal pure returns (
        uint16 underlyingAssetIndex, // 16 bits
        uint40 expiry, // 40 bits
        Strategy strategy, // 4 bits
        uint8 length, // 2 bit
        bool[4] memory isBuys, // 1 bit each
        uint48[4] memory strikePrices, // 46 bits each
        bool[4] memory isCalls, // 1 bit each
        uint8 sourceVaultIndex // 2 bits
    ) {
        underlyingAssetIndex = uint16((optionTokenId >> 240) & 0xFFFF); // 16 bits
        expiry = uint40((optionTokenId >> 200) & 0xFFFFFFFFFF); // 40 bits
        strategy = Strategy(uint8((optionTokenId >> 196) & 0xF)); // 4 bits
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");

        length = uint8((optionTokenId >> 194) & 0x3) + 1; // 2 bits for length
        
        for (uint256 i = 0; i < 4;) {
            isBuys[i] = ((optionTokenId >> (193 - i * 48)) & 0x1) != 0; // 1 bit each
            strikePrices[i] = uint48((optionTokenId >> (147 - i * 48)) & 0x3FFFFFFFFFF); // 46 bits each
            isCalls[i] = ((optionTokenId >> (146 - i * 48)) & 0x1) != 0; // 1 bit each
            unchecked { i++; }
        }
        
        sourceVaultIndex = uint8(optionTokenId & 0x3); // 2 bits for sourceVaultIndex
    }

    function getOppositeOptionTokenId(uint256 optionTokenId) internal pure returns (uint256 oppositeOptionTokenId) {
        (
            uint16 underlyingAssetIndex,
            uint40 expiry,
            ,
            uint8 length,
            bool[4] memory isBuys,
            uint48[4] memory strikePrices,
            bool[4] memory isCalls,
            uint8 sourceVaultIndex
        ) = parseOptionTokenId(optionTokenId);

        for(uint256 i = 0; i < length;) {
            isBuys[i] = !isBuys[i];
            unchecked { i++; }
        }

        return formatOptionTokenId(underlyingAssetIndex, expiry, length, isBuys, strikePrices, isCalls, sourceVaultIndex);
    }

    function getOppositeStrategy(Strategy strategy) internal pure returns (Strategy) {
        if (strategy == Strategy.BuyCall) {
            return Strategy.SellCall;
        } else if (strategy == Strategy.SellCall) {
            return Strategy.BuyCall;
        } else if (strategy == Strategy.BuyPut) {
            return Strategy.SellPut;
        } else if (strategy == Strategy.SellPut) {
            return Strategy.BuyPut;
        } else if (strategy == Strategy.BuyCallSpread) {
            return Strategy.SellCallSpread;
        } else if (strategy == Strategy.SellCallSpread) {
            return Strategy.BuyCallSpread;
        } else if (strategy == Strategy.BuyPutSpread) {
            return Strategy.SellPutSpread;
        } else if (strategy == Strategy.SellPutSpread) {
            return Strategy.BuyPutSpread;
        } else {
            revert("Utils: Invalid strategy");
        }
    }

    function getUnderlyingAssetIndexByOptionTokenId(uint256 optionTokenId) internal pure returns (uint16) {
        return uint16((optionTokenId >> 240) & 0xFFFF);
    }

    function getExpiryByOptionTokenId(uint256 optionTokenId) internal pure returns (uint40) {
        return uint40((optionTokenId >> 200) & 0xFFFFFFFFFF);
    }

    function getStrategyByOptionTokenId(uint256 optionTokenId) internal pure returns (Strategy) {
        Strategy strategy = Strategy(uint8((optionTokenId >> 196) & 0xF)); // 4 bits
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");
        return strategy;
    }

    function getSourceVaultIndexByOptionTokenId(uint256 optionTokenId) internal pure returns (uint8) {
        return uint8(optionTokenId & 0x3);
    }

    function getLengthByStrategy(Strategy strategy) internal pure returns (uint8 length) {
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");

        if (isNaked(strategy)) {
            length = 1;
        } if (isSpread(strategy)) {
            length = 2;
        }
    }

    function isBuy(Strategy strategy) internal pure returns (bool) {
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");
        return strategy == Strategy.BuyCall || strategy == Strategy.BuyPut || strategy == Strategy.BuyCallSpread || strategy == Strategy.BuyPutSpread;
    }

    function isSell(Strategy strategy) internal pure returns (bool) {
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");
        return strategy == Strategy.SellCall || strategy == Strategy.SellPut || strategy == Strategy.SellCallSpread || strategy == Strategy.SellPutSpread;
    }

    function isCall(Strategy strategy) internal pure returns (bool) {
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");
        return strategy == Strategy.BuyCall || strategy == Strategy.SellCall || strategy == Strategy.BuyCallSpread || strategy == Strategy.SellCallSpread;
    }

    function isPut(Strategy strategy) internal pure returns (bool) {
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");
        return strategy == Strategy.BuyPut || strategy == Strategy.SellPut || strategy == Strategy.BuyPutSpread || strategy == Strategy.SellPutSpread;
    }

    function isNaked(Strategy strategy) internal pure returns (bool) {
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");
        return strategy == Strategy.BuyCall || strategy == Strategy.SellCall || strategy == Strategy.BuyPut || strategy == Strategy.SellPut;
    }

    function isCombo(Strategy strategy) internal pure returns (bool) {
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");
        return strategy != Strategy.BuyCall && strategy != Strategy.SellCall && strategy != Strategy.BuyPut && strategy == Strategy.SellPut;
    }

    function isSpread(Strategy strategy) internal pure returns (bool) {
        require(strategy != Strategy.NotSupported, "Utils: Invalid strategy");
        return strategy == Strategy.BuyCallSpread || strategy == Strategy.SellCallSpread || strategy == Strategy.BuyPutSpread || strategy == Strategy.SellPutSpread;
    }
}

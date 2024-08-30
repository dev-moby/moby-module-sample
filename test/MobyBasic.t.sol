// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {MobyRouter} from "../src/MobyRouter.sol";
import {IOptionsMarket} from "../src/interfaces/IOptionsMarket.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {IVaultPriceFeed} from "../src/interfaces/IVaultPriceFeed.sol";
import {Utils} from "../src/libraries/Utils.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {Setup} from "./Setup.t.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

contract MobyRouterTest is Setup {

    function test_closeExpiry() public view {
        console.log("Zero Date to Expiration: ", get0DteExpiry());
        console.log("One  Date to Expiration: ", get1DteExpiry());
    }

    function test_indexToUnderlyingAsset() public view {
        for (uint16 i = 1; i < 20; i++) {
            address _underylingAsset = IOptionsMarket(addressSet.OPTIONS_MARKET).indexToUnderlyingAsset(i);
            if (_underylingAsset == address(0)) {
                break;
            } else {
                string memory _symbol = IERC20Metadata(_underylingAsset).symbol();
                console.log(
                    i, 
                    IOptionsMarket(addressSet.OPTIONS_MARKET).indexToUnderlyingAsset(i), 
                    _symbol
                );
            }
        }
    }

    function test_optionId() public view {
        address _underlyingAsset = addressSet.WBTC;
        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePrice = uint48((roundDown(_spotPrice, 500e30) + 1000e30)/1e30);
        bytes32 _optionId = getOptionId(_underlyingAsset, _expiry, _strikePrice);
        (uint16 _year, uint8 _month, uint8 _day, uint8 _hour) = getDate(get1DteExpiry());
        console.log("underlyingAsset ", IERC20Metadata(_underlyingAsset).symbol());
        console.log("year ", _year);
        console.log("month ", _month);
        console.log("day ", _day);
        console.log("hour ", _hour);
        console.log("strikePrice ", _strikePrice);
        console.log("OptionId(underlyingAsset, expiry, strikePrice) is ");
        console.logBytes32(_optionId);
    }

    function test_parseOptionTokenId() public view {
        uint256 _optionTokenId = 1769619040618146688083008194248310796012278224567126051435131305740730368;
        (
            uint16 _underlyingAssetIndex, // 16 bits
            uint40 _expiry, // 40 bits
            Utils.Strategy _strategy, // 4 bits
            uint8 _length, // 2 bit
            bool[4] memory _isBuys, // 1 bit each
            uint48[4] memory _strikePrices, // 46 bits each
            bool[4] memory _isCalls, // 1 bit each
            uint8 _sourceVaultIndex // 2 bits
        )  = mobyRouter.parseOptionTokenId(_optionTokenId);
            console.log("underlyingAssetIndex ", _underlyingAssetIndex);
            console.log("expiry (", uintToString(uint(_expiry)), ")");
            (uint16 year, uint8 month, uint8 day, uint8 hour) = getDate(_expiry);
            console.log(" - year : ", year);
            console.log(" - month : ", month);
            console.log(" - day : ", day);
            console.log(" - hour : ", hour, "(UTC)");
            console.log(string(abi.encodePacked(
                "strategy ", uintToString(uint(_strategy)),
                " ( 0 : ", "NotSupported, ",
                " 1 : ", "BuyCall, ",
                " 2 : ", "SellCall, ",
                " 3 : ", "BuyPut, ",
                " 4 : ", "SellPut, ",
                " 5 : ", "BuyCallSpread, ",
                " 6 : ", "SellCallSpread, ",
                " 7 : ", "BuyPutSpread, ",
                " 8 : ", "SellPutSpread)"
            )));
            console.log("length ", _length);
            console.log("isBuys[0] ", _isBuys[0]);
            console.log("isBuys[1] ", _isBuys[1]);
            console.log("isBuys[2] ", _isBuys[2]);
            console.log("isBuys[3] ", _isBuys[3]);
            console.log("strikePrices[0] ", _strikePrices[0]);
            console.log("strikePrices[1] ", _strikePrices[1]);
            console.log("strikePrices[2] ", _strikePrices[2]);
            console.log("strikePrices[3] ", _strikePrices[3]);
            console.log("isCalls[0] ", _isCalls[0]);
            console.log("isCalls[1] ", _isCalls[1]);
            console.log("isCalls[2] ", _isCalls[2]);
            console.log("isCalls[3] ", _isCalls[3]);
            console.log("sourceVaultIndex ", _sourceVaultIndex);
    }

    

    // buy naked call
    function test_createOpenPosition1() public returns (bytes32 _requestKey) {
        address _underlyingAsset = addressSet.WBTC;
        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePrice = uint48((roundDown(_spotPrice, 500e30) + 1000e30)/1e30);
        charge(user);

        uint16 _underlyingAssetIndex = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(addressSet.WBTC);
        uint8 _length = 1;
        bool[4] memory _isBuys = [true, false, false, false]; // use only 1st
        bytes32[4] memory _optionIds = [
            getOptionId(_underlyingAsset, _expiry, _strikePrice),
            bytes32(0),
            bytes32(0),
            bytes32(0)
        ]; // use only 1st
        bool[4] memory _isCalls = [true, false, false, false]; // use only 1st
        uint256 _minSize = 0;
        address[] memory _path = new address[](1);
        _path[0] = addressSet.USDC; // send USDC as quoteToken
        uint256 _amountIn = 100e6;
        uint256 _minOutWhenSwap = 0;
        address _leadTrader = address(0);
        vm.startPrank(user);
        IERC20Metadata(addressSet.USDC).approve(address(mobyRouter), _amountIn);
        _requestKey = mobyRouter.createOpenPosition{value: mobyRouter.executionFee()}
        (_underlyingAssetIndex, _length, _isBuys, _optionIds, _isCalls, _minSize, _path, _amountIn, _minOutWhenSwap, _leadTrader);
        vm.stopPrank();
        logOpenPositionRequest(_requestKey);
    }

    // sell naked call
    function test_createOpenPosition2() public returns (bytes32 _requestKey) {
        address _underlyingAsset = addressSet.WBTC;
        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePrice = uint48((roundDown(_spotPrice, 500e30) + 1000e30)/1e30);
        charge(user);

        uint16 _underlyingAssetIndex = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(addressSet.WBTC);
        uint8 _length = 1;
        bool[4] memory _isBuys = [false, false, false, false]; // use only 1st
        bytes32[4] memory _optionIds = [
            getOptionId(_underlyingAsset, _expiry, _strikePrice),
            bytes32(0),
            bytes32(0),
            bytes32(0)
        ]; // use only 1st
        bool[4] memory _isCalls = [true, false, false, false]; // use only 1st
        uint256 _minSize = 0;
        address[] memory _path = new address[](1);
        _path[0] = addressSet.WBTC; // send WBTC as collateral
        uint256 _amountIn = 0.01e8;
        uint256 _minOutWhenSwap = 0;
        address _leadTrader = address(0);
        vm.startPrank(user);
        IERC20Metadata(addressSet.WBTC).approve(address(mobyRouter), _amountIn);
        _requestKey = mobyRouter.createOpenPosition{value: mobyRouter.executionFee()}
        (_underlyingAssetIndex, _length, _isBuys, _optionIds, _isCalls, _minSize, _path, _amountIn, _minOutWhenSwap, _leadTrader);
        vm.stopPrank();
        logOpenPositionRequest(_requestKey);
    }

    // buy naked put
    function test_createOpenPosition3() public returns (bytes32 _requestKey) {
        address _underlyingAsset = addressSet.WBTC;
        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePrice = uint48((roundDown(_spotPrice, 500e30) + 1000e30)/1e30);
        charge(user);

        uint16 _underlyingAssetIndex = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(addressSet.WBTC);
        uint8 _length = 1;
        bool[4] memory _isBuys = [true, false, false, false]; // use only 1st
        bytes32[4] memory _optionIds = [
            getOptionId(_underlyingAsset, _expiry, _strikePrice),
            bytes32(0),
            bytes32(0),
            bytes32(0)
        ]; // use only 1st
        bool[4] memory _isCalls = [false, false, false, false]; // use only 1st
        uint256 _minSize = 0;
        address[] memory _path = new address[](1);
        _path[0] = addressSet.USDC; // send USDC as quoteToken
        uint256 _amountIn = 100e6;
        uint256 _minOutWhenSwap = 0;
        address _leadTrader = address(0);
        vm.startPrank(user);
        IERC20Metadata(addressSet.USDC).approve(address(mobyRouter), _amountIn);
        _requestKey = mobyRouter.createOpenPosition{value: mobyRouter.executionFee()}
        (_underlyingAssetIndex, _length, _isBuys, _optionIds, _isCalls, _minSize, _path, _amountIn, _minOutWhenSwap, _leadTrader);
        vm.stopPrank();
        logOpenPositionRequest(_requestKey);
    }

    // sell naked put
    function test_createOpenPosition4() public returns (bytes32 _requestKey) {
        address _underlyingAsset = addressSet.WBTC;
        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePrice = uint48((roundDown(_spotPrice, 500e30) + 1000e30)/1e30);
        charge(user);

        uint16 _underlyingAssetIndex = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(addressSet.WBTC);
        uint8 _length = 1;
        bool[4] memory _isBuys = [false, false, false, false]; // use only 1st
        bytes32[4] memory _optionIds = [
            getOptionId(_underlyingAsset, _expiry, _strikePrice),
            bytes32(0),
            bytes32(0),
            bytes32(0)
        ]; // use only 1st
        bool[4] memory _isCalls = [false, false, false, false]; // use only 1st
        uint256 _minSize = 0;
        address[] memory _path = new address[](1);
        _path[0] = addressSet.USDC; // send USDC as quoteToken
        uint256 _amountIn = 100e6;
        uint256 _minOutWhenSwap = 0;
        address _leadTrader = address(0);
        vm.startPrank(user);
        IERC20Metadata(addressSet.USDC).approve(address(mobyRouter), _amountIn);
        _requestKey = mobyRouter.createOpenPosition{value: mobyRouter.executionFee()}
        (_underlyingAssetIndex, _length, _isBuys, _optionIds, _isCalls, _minSize, _path, _amountIn, _minOutWhenSwap, _leadTrader);
        vm.stopPrank();
        logOpenPositionRequest(_requestKey);
    }

    // buy call spread
    function test_createOpenPosition5() public returns (bytes32 _requestKey) {
        address _underlyingAsset = addressSet.WBTC;
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePriceToBuyCall = uint48((roundDown(_spotPrice, 500e30) + 1000e30)/1e30);
        uint48 _strikePriceToSellCall = uint48((roundDown(_spotPrice, 500e30) + 1500e30)/1e30);

        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        charge(user);

        uint16 _underlyingAssetIndex = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(addressSet.WBTC);
        uint8 _length = 2;
        bool[4] memory _isBuys = [true, false, false, false]; // use only 1st and 2nd
        bytes32[4] memory _optionIds = [
            getOptionId(_underlyingAsset, _expiry, _strikePriceToBuyCall),
            getOptionId(_underlyingAsset, _expiry, _strikePriceToSellCall),
            bytes32(0),
            bytes32(0)
        ]; // use only 1st and 2nd
        bool[4] memory _isCalls = [true, true, false, false]; // use only 1st and 2nd
        uint256 _minSize = 0;
        address[] memory _path = new address[](1);
        _path[0] = addressSet.USDC; // send USDC as quoteToken
        uint256 _amountIn = 100e6;
        uint256 _minOutWhenSwap = 0;
        address _leadTrader = address(0);
        vm.startPrank(user);
        IERC20Metadata(addressSet.USDC).approve(address(mobyRouter), _amountIn);
        _requestKey = mobyRouter.createOpenPosition{value: mobyRouter.executionFee()}
        (_underlyingAssetIndex, _length, _isBuys, _optionIds, _isCalls, _minSize, _path, _amountIn, _minOutWhenSwap, _leadTrader);
        vm.stopPrank();
        logOpenPositionRequest(_requestKey);
    }

    // sell call spread
    function test_createOpenPosition6() public returns (bytes32 _requestKey) {
        address _underlyingAsset = addressSet.WBTC;
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePriceToSellCall = uint48((roundDown(_spotPrice, 500e30) + 1000e30)/1e30);
        uint48 _strikePriceToBuyCall = uint48((roundDown(_spotPrice, 500e30) + 1500e30)/1e30);

        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        charge(user);

        uint16 _underlyingAssetIndex = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(addressSet.WBTC);
        uint8 _length = 2;
        bool[4] memory _isBuys = [true, false, false, false]; // use only 1st and 2nd
        bytes32[4] memory _optionIds = [
            getOptionId(_underlyingAsset, _expiry, _strikePriceToBuyCall),
            getOptionId(_underlyingAsset, _expiry, _strikePriceToSellCall),
            bytes32(0),
            bytes32(0)
        ]; // use only 1st and 2nd
        bool[4] memory _isCalls = [true, true, false, false]; // use only 1st and 2nd
        uint256 _minSize = 0;
        address[] memory _path = new address[](1);
        _path[0] = addressSet.USDC; // send USDC as quoteToken
        uint256 _amountIn = 100e6;
        uint256 _minOutWhenSwap = 0;
        address _leadTrader = address(0);
        vm.startPrank(user);
        IERC20Metadata(addressSet.USDC).approve(address(mobyRouter), _amountIn);
        _requestKey = mobyRouter.createOpenPosition{value: mobyRouter.executionFee()}
        (_underlyingAssetIndex, _length, _isBuys, _optionIds, _isCalls, _minSize, _path, _amountIn, _minOutWhenSwap, _leadTrader);
        vm.stopPrank();
        logOpenPositionRequest(_requestKey);
    }

    // buy put spread
    function test_createOpenPosition7() public returns (bytes32 _requestKey) {
        address _underlyingAsset = addressSet.WBTC;
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePriceToBuyPut = uint48((roundDown(_spotPrice, 500e30) - 1000e30)/1e30);
        uint48 _strikePriceToSellPut = uint48((roundDown(_spotPrice, 500e30) - 1500e30)/1e30);

        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        charge(user);

        uint16 _underlyingAssetIndex = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(addressSet.WBTC);
        uint8 _length = 2;
        bool[4] memory _isBuys = [true, false, false, false]; // use only 1st and 2nd
        bytes32[4] memory _optionIds = [
            getOptionId(_underlyingAsset, _expiry, _strikePriceToBuyPut),
            getOptionId(_underlyingAsset, _expiry, _strikePriceToSellPut),
            bytes32(0),
            bytes32(0)
        ]; // use only 1st and 2nd
        bool[4] memory _isCalls = [false, false, false, false]; // use only 1st and 2nd
        uint256 _minSize = 0;
        address[] memory _path = new address[](1);
        _path[0] = addressSet.USDC; // send USDC as quoteToken
        uint256 _amountIn = 100e6;
        uint256 _minOutWhenSwap = 0;
        address _leadTrader = address(0);
        vm.startPrank(user);
        IERC20Metadata(addressSet.USDC).approve(address(mobyRouter), _amountIn);
        _requestKey = mobyRouter.createOpenPosition{value: mobyRouter.executionFee()}
        (_underlyingAssetIndex, _length, _isBuys, _optionIds, _isCalls, _minSize, _path, _amountIn, _minOutWhenSwap, _leadTrader);
        vm.stopPrank();
        logOpenPositionRequest(_requestKey);
    }

    // sell put spread
    function test_createOpenPosition8() public returns (bytes32 _requestKey) {
        address _underlyingAsset = addressSet.WBTC;
        uint256 _spotPrice = IVaultPriceFeed(addressSet.VAULT_PRICE_FEED).getSpotPrice(_underlyingAsset, false);
        uint48 _strikePriceToSellPut = uint48((roundDown(_spotPrice, 500e30) - 1000e30)/1e30);
        uint48 _strikePriceToBuyPut = uint48((roundDown(_spotPrice, 500e30) - 1500e30)/1e30);

        uint40 _expiry = get1DteExpiry(); // or  // getTimestamp(2024, 8, 29, 8)
        charge(user);

        uint16 _underlyingAssetIndex = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(addressSet.WBTC);
        uint8 _length = 2;
        bool[4] memory _isBuys = [true, false, false, false]; // use only 1st and 2nd
        bytes32[4] memory _optionIds = [
            getOptionId(_underlyingAsset, _expiry, _strikePriceToBuyPut),
            getOptionId(_underlyingAsset, _expiry, _strikePriceToSellPut),
            bytes32(0),
            bytes32(0)
        ]; // use only 1st and 2nd
        bool[4] memory _isCalls = [false, false, false, false]; // use only 1st and 2nd
        uint256 _minSize = 0;
        address[] memory _path = new address[](1);
        _path[0] = addressSet.USDC; // send USDC as quoteToken
        uint256 _amountIn = 100e6;
        uint256 _minOutWhenSwap = 0;
        address _leadTrader = address(0);
        vm.startPrank(user);
        IERC20Metadata(addressSet.USDC).approve(address(mobyRouter), _amountIn);
        _requestKey = mobyRouter.createOpenPosition{value: mobyRouter.executionFee()}
        (_underlyingAssetIndex, _length, _isBuys, _optionIds, _isCalls, _minSize, _path, _amountIn, _minOutWhenSwap, _leadTrader);
        vm.stopPrank();
        logOpenPositionRequest(_requestKey);
    }

}

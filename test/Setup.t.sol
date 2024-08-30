// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {TestUtils} from "./TestUtils.sol";
import {AddressBook} from "./AddressBook.sol";
import {IOptionsMarket} from "../src/interfaces/IOptionsMarket.sol";
import {IOptionsAuthority} from "../src/interfaces/IOptionsAuthority.sol";
import {IViewAggregator} from "../src/interfaces/IViewAggregator.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {IFastPriceFeed} from "../src/interfaces/IFastPriceFeed.sol";
import {ISpotPriceFeed} from "../src/interfaces/ISpotPriceFeed.sol";
import {ISettlePriceFeed} from "../src/interfaces/ISettlePriceFeed.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IOwnable} from "../src/interfaces/IOwnable.sol";
import {MobyRouter} from "../src/MobyRouter.sol";

contract Setup is TestUtils, AddressBook {
    address internal developer = address(0xbeef);
    address internal user = address(0x1234);
    address internal mockMobyKeeper = address(0x2345);
    uint48 internal constant TEST_STRIKE_PRICE = 59000; // $59000
    uint256 internal constant TEST_MARK_PRICE = 410.65e30; // $410.64
    uint256 internal constant TEST_RISK_PREMIUM = 0.33e30; // $0.33
    MobyRouter internal mobyRouter;
    AddressBook.AddressSet public addressSet = AddressBook.getAddressBook(42161); // Arbitrum One

    function setUp() public {
        vm.startPrank(developer);
        MobyRouter _mobyRouter = new MobyRouter();
        mobyRouter = MobyRouter(payable(address(new TransparentUpgradeableProxy(address(_mobyRouter), developer, ""))));
        mobyRouter.initilize(addressSet.POSITION_MANAGER, addressSet.SETTLE_MANAGER);
        vm.stopPrank();

        // set MockKeeper for test
        vm.startPrank(IOwnable(addressSet.OPTIONS_AUTHORITY).owner());
        IOptionsAuthority(addressSet.OPTIONS_AUTHORITY).setKeeper(mockMobyKeeper, true);
        IOptionsAuthority(addressSet.OPTIONS_AUTHORITY).setPositionKeeper(mockMobyKeeper, true);
        vm.stopPrank();
    }

    function get0DteExpiry() public view returns (uint40 zeroDte) {
        uint40 blockTimestamp = uint40(block.timestamp);
        zeroDte = getTimestamp(2024, 8, 21, 8);
        uint40 leftDays = (blockTimestamp - zeroDte) / 86400 + 1;
        return zeroDte + leftDays * 86400;
    }
    function get1DteExpiry() public view returns (uint40 oneDte) {
        oneDte = get0DteExpiry() + 86400;
    }

    function getOptionId(address _underlyingAsset, uint40 _expiry, uint48 _strikePrice) public view returns (bytes32 _optionId) {
        (uint16 _underlyingAssetIndex) = IOptionsMarket(addressSet.OPTIONS_MARKET).underlyingAssetToIndex(_underlyingAsset);
        
        _optionId = IOptionsMarket(addressSet.OPTIONS_MARKET).getOptionId(
            _underlyingAssetIndex,
            _expiry,
            _strikePrice
        );
    }

    function charge(address _account) internal {
        deal(addressSet.WBTC, _account, 100e8);
        deal(addressSet.USDC, _account, 100e6);
        deal(_account, 100 ether);
        vm.prank(_account);
        IWETH(addressSet.WETH).deposit{value: 100 ether}();
        deal(_account, 100 ether);
    }

    function logOpenPositionRequest(bytes32 requestKey) internal view {
        (
            /* address account */,
            uint16 underlyingAssetIndex,
            uint40 expiry,
            uint256 optionTokenId,
            uint256 minSize,
            uint256 amountIn,
            uint256 minOutWhenSwap,
            bool isDepositedInETH,
            uint40 blockTime,
            IPositionManager.RequestStatus status,
            uint256 sizeOut,
            uint256 executionPrice,
            uint40 processBlockTime,
            uint256 amountOut
        ) = IPositionManager(addressSet.POSITION_MANAGER).openPositionRequests(requestKey);
        console.log("requestKey - ", vm.toString(requestKey));
        console.log("underlyingAssetIndex ", underlyingAssetIndex);
        console.log("expiry ", expiry);
        console.log("optionTokenId ", optionTokenId);
        console.log("minSize ", minSize);
        console.log("amountIn ", amountIn);
        console.log("minOutWhenSwap ", minOutWhenSwap);
        console.log("isDepositedInETH ", isDepositedInETH);
        console.log("blockTime ", blockTime);
        console.log("status ", uint256(status), "(0: Pending, 1: Cancelled, 2: Executed)");
        console.log("sizeOut ", sizeOut);
        console.log("executionPrice ", executionPrice);
        console.log("processBlockTime ", processBlockTime);
        console.log("amountOut ", amountOut);
    }

    function logClosePositionRequest(bytes32 requestKey) internal view {
        (
            /* address account */,
            uint16 underlyingAssetIndex,
            uint40 expiry,
            uint256 optionTokenId,
            uint256 size,
            uint256 minAmountOut,
            uint256 minOutWhenSwap,
            bool withdrawETH,
            uint40 blockTime,
            IPositionManager.RequestStatus status,
            uint256 amountOut,
            uint256 executionPrice,
            uint40 processBlockTime
        ) = IPositionManager(addressSet.POSITION_MANAGER).closePositionRequests(requestKey);
        console.log("requestKey - ", vm.toString(requestKey));
        console.log("underlyingAssetIndex ", underlyingAssetIndex);
        console.log("expiry ", expiry);
        console.log("optionTokenId ", optionTokenId);
        console.log("size ", size);
        console.log("minAmountOut ", minAmountOut);
        console.log("minOutWhenSwap ", minOutWhenSwap);
        console.log("withdrawETH ", withdrawETH);
        console.log("blockTime ", blockTime);
        console.log("status ", uint256(status), "(0: Pending, 1: Cancelled, 2: Executed)");
        console.log("amountOut ", amountOut);
        console.log("executionPrice ", executionPrice);
        console.log("processBlockTime ", processBlockTime);
    }
}

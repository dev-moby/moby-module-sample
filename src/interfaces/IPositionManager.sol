// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPositionManager {
    enum RequestStatus {
        Pending,
        Cancelled,
        Executed
    }

    function maxTimeDelay() external view returns (uint40);
    function positionDeadlineBuffer() external view returns (uint40);
    function positionRequestKeysStart() external view returns (uint256);
    function positionRequestKeys(uint256 index) external view returns (bytes32);
    function positionRequestTypes(uint256 index) external view returns (bool);

    function openPositionRequests(bytes32 key) external view returns (
        address account,                    // trader's address
        uint16 underlyingAssetIndex,        // underlying asset index
        uint40 expiry,                      // expiry of the option
        uint256 optionTokenId,              // ID of the option token
        uint256 minSize,                    // minimum quantity of option tokens (variable value)
        uint256 amountIn,                   // amount of payment token (fixed value)
        uint256 minOutWhenSwap,             // minimum quantity of tokens desired when swapping
        bool isDepositedInETH,              // whether the payment token is ETH
        uint40 blockTime,                   // block time at the moment of request
        RequestStatus status,               // request status
        uint256 sizeOut,                    // quantity of the executed option token
        uint256 executionPrice,             // price of the executed option token
        uint40 processBlockTime,            // block time at the moment of execution
        uint256 amountOut                   // quantity of the premium when sold option
    );

    function closePositionRequests(bytes32 key) external view returns (
        address account,                    // trader's address
        uint16 underlyingAssetIndex,        // underlying asset index
        uint40 expiry,                      // expiry of the option
        uint256 optionTokenId,              // ID of the option token
        uint256 size,                       // quantity of the option token (fixed value)
        uint256 minAmountOut,               // minimum quantity of payout token (variable value)
        uint256 minOutWhenSwap,             // minimum quantity of tokens desired when swapping
        bool withdrawETH,                   // whether the payout token is ETH
        uint40 blockTime,                   // block time at the moment of request
        RequestStatus status,               // request status
        uint256 amountOut,                  // quantity of the payout token
        uint256 executionPrice,             // price of the executed option token
        uint40 processBlockTime             // block time at the moment of execution
    );
    function getRequestQueueLengths() external view returns (uint256, uint256, uint256);
    function executePositions(uint256 _count, address payable _executionFeeReceiver) external;
    function getOpenPositionRequestPath(bytes32 _key) external view returns (address[] memory);
    function getClosePositionRequestPath(bytes32 _key) external view returns (address[] memory);

    function leadTrader(uint256 _requestIndex) external view returns (address leadTrader);
    function copyTradeFeeRebateRate() external view returns (uint256);
    function executionFee() external view returns (uint256);
    function controller() external view returns (address);
    function optionsMarket() external view returns (address);

    function createOpenPosition(
        uint16 _underlyingAssetIndex,
        uint8 _length,
        bool[4] memory _isBuys,
        bytes32[4] memory _optionIds,
        bool[4] memory _isCalls,
        uint256 _minSize,
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOutWhenSwap,
        address _leadTrader
    ) external payable returns (bytes32 _requestKey);

    function createClosePosition(
        uint16 _underlyingAssetIndex,
        uint256 _optionTokenId,
        uint256 _size,
        address[] memory _path,
        uint256 _minAmountOut,
        uint256 _minOutWhenSwap,
        bool _withdrawETH
    ) external payable returns (bytes32);
}

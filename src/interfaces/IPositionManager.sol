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
        address account,                    
        uint16 underlyingAssetIndex,
        uint40 expiry,
        uint256 optionTokenId,
        uint256 minSize,
        uint256 amountIn,
        uint256 minOutWhenSwap,
        bool isDepositedInETH,
        uint40 blockTime,
        RequestStatus status,
        uint256 sizeOut,
        uint256 executionPrice,
        uint40 processBlockTime,
        uint256 amountOut // premium amount when sold option
    );

    function closePositionRequests(bytes32 key) external view returns (
        address account,
        uint16 underlyingAssetIndex,
        uint40 expiry,
        uint256 optionTokenId,
        uint256 size,
        uint256 minAmountOut,
        uint256 minOutWhenSwap,
        bool withdrawETH,
        uint40 blockTime,
        RequestStatus status,
        uint256 amountOut,
        uint256 executionPrice,
        uint40 processBlockTime
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPositionManager.sol";

interface IViewAggregator {
    struct PositionRequestInfo {
        uint256 requestIndex;
        bool isOpen;
        address account;
        uint256 optionTokenId;
        uint256 amountInOrSize; // amountIn for open position, size for close position
        uint40 blockTime;
        IPositionManager.RequestStatus status;
        uint256 sizeOutOrAmountOut; // sizeOut for open position, amountOut for close position
        uint256 executionPrice;
        uint40 processBlockTime;
        address path0;
        address path1;
    }

    function positionRequestInfoWithOlpUtilityRatio(uint256 _maxItem) external view returns (
        PositionRequestInfo[] memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );
}

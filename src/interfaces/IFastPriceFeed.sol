// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFastPriceFeed {
    function lastUpdatedAt(uint256 _tokenId) external view returns (uint256);
    function setUpdateDuration(uint256 _priceDuration) external;

    function getMarkPrice(uint256 _optionTokenId) external view returns (uint256);
    function getRiskPremium(uint256 _optionTokenId, uint256 _requestIndex) external view returns (uint256);
    function setPricesAndRiskPremiumsWithBitsAndExecute(
        address _positionManager,
        uint256[] memory _markPriceBitArray,
        uint256[] memory _riskPremiumBitArray,
        uint256[] memory _optionTokenIds,
        uint256[] memory _requestIndexes,
        uint256 _timestamp,
        uint256 _endIndexForPositions,
        uint256 _maxPositions
    ) external;
}

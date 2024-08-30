// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISpotPriceFeed {
    function description() external view returns (string memory);
    
    function setUpdateDuration(uint256 _updateDuration) external;
    function setIsMaxDeviationEnabled(bool _isMaxDeviationEnabled) external;
    function setMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints) external;

    function feedSpotPrices(address[] memory _tokens, uint256[] memory _spotPrices) external;
    function getSpotPrice(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);
    function getLastUpdatedAt() external view returns (uint256);
    function getSpotPriceWithLastUpdatedAt(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256, uint256);
}
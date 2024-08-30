// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettlePriceFeed {
    function description() external view returns (string memory);
    function feedSettlePrices(address[] memory _tokens, uint256[] memory _settlePrices, uint256 _expiry) external;
    function getSettlePrice(address _token, uint256 _expiry) external view returns (uint256);
}
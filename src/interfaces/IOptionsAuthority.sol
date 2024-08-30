// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOptionsAuthority {
    function isAdmin(address _admin) external view returns (bool);
    function isPositionKeeper(address _positionKeeper) external view returns (bool);
    function isFastPriceFeed(address _fastPriceFeed) external view returns (bool);
    function isKeeper(address _keeper) external view returns (bool);
    function isController(address _controller) external view returns (bool);
    function isFeeDistributor(address _feeDistributor) external view returns (bool);

    function setKeeper(address _keeper, bool _isKeeper) external;
    function setPositionKeeper(address _positionKeeper, bool _isPositionKeeper) external;
}
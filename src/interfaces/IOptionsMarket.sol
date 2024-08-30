// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOptionsMarket {
    struct Option {
        uint16 underlyingAssetIndex;
        address underlyingAsset;
        uint40 expiry;
        uint48 strikePrice;
        bool isActive;
    }
    
    function mainStableAsset() external view returns (address);

    function indexToUnderlyingAsset(uint16) external view returns (address);
    function underlyingAssetToIndex(address) external view returns (uint16);
    function underlyingAssetToOptionsToken(address) external view returns (address);
    function optionsTokenToUnderlyingAsset(address) external view returns (address);
    function isUnderlyingAssetActive(address) external view returns (bool);

    function setMainStableAsset(address _mainStableAsset) external;
    function addUnderlyingAsset(address _underlyingAsset, address _optionsToken) external;
    function setIsUnderlyingAsset(uint16 _underlyingAssetIndex, bool _isUnderlyingAssetActive) external;

    function getOptionId(
        uint16 _underlyingAssetIndex,
        uint40 _expiry,
        uint48 _strikePrice
    ) external pure returns (bytes32);
    function getOptionTokenId (
        uint16 _underlyingAssetIndex,
        uint40 _expiry,
        uint8 _length,
        bool[4] memory _isBuys,
        bytes32[4] memory _optionIds,
        bool[4] memory _isCall,
        uint8 _sourceVaultIndex
    ) external view returns (uint256);
    function getMainStableAsset() external view returns (address, uint8);
    function getUnderlyingAssetByIndex(uint16 _underlyingAssetIndex) external view returns (address, uint8);
    function getOptionsTokenByIndex (uint16 _underlyingAssetIndex) external view returns (address);
    function getOptionDetail(bytes32 _key) external view returns (uint16, address, uint40, uint48);
    function getOptionsBatch(bytes32[] memory _keys) external view returns (Option[] memory);

    function isOptionAvailable(bytes32 _key) external view returns (bool);
    function validateOptionIds(uint8 _length, bytes32[4] memory _optionIds) external view returns (uint16, uint40, uint8);

    function addOptions(address _underlyingAsset, uint40 _expiry, uint48[] memory _strikePrices) external;
    function removeOptions(bytes32[] memory _keys) external;
}

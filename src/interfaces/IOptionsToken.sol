// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Base.sol";
import "./IERC1155Enumerable.sol";
import "./IERC165Base.sol";

interface IOptionsToken is IERC1155Base, IERC1155Enumerable, IERC165Base {
      function name() external view returns (string memory);
      function underlyingAsset() external view returns (address);
      function decimals() external view returns (uint8);
      function mint(address account, uint256 id, uint256 amount) external;
      function burn(address account, uint256 id, uint256 amount) external;
}
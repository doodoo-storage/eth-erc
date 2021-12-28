// SPDX-License-Identifier: MIT
pragma solidity ^0.5.6;

import "./IERC1155.sol";

contract IERC1155MetadataURI is IERC1155 {
  function uri(uint256 id) external view returns (string memory);
}

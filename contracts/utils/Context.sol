// SPDX-License-Identifier: MIT
pragma solidity ^0.5.6;

contract Context {
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal pure returns (bytes memory) {
    return msg.data;
  }
}
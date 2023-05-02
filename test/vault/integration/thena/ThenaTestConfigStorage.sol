// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { ITestConfigStorage } from "../abstract/ITestConfigStorage.sol";

contract ThenaTestConfigStorage is ITestConfigStorage {

  constructor() {
  }

  function getTestConfig(uint256 i) public view returns (bytes memory) {
    return abi.encode("");
  }

  function getTestConfigLength() public view returns (uint256) {
    return 0;
  }
}

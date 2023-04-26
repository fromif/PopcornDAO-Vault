// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { ITestConfigStorage } from "../abstract/ITestConfigStorage.sol";

struct DotDotTestConfig {
    address lpStaking;
}

contract DotDotTestConfigStorage is ITestConfigStorage {
  DotDotTestConfig[] internal testConfigs;

  constructor() {
    // BSC - LpDepositor
    testConfigs.push(
      DotDotTestConfig(0x8189F0afdBf8fE6a9e13c69bA35528ac6abeB1af)
    );
    
  }

  function getTestConfig(uint256 i) public view returns (bytes memory) {
    return abi.encode(testConfigs[i].lpStaking);
  }

  function getTestConfigLength() public view returns (uint256) {
    return testConfigs.length;
  }
}

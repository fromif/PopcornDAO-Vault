// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { ITestConfigStorage } from "../abstract/ITestConfigStorage.sol";

struct DotDotTestConfig {
    address lpToken;
    address lpStaking;
}

contract DotDotTestConfigStorage is ITestConfigStorage {
  DotDotTestConfig[] internal testConfigs;

  constructor() {
    // BSC - val3EPS - LpDepositor
    testConfigs.push(
      DotDotTestConfig(0x5b5bD8913D766D005859CE002533D4838B0Ebbb5, 0x8189F0afdBf8fE6a9e13c69bA35528ac6abeB1af)
    );
    
  }

  function getTestConfig(uint256 i) public view returns (bytes memory) {
    return abi.encode(testConfigs[i].lpToken, testConfigs[i].lpStaking);
  }

  function getTestConfigLength() public view returns (uint256) {
    return testConfigs.length;
  }
}

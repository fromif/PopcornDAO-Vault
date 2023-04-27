// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { ITestConfigStorage } from "../abstract/ITestConfigStorage.sol";

struct SonneTestConfig {
  address asset;
}

contract SonneTestConfigStorage is ITestConfigStorage {
  SonneTestConfig[] internal testConfigs;

  constructor() {
    // Optimism - soUSDT
    testConfigs.push(SonneTestConfig(0x5Ff29E4470799b982408130EFAaBdeeAE7f66a10));
  }

  function getTestConfig(uint256 i) public view returns (bytes memory) {
    return abi.encode(testConfigs[i].asset);
  }

  function getTestConfigLength() public view returns (uint256) {
    return testConfigs.length;
  }
}

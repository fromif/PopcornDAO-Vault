// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { ITestConfigStorage } from "../abstract/ITestConfigStorage.sol";

struct ThenaTestConfig {
  address asset;
}

contract ThenaTestConfigStorage is ITestConfigStorage {

  ThenaTestConfig[] internal testConfigs;

  constructor() {
    address asset = 0x483653bcF3a10d9a1c334CE16a19471a614F4385; // VolatileV1 AMM - WBNB/BUSD
    testConfigs.push(ThenaTestConfig(asset));
  }

  function getTestConfig(uint256 i) public view returns (bytes memory) {
    return abi.encode(testConfigs[i].asset);
  }

  function getTestConfigLength() public view returns (uint256) {
    return testConfigs.length;
  }
}

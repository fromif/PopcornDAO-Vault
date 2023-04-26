// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {ITestConfigStorage} from "../../../abstract/ITestConfigStorage.sol";

struct MorphoCompoundV2TestConfig {
    address supplyVault;
}

contract MorphoCompoundV2TestConfigStorage is ITestConfigStorage {
    MorphoCompoundV2TestConfig[] internal testConfigs;

    constructor() {
        // Mainnet - mcUSDC
        testConfigs.push(
            MorphoCompoundV2TestConfig(0xba9E3b3b684719F80657af1A19DEbc3C772494a0)
        );
    }

    function getTestConfig(uint256 i) public view returns (bytes memory) {
        return abi.encode(testConfigs[i].supplyVault);
    }

    function getTestConfigLength() public view returns (uint256) {
        return testConfigs.length;
    }
}

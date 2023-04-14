// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {ITestConfigStorage} from "../../../abstract/ITestConfigStorage.sol";

struct MorphoAaveV2TestConfig {
    address supplyVault;
}

contract MorphoAaveV2TestConfigStorage is ITestConfigStorage {
    MorphoAaveV2TestConfig[] internal testConfigs;

    constructor() {
        // Mainnet - maDAI
        testConfigs.push(
            MorphoAaveV2TestConfig(0xA5269A8e31B93Ff27B887B56720A25F844db0529)
        );
    }

    function getTestConfig(uint256 i) public view returns (bytes memory) {
        return abi.encode(testConfigs[i].supplyVault);
    }

    function getTestConfigLength() public view returns (uint256) {
        return testConfigs.length;
    }
}

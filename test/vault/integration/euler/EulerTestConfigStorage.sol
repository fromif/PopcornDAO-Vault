// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {ITestConfigStorage} from "../abstract/ITestConfigStorage.sol";

struct EulerTestConfig {
    address eulerToken;
    address eulerMarket;
    address stakingReward;
}

contract EulerTestConfigStorage is ITestConfigStorage {
    EulerTestConfig[] internal testConfigs;

    constructor() {
        // Mainnet - WETH StakingReward
        testConfigs.push(
            EulerTestConfig(
                0x27182842E098f60e3D576794A5bFFb0777E025d3,
                0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3,
                0x229443bf7F1297192394B7127427DB172a5bDe9E
            )
        );

        // Polygon - MAI-FRAX sLP vault
        //testConfigs.push(BeefyTestConfig(0xbC94bDb5393CBABF9B319E892abC95B93B5949A8, address(0)));

        //testConfigs.push(BeefyTestConfig(0xc10C75247f503cc7B7496D72a6F3C443adDB7110, address(0)));
    }

    function getTestConfig(uint256 i) public view returns (bytes memory) {
        return
            abi.encode(testConfigs[i].eulerToken, testConfigs[i].eulerMarket, testConfigs[i].stakingReward);
    }

    function getTestConfigLength() public view returns (uint256) {
        return testConfigs.length;
    }
}

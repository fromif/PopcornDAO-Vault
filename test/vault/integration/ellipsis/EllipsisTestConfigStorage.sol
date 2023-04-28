// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {ITestConfigStorage} from "../abstract/ITestConfigStorage.sol";

struct EllipsisTestConfig {
    address pool;
    address addressProvider;
    address ellipsisStaking;
}

contract EllipsisTestConfigStorage is ITestConfigStorage {
    EllipsisTestConfig[] internal testConfigs;

    constructor() {
        // BSC - 3EPS Pool, Ellipsis Address Provider,  EllipsisLPStaking
        testConfigs.push(
            EllipsisTestConfig(0x160CAed03795365F3A589f10C379FfA7d75d4E76, 0x266Bb386252347b03C7B6eB37F950f476D7c3E63, 0x5B74C99AA2356B4eAa7B85dC486843eDff8Dfdbe)
        );
    }

    function getTestConfig(uint256 i) public view returns (bytes memory) {
        return abi.encode(testConfigs[i].pool, testConfigs[i].addressProvider, testConfigs[i].ellipsisStaking);
    }

    function getTestConfigLength() public view returns (uint256) {
        return testConfigs.length;
    }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {EulerAdapter, SafeERC20, IERC20, IERC20Metadata, IEulerEToken, IEulerMarkets, IStakingRewards} from "../../../../src/vault/adapter/euler/EulerAdapter.sol";
import {EulerTestConfigStorage, EulerTestConfig} from "./EulerTestConfigStorage.sol";
import {AbstractAdapterTest, ITestConfigStorage, IAdapter, Math} from "../abstract/AbstractAdapterTest.sol";
import {IPermissionRegistry, Permission} from "../../../../src/interfaces/vault/IPermissionRegistry.sol";
import {PermissionRegistry} from "../../../../src/vault/PermissionRegistry.sol";

contract EulerAdapterTest is AbstractAdapterTest {
    using Math for uint256;

    address public eulerToken;
    IEulerMarkets public eulerMarket;
    IEulerEToken public eulerEToken;
    IStakingRewards public stakingReward;
    IPermissionRegistry permissionRegistry;

    function setUp() public {
        uint256 forkId = vm.createSelectFork(vm.rpcUrl("mainnet"));
        vm.selectFork(forkId);

        testConfigStorage = ITestConfigStorage(
            address(new EulerTestConfigStorage())
        );

        _setUpTest(testConfigStorage.getTestConfig(0));
    }

    function overrideSetup(bytes memory testConfig) public override {
        _setUpTest(testConfig);
    }

    function _setUpTest(bytes memory testConfig) internal {
        createAdapter();

        (
            address _eulerToken,
            address _eulerMarket,
            address _stakingReward
        ) = abi.decode(testConfig, (address, address, address));

        eulerToken = _eulerToken;
        eulerMarket = IEulerMarkets(_eulerMarket);
        stakingReward = IStakingRewards(_stakingReward);
        eulerEToken = IEulerEToken(stakingReward.stakingToken());
        asset = IERC20(eulerEToken.underlyingAsset());

        // Endorse eulerMarket
        permissionRegistry = IPermissionRegistry(
            address(new PermissionRegistry(address(this)))
        );
        setPermission(address(eulerMarket), true, false);

        setUpBaseTest(
            asset,
            address(new EulerAdapter()),
            address(permissionRegistry),
            10,
            "Euler ",
            true
        );

        adapter.initialize(
            abi.encode(asset, address(this), strategy, 0, sigs, ""),
            externalRegistry,
            testConfig
        );
    }

    function setPermission(
        address target,
        bool endorsed,
        bool rejected
    ) public {
        address[] memory targets = new address[](1);
        Permission[] memory permissions = new Permission[](1);
        targets[0] = target;
        permissions[0] = Permission(endorsed, rejected);
        permissionRegistry.setPermissions(targets, permissions);
    }

    function test__RT_deposit_withdraw() public override {
    }

    function test__RT_mint_withdraw() public override {
    }

    function test__harvest() public override {
    }
}

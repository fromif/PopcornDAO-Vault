// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {MorphoCompoundAdapter, SafeERC20, IERC20, IERC20Metadata, ICompoundSupplyVault} from "../../../../src/vault/adapter/morpho/compound/MorphoCompoundAdapter.sol";
import {MorphoCompoundTestConfigStorage, MorphoCompoundTestConfig} from "./MorphoCompoundTestConfigStorage.sol";
import {AbstractAdapterTest, ITestConfigStorage, IAdapter, Math} from "../abstract/AbstractAdapterTest.sol";
import {IPermissionRegistry, Permission} from "../../../../src/interfaces/vault/IPermissionRegistry.sol";
import {PermissionRegistry} from "../../../../src/vault/PermissionRegistry.sol";

contract MorphoCompoundAdapterTest is AbstractAdapterTest {
    using Math for uint256;

    ICompoundSupplyVault public supplyVault;
    IPermissionRegistry permissionRegistry;

    function setUp() public {
        uint256 forkId = vm.createSelectFork(vm.rpcUrl("mainnet"));
        vm.selectFork(forkId);

        testConfigStorage = ITestConfigStorage(
            address(new MorphoCompoundTestConfigStorage())
        );

        _setUpTest(testConfigStorage.getTestConfig(0));
    }

    function overrideSetup(bytes memory testConfig) public override {
        _setUpTest(testConfig);
    }

    function _setUpTest(bytes memory testConfig) internal {
        createAdapter();

        address _supplyVault = abi.decode(testConfig, (address));

        supplyVault = ICompoundSupplyVault(_supplyVault);
        asset = IERC20(supplyVault.asset());

        permissionRegistry = IPermissionRegistry(
            address(new PermissionRegistry(address(this)))
        );
        setPermission(address(supplyVault), true, false);

        setUpBaseTest(
            asset,
            address(new MorphoCompoundAdapter()),
            address(permissionRegistry),
            10,
            "MorphoCompound ",
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

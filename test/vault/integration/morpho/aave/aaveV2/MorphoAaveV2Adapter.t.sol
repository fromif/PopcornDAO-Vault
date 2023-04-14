// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";

import {MorphoAaveV2Adapter, SafeERC20, IERC20, IERC20Metadata, IAaveSupplyVault} from "../../../../../../../src/vault/adapter/morpho/aave/aaveV2/MorphoAaveV2Adapter.sol";
import {MorphoAaveV2TestConfigStorage, MorphoAaveV2TestConfig} from "./MorphoAaveV2TestConfigStorage.sol";
import {AbstractAdapterTest, ITestConfigStorage, IAdapter, Math} from "../../../abstract/AbstractAdapterTest.sol";
import {IPermissionRegistry, Permission} from "../../../../../../../src/interfaces/vault/IPermissionRegistry.sol";
import {PermissionRegistry} from "../../../../../../../src/vault/PermissionRegistry.sol";

contract MorphoAaveV2AdapterTest is AbstractAdapterTest {
    using Math for uint256;

    IAaveSupplyVault public supplyVault;
    IPermissionRegistry permissionRegistry;

    function setUp() public {
        uint256 forkId = vm.createSelectFork(vm.rpcUrl("mainnet"));
        vm.selectFork(forkId);

        testConfigStorage = ITestConfigStorage(
            address(new MorphoAaveV2TestConfigStorage())
        );

        _setUpTest(testConfigStorage.getTestConfig(0));
    }

    function overrideSetup(bytes memory testConfig) public override {
        _setUpTest(testConfig);
    }

    function _setUpTest(bytes memory testConfig) internal {
        createAdapter();

        address _supplyVault = abi.decode(testConfig, (address));

        supplyVault = IAaveSupplyVault(_supplyVault);
        asset = IERC20(supplyVault.asset());

        permissionRegistry = IPermissionRegistry(
            address(new PermissionRegistry(address(this)))
        );
        setPermission(address(supplyVault), true, false);

        setUpBaseTest(
            asset,
            address(new MorphoAaveV2Adapter()),
            address(permissionRegistry),
            10,
            "MorphoAaveV2 ",
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
}

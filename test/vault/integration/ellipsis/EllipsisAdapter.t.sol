// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";

import { EllipsisAdapter, SafeERC20, IERC20, IERC20Metadata, Math, IEllipsis, IStaking, IAddressProvider } from "../../../../src/vault/adapter/ellipsis/EllipsisAdapter.sol";
import { EllipsisTestConfigStorage, EllipsisTestConfig } from "./EllipsisTestConfigStorage.sol";
import { AbstractAdapterTest, ITestConfigStorage, IAdapter } from "../abstract/AbstractAdapterTest.sol";
import { IPermissionRegistry, Permission } from "../../../../src/interfaces/vault/IPermissionRegistry.sol";
import { PermissionRegistry } from "../../../../src/vault/PermissionRegistry.sol";

contract EllipsisAdapterTest is AbstractAdapterTest {
  using Math for uint256;

  address lp_token;
  IEllipsis ellipsis;
  IStaking staking;
  address busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BSC BUSD Address

  IPermissionRegistry permissionRegistry;


  function setUp() public {
    uint256 forkId = vm.createSelectFork(vm.rpcUrl("binance"));
    vm.selectFork(forkId);

    testConfigStorage = ITestConfigStorage(address(new EllipsisTestConfigStorage()));

    _setUpTest(testConfigStorage.getTestConfig(0));

    maxAssets = maxAssets / 100;
  }

  function overrideSetup(bytes memory testConfig) public override {
    _setUpTest(testConfig);
  }

  function _setUpTest(bytes memory testConfig) internal {
    (address _ellipsisPool, address _addressProvider, address _ellipsisLPStaking) = abi.decode(testConfig, (address, address, address));

    ellipsis = IEllipsis(_ellipsisPool);

    // Endorse Balancer Market
    permissionRegistry = IPermissionRegistry(
        address(new PermissionRegistry(address(this)))
    );

    setPermission(_ellipsisPool, true, false);
    setPermission(_addressProvider, true, false);
    setPermission(_ellipsisLPStaking, true, false);

    setUpBaseTest(IERC20(busd), address(new EllipsisAdapter()), address(permissionRegistry), 10, "popE-", true);

    vm.label(address(asset), "Binance USD");
    vm.label(address(_ellipsisPool), "_ellipsisPool");
    vm.label(address(this), "test");

    adapter.initialize(abi.encode(asset, address(this), strategy, 0, sigs, ""), externalRegistry, testConfig);
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
  /*//////////////////////////////////////////////////////////////
                          HELPER
  //////////////////////////////////////////////////////////////*/

  // Verify that totalAssets returns the expected amount
  function verify_totalAssets() public override {
    // Make sure totalAssets isn't 0
    deal(address(asset), bob, defaultAmount);
    vm.startPrank(bob);
    asset.approve(address(adapter), defaultAmount);
    adapter.deposit(defaultAmount, bob);
    vm.stopPrank();

    assertEq(
      adapter.totalAssets(),
      adapter.convertToAssets(adapter.totalSupply()),
      string.concat("totalSupply converted != totalAssets", baseTestId)
    );
  }

  /*//////////////////////////////////////////////////////////////
                          INITIALIZATION
  //////////////////////////////////////////////////////////////*/

  function verify_adapterInit() public override {
    assertEq(
      IERC20Metadata(address(adapter)).symbol(),
      string.concat("popE-", IERC20Metadata(address(asset)).symbol()),
      "symbol"
    );
  }

  /*//////////////////////////////////////////////////////////////
                            ROUNDTRIP TESTS
  //////////////////////////////////////////////////////////////*/

  function test__RT_deposit_withdraw() public override {
  }

  // NOTE - The across adapter suffers often from an off-by-one error which "steals" 1 wei from the user
  function test__RT_mint_withdraw() public override {

  }

  /*//////////////////////////////////////////////////////////////
                              PAUSE
    //////////////////////////////////////////////////////////////*/
  function test__harvest() public override {}

  function test__unpause() public override {
    _mintAssetAndApproveForAdapter(defaultAmount * 3, bob);

    vm.prank(bob);
    adapter.deposit(defaultAmount, bob);

    uint256 oldTotalSupply = adapter.totalSupply();
    uint256 oldIouBalance = iouBalance();

    adapter.pause();
    adapter.unpause();

    // We simply deposit back into the external protocol
    // TotalSupply and Assets dont change
    assertApproxEqAbs(oldTotalSupply, adapter.totalSupply(), _delta_, "totalSupply");
    assertApproxEqAbs(asset.balanceOf(address(adapter)), 0, _delta_, "asset balance");
    assertApproxEqAbs(iouBalance(), oldIouBalance, _delta_, "iou balance");

    // Deposit and mint dont revert
    vm.startPrank(bob);
    adapter.deposit(defaultAmount, bob);
    adapter.mint(defaultAmount, bob);
  }
}

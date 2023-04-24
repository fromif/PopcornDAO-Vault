// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";

import { BalancerGaugeAdapter, SafeERC20, IERC20, IERC20Metadata, Math, IGauge, IMinter, IWithRewards, IStrategy } from "../../../../src/vault/adapter/balancer/BalancerGaugeAdapter.sol";
import { BalancerGaugeTestConfigStorage, BalancerGaugeTestConfig } from "./BalancerGaugeTestConfigStorage.sol";
import { AbstractAdapterTest, ITestConfigStorage, IAdapter } from "../abstract/AbstractAdapterTest.sol";
import { IPermissionRegistry, Permission } from "../../../../src/interfaces/vault/IPermissionRegistry.sol";
import { PermissionRegistry } from "../../../../src/vault/PermissionRegistry.sol";
import { MockStrategyClaimer } from "../../../utils/mocks/MockStrategyClaimer.sol";

contract BalancerGaugeAdapterTest is AbstractAdapterTest {
  using Math for uint256;

  address lp_token;
  address minter;
  IGauge gague;
  uint256 compoundDefaultAmount = 1e18;

  IPermissionRegistry permissionRegistry;


  function setUp() public {
    uint256 forkId = vm.createSelectFork(vm.rpcUrl("mainnet"));
    vm.selectFork(forkId);

    testConfigStorage = ITestConfigStorage(address(new BalancerGaugeTestConfigStorage()));

    _setUpTest(testConfigStorage.getTestConfig(0));
  }

  function overrideSetup(bytes memory testConfig) public override {
    _setUpTest(testConfig);
  }

  function _setUpTest(bytes memory testConfig) internal {
    (address _balancerGauge, address _minter) = abi.decode(testConfig, (address,address));

    gague = IGauge(_balancerGauge);
    lp_token = gague.lp_token();
    minter = _minter;

    (bool isKilled) = gague.is_killed();
    assertEq(isKilled, false, "InvalidGauge");

    // Endorse Balancer Market
    permissionRegistry = IPermissionRegistry(
        address(new PermissionRegistry(address(this)))
    );
    setPermission(_balancerGauge, true, false);

    setUpBaseTest(IERC20(lp_token), address(new BalancerGaugeAdapter()), address(permissionRegistry), 10, "popB-", true);

    vm.label(address(asset), "USDC-DAI-USDT");
    vm.label(address(_balancerGauge), "_balancerGauge");
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

function test__initialization() public override {

    (address _balancerGauge, address _minter) = abi.decode(testConfigStorage.getTestConfig(0), (address,address));

    createAdapter();
    uint256 callTime = block.timestamp;

    if (address(strategy) != address(0)) {
      vm.expectEmit(false, false, false, true, address(strategy));
      emit SelectorsVerified();
      vm.expectEmit(false, false, false, true, address(strategy));
      emit AdapterVerified();
      vm.expectEmit(false, false, false, true, address(strategy));
      emit StrategySetup();
    }
    vm.expectEmit(false, false, false, true, address(adapter));
    emit Initialized(uint8(1));
    adapter.initialize(
      abi.encode(asset, address(this), strategy, 0, sigs, ""),
      externalRegistry,
      abi.encode(_balancerGauge, _minter)
    );

    assertEq(adapter.owner(), address(this), "owner");
    assertEq(adapter.strategy(), address(strategy), "strategy");
    assertEq(adapter.harvestCooldown(), 0, "harvestCooldown");
    assertEq(adapter.strategyConfig(), "", "strategyConfig");
    assertEq(
      IERC20Metadata(address(adapter)).decimals(),
      IERC20Metadata(address(asset)).decimals() + adapter.decimalOffset(),
      "decimals"
    );

    verify_adapterInit();
  }

  function verify_adapterInit() public override {
    assertEq(adapter.asset(), gague.lp_token(), "asset");
    assertEq(
      IERC20Metadata(address(adapter)).name(),
      string.concat("Popcorn Balancer", IERC20Metadata(address(asset)).name(), " Adapter"),
      "name"
    );
    assertEq(
      IERC20Metadata(address(adapter)).symbol(),
      string.concat("popB-", IERC20Metadata(address(asset)).symbol()),
      "symbol"
    );

    assertEq(asset.allowance(address(adapter), address(gague)), type(uint256).max, "allowance");

    // Test Beefy Config Boundaries
    createAdapter();
    (address _balancerGauge, address _minter) = abi.decode(testConfigStorage.getTestConfig(0), (address,address));

    adapter.initialize(
      abi.encode(asset, address(this), strategy, 0, sigs, ""),
      address(permissionRegistry),
      abi.encode(_balancerGauge, _minter)
    );
  }
  /*//////////////////////////////////////////////////////////////
                              PAUSE
    //////////////////////////////////////////////////////////////*/

  function test__unpause() public override {
    _mintFor(3e18, bob);

    vm.prank(bob);
    adapter.deposit(1e18, bob);

    uint256 oldTotalAssets = adapter.totalAssets();
    uint256 oldTotalSupply = adapter.totalSupply();
    uint256 oldIouBalance = iouBalance();

    adapter.pause();
    adapter.unpause();

    // We simply deposit back into the external protocol
    // TotalSupply and Assets dont change
    // A Tiny change in cToken balance will throw of the assets by some margin.
    assertApproxEqAbs(oldTotalAssets, adapter.totalAssets(), 3e8, "totalAssets");
    assertApproxEqAbs(oldTotalSupply, adapter.totalSupply(), _delta_, "totalSupply");
    assertApproxEqAbs(asset.balanceOf(address(adapter)), 0, _delta_, "asset balance");
    assertApproxEqAbs(iouBalance(), oldIouBalance, _delta_, "iou balance");

    // Deposit and mint dont revert
    vm.startPrank(bob);
    adapter.deposit(1e18, bob);
    adapter.mint(1e18, bob);
  }

  /*//////////////////////////////////////////////////////////////
                              CLAIM
    //////////////////////////////////////////////////////////////*/

  function test__claim() public override {

    (address _balancerGauge, address _minter) = abi.decode(testConfigStorage.getTestConfig(0), (address,address));

    strategy = IStrategy(address(new MockStrategyClaimer()));
    createAdapter();
    adapter.initialize(
      abi.encode(asset, address(this), strategy, 0, sigs, ""),
      externalRegistry,
      testConfigStorage.getTestConfig(0)
    );

    _mintFor(1000e18, bob);

    vm.prank(bob);
    adapter.deposit(1000e18, bob);

    vm.warp(block.timestamp + 10 days);

    vm.prank(bob);
    adapter.withdraw(1, bob, bob);

    address[] memory rewardTokens = IWithRewards(address(adapter)).rewardTokens();
    assertEq(rewardTokens[0], IMinter(minter).getBalancerToken());

    assertGt(IERC20(rewardTokens[0]).balanceOf(address(adapter)), 0);
  }
}

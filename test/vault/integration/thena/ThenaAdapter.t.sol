// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;
import "forge-std/console.sol";

import { Test } from "forge-std/Test.sol";

import { ThenaAdapter, SafeERC20, IERC20, IERC20Metadata, GaugeV2, VoterV3, IWithRewards, IStrategy, ERC20 } from "../../../../src/vault/adapter/thena/ThenaAdapter.sol";
import { AbstractAdapterTest, ITestConfigStorage, IAdapter, Math } from "../abstract/AbstractAdapterTest.sol";
import { ThenaTestConfigStorage, ThenaTestConfig } from "./ThenaTestConfigStorage.sol";
import { MockStrategyClaimer } from "../../../utils/mocks/MockStrategyClaimer.sol";


contract ThenaAdapterTest is AbstractAdapterTest {
  using Math for uint256;

  address _factory = 0x3A1D0952809F4948d15EBCe8d345962A282C4fCb;

  VoterV3 public GAUGES_FACTORY_VOTER;
  GaugeV2 public gauge;

  function setUp() public {
    
    uint256 forkId = vm.createSelectFork(vm.rpcUrl("binance"));
    vm.selectFork(forkId);

    testConfigStorage = ITestConfigStorage(address(new ThenaTestConfigStorage()));

    _setUpTest(testConfigStorage.getTestConfig(0));
  }

  function overrideSetup(bytes memory testConfig) public override {
    _setUpTest(testConfig);
  }

  function _setUpTest(bytes memory testConfig) internal {

    address token = abi.decode(testConfig, (address));

    setUpBaseTest(
      IERC20(token),
      address(new ThenaAdapter()),
      _factory,
      10,
      "Thena ",
      true
    );

    GAUGES_FACTORY_VOTER = VoterV3(externalRegistry);

    gauge = GAUGES_FACTORY_VOTER.gauges(ERC20(token));

    vm.label(_factory, "_factory");
    vm.label(address(asset), "asset");
    vm.label(address(this), "test");

    adapter.initialize(abi.encode(asset, address(this), strategy, 0, sigs, ""), externalRegistry, testConfig);
  }

  /*//////////////////////////////////////////////////////////////
                          HELPER
    //////////////////////////////////////////////////////////////*/

  function iouBalance() public view override returns (uint256) {
    return gauge.balanceOf(address(adapter));
  }

  // Verify that totalAssets returns the expected amount
  function verify_totalAssets() public override {
    // Make sure totalAssets isnt 0
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
      abi.encode("")
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
    // assertNotEq(IEllipsisLpStaking(lpStaking).depositTokens(adapter.asset()), address(0), "asset");
    assertEq(
      IERC20Metadata(address(adapter)).name(),
      string.concat("Popcorn Thena", IERC20Metadata(address(asset)).name(), " Adapter"),
      "name"
    );
    assertEq(
      IERC20Metadata(address(adapter)).symbol(),
      string.concat("popT-", IERC20Metadata(address(asset)).symbol()),
      "symbol"
    );
  }

  /*//////////////////////////////////////////////////////////////
                              CLAIM
    //////////////////////////////////////////////////////////////*/

  function test__claim() public override {
    strategy = IStrategy(address(new MockStrategyClaimer()));
    createAdapter();
    adapter.initialize(
      abi.encode(asset, address(this), strategy, 0, sigs, ""),
      externalRegistry,
      ""
    );

    _mintAssetAndApproveForAdapter(1000e18, bob);

    vm.prank(bob);
    adapter.deposit(1000e18, bob);
    vm.warp(block.timestamp + 10 days);
    vm.prank(bob);
    adapter.withdraw(1, bob, bob);
    address[] memory rewardTokens = IWithRewards(address(adapter)).rewardTokens();
    assertGt(IERC20(rewardTokens[0]).balanceOf(address(adapter)), 0);
  }
}

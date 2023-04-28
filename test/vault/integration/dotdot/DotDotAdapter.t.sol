// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;
import "forge-std/console.sol";

import { Test } from "forge-std/Test.sol";

import { DotDotAdapter, SafeERC20, IERC20, IERC20Metadata, IEllipsisLpStaking, IWithRewards, IStrategy } from "../../../../src/vault/adapter/dotdot/DotDotAdapter.sol";
import { AbstractAdapterTest, ITestConfigStorage, IAdapter, Math } from "../abstract/AbstractAdapterTest.sol";
import { MockStrategyClaimer } from "../../../utils/mocks/MockStrategyClaimer.sol";

contract DotDotAdapterTest is AbstractAdapterTest {
  using Math for uint256;

  IEllipsisLpStaking public lpStaking;
  address _lpToken = 0x5b5bD8913D766D005859CE002533D4838B0Ebbb5;
  address _lpStaking = 0x8189F0afdBf8fE6a9e13c69bA35528ac6abeB1af;

  function setUp() public {
    _setUpTest();
  }

  function _setUpTest() internal {

    uint256 forkId = vm.createSelectFork(vm.rpcUrl("binance"));
    vm.selectFork(forkId);

    lpStaking = IEllipsisLpStaking(_lpStaking);

    setUpBaseTest(
      IERC20(_lpToken),
      address(new DotDotAdapter()),
      _lpStaking,
      10,
      "DotDot ",
      true
    );

    vm.label(_lpStaking, "lpStaking");
    vm.label(address(asset), "asset");
    vm.label(address(this), "test");

    adapter.initialize(abi.encode(asset, address(this), strategy, 0, sigs, ""), externalRegistry, "");
  }

  /*//////////////////////////////////////////////////////////////
                          HELPER
    //////////////////////////////////////////////////////////////*/

  function iouBalance() public view override returns (uint256) {

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
      abi.encode(_lpStaking)
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
      string.concat("Popcorn DotDot", IERC20Metadata(address(asset)).name(), " Adapter"),
      "name"
    );
    assertEq(
      IERC20Metadata(address(adapter)).symbol(),
      string.concat("popD-", IERC20Metadata(address(asset)).symbol()),
      "symbol"
    );
  }

  /*//////////////////////////////////////////////////////////////
                    DEPOSIT/MINT/WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

  function test__deposit(uint8 fuzzAmount) public override {

    uint256 amount = bound(uint256(fuzzAmount), minFuzz, maxAssets);

    _mintAssetAndApproveForAdapter(amount, bob);
    prop_deposit(bob, bob, amount, testId);

    increasePricePerShare(raise);

    _mintAssetAndApproveForAdapter(amount, bob);
    prop_deposit(bob, alice, amount, testId);

  }

  function test__mint(uint8 fuzzAmount) public override {

    uint256 amount = bound(uint256(fuzzAmount), minFuzz, maxShares);

    _mintAssetAndApproveForAdapter(adapter.previewMint(amount), bob);
    prop_mint(bob, bob, amount, testId);

    increasePricePerShare(raise);

    _mintAssetAndApproveForAdapter(adapter.previewMint(amount), bob);
    prop_mint(bob, alice, amount, testId);
    
  }

  function test__withdraw(uint8 fuzzAmount) public override {

    uint256 amount = bound(uint256(fuzzAmount), minFuzz, maxAssets);

    uint256 reqAssets = (adapter.previewMint(adapter.previewWithdraw(amount)) * 10) / 8;
    _mintAssetAndApproveForAdapter(reqAssets, bob);
    vm.prank(bob);
    adapter.deposit(reqAssets, bob);
    prop_withdraw(bob, bob, amount, testId);

    _mintAssetAndApproveForAdapter(reqAssets, bob);
    vm.prank(bob);
    adapter.deposit(reqAssets, bob);

    increasePricePerShare(raise);

    vm.prank(bob);
    adapter.approve(alice, type(uint256).max);
    prop_withdraw(alice, bob, amount, testId);
    
  }

  function test__redeem(uint8 fuzzAmount) public override {

    uint256 amount = bound(uint256(fuzzAmount), minFuzz, maxShares);

    uint256 reqAssets = (adapter.previewMint(amount) * 10) / 9;
    _mintAssetAndApproveForAdapter(reqAssets, bob);
    vm.prank(bob);
    adapter.deposit(reqAssets, bob);
    prop_redeem(bob, bob, amount, testId);

    _mintAssetAndApproveForAdapter(reqAssets, bob);
    vm.prank(bob);
    adapter.deposit(reqAssets, bob);

    increasePricePerShare(raise);

    vm.prank(bob);
    adapter.approve(alice, type(uint256).max);
    prop_redeem(alice, bob, amount, testId);
    
  }

  /*//////////////////////////////////////////////////////////////
                              PAUSE
    //////////////////////////////////////////////////////////////*/

  function test__unpause() public override {
    _mintAssetAndApproveForAdapter(defaultAmount * 3, bob);

    vm.prank(bob);
    adapter.deposit(defaultAmount, bob);

    uint256 oldTotalAssets = adapter.totalAssets();
    uint256 oldTotalSupply = adapter.totalSupply();
    uint256 oldIouBalance = iouBalance();

    adapter.pause();
    adapter.unpause();

    // We simply deposit back into the external protocol
    // TotalSupply and Assets dont change
    // @dev overriden _delta_
    assertApproxEqAbs(oldTotalAssets, adapter.totalAssets(), 50, "totalAssets");
    assertApproxEqAbs(oldTotalSupply, adapter.totalSupply(), 50, "totalSupply");
    assertApproxEqAbs(asset.balanceOf(address(adapter)), 0, 50, "asset balance");
    assertApproxEqRel(iouBalance(), oldIouBalance, 1, "iou balance");

    // Deposit and mint dont revert
    vm.startPrank(bob);
    adapter.deposit(defaultAmount, bob);
    adapter.mint(defaultAmount, bob);
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

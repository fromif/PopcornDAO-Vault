// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {IERC4626Upgradeable as IERC4626, IERC20Upgradeable as IERC20} from "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";

contract Tester is Test {
    IERC4626 mDaiVault = IERC4626(0x36F8d0D0573ae92326827C4a82Fe4CE4C244cAb6);
    IERC20 asset = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function setUp() public {
        uint256 forkId = vm.createSelectFork(vm.rpcUrl("mainnet"));
        vm.selectFork(forkId);

        deal(address(asset), address(this), 1 ether);
    }

    function test_morphoVault() public {
        asset.approve(address(mDaiVault), 1 ether);
        mDaiVault.deposit(1 ether, address(this));
        emit log_uint(IERC20(address(mDaiVault)).balanceOf(address(this)));

        mDaiVault.withdraw(0.9 ether, address(this), address(this));
        emit log_uint(IERC20(address(asset)).balanceOf(address(this)));
        emit log_uint(IERC20(address(mDaiVault)).balanceOf(address(this)));
    }
}

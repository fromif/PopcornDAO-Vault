// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

interface IEulerEToken {
    function deposit(uint256 subAccountId, uint256 amount) external;

    function withdraw(uint256 subAccountId, uint256 amount) external;

    function balanceOfUnderlying(address account)
        external
        view
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

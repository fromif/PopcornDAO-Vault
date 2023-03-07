// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

interface IStakingRewards {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function rewardsToken() external view returns (address);

    function stakingToken() external view returns (address);

    function earned(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;
import {AdapterBase, IERC20, IERC20Metadata, SafeERC20, ERC20, Math, IStrategy, IAdapter} from "../abstracts/AdapterBase.sol";
import {IEulerEToken} from "./IEulerEToken.sol";
import {IEulerMarkets} from "./IEulerMarkets.sol";
import {IStakingRewards} from "./IStakingRewards.sol";

contract EulerAdapter is AdapterBase {
    using SafeERC20 for IERC20;
    using Math for uint256;

    string internal _name;
    string internal _symbol;
    uint256 private _totalHarvestedFromStakingReward;
    mapping(address => uint256) private _rewards;

    address public eulerToken;
    IEulerMarkets public eulerMarket;
    IEulerEToken public eulerEToken;
    IStakingRewards public stakingReward;
    IERC20 public rewardToken;

    function initialize(
        bytes memory adapterInitData,
        address registry,
        bytes memory eulerInitData
    ) external initializer {
        __AdapterBase_init(adapterInitData);
        (
            address _eulerToken,
            address _eulerMarket,
            address _stakingReward
        ) = abi.decode(eulerInitData, (address, address, address));

        eulerToken = _eulerToken;
        eulerMarket = IEulerMarkets(_eulerMarket);
        eulerEToken = IEulerEToken(eulerMarket.underlyingToEToken(asset()));

        if (_stakingReward != address(0)) {
            stakingReward = IStakingRewards(_stakingReward);
            rewardToken = IERC20(stakingReward.rewardsToken());
        }

        _name = string.concat(
            "Popcorn Euler",
            IERC20Metadata(asset()).name(),
            " Adapter"
        );
        _symbol = string.concat("popE-", IERC20Metadata(asset()).symbol());

        IERC20(asset()).approve(eulerToken, type(uint256).max);
    }

    function name()
        public
        view
        override(IERC20Metadata, ERC20)
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        public
        view
        override(IERC20Metadata, ERC20)
        returns (string memory)
    {
        return _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/
    function _totalAssets() internal view override returns (uint256) {
        return eulerEToken.balanceOfUnderlying(address(this));
    }

    function previewWithdraw(uint256 assets)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    function previewRedeem(uint256 shares)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    function getRewards(address account) public view returns (uint256) {
        return _rewards[account] + _rewardsFromStakingReward(account);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function _protocolDeposit(uint256 amount, uint256)
        internal
        virtual
        override
    {
        eulerEToken.deposit(0, amount);

        if (address(stakingReward) != address(0)) {
            uint256 eTokenAmt = eulerEToken.balanceOf(address(this));
            stakingReward.stake(eTokenAmt);
        }
    }

    function _protocolWithdraw(uint256, uint256 shares)
        internal
        virtual
        override
    {
        uint256 amount = _convertToAssets(shares, Math.Rounding.Down);
        if (address(stakingReward) != address(0)) {
            stakingReward.unstake(amount);
            _harvestFromStakingReward(msg.sender);
        }
        eulerEToken.withdraw(0, amount);
    }

    function _harvestFromStakingReward(address caller) internal {
        uint256 amount = _rewardsFromStakingReward(caller);
        _rewards[caller] += amount;
        _totalHarvestedFromStakingReward += amount;
    }

    function _rewardsFromStakingReward(address account)
        internal
        view
        returns (uint256)
    {
        if (address(stakingReward) == address(0)) return 0;
        uint256 rewardInStakingReward = stakingReward.earned(address(this));
        uint256 harvestedReward = rewardToken.balanceOf(address(this));
        uint256 availableReward = rewardInStakingReward +
            harvestedReward -
            _totalHarvestedFromStakingReward;

        uint256 shares = balanceOf(account);
        uint256 supply = totalSupply();
        return shares.mulDiv(availableReward, supply, Math.Rounding.Down);
    }

    function claim() public {
        stakingReward.getReward();
        address caller = msg.sender;
        uint256 amount = getRewards(caller);
        _totalHarvestedFromStakingReward -= _rewards[caller];
        _rewards[caller] = 0;
        rewardToken.transfer(caller, amount);
    }
}

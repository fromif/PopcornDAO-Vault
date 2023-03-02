// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;
import {AdapterBase, IERC20, IERC20Metadata, SafeERC20, ERC20, Math, IStrategy, IAdapter} from "../abstracts/AdapterBase.sol";
import {WithRewards, IWithRewards} from "../abstracts/WithRewards.sol";
import {IEulerEToken} from "./IEulerEToken.sol";
import {IEulerMarkets} from "./IEulerMarkets.sol";
import {IStakingRewards} from "./IStakingRewards.sol";

contract EulerAdapter is AdapterBase, WithRewards {
    using SafeERC20 for IERC20;
    using Math for uint256;

    string internal _name;
    string internal _symbol;

    address public eulerToken;
    IEulerMarkets public eulerMarket;
    IEulerEToken public eulerEToken;
    IStakingRewards public stakingReward;

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

    function rewardTokens() external view override returns (address[] memory) {
        address[] memory _rewardTokens = new address[](1);
        if (address(stakingReward) != address(0)) {
            _rewardTokens[0] = stakingReward.rewardsToken();
        }
        return _rewardTokens;
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
        }
        eulerEToken.withdraw(0, amount);
    }

    error NoStakingReward();

    function claim() public override onlyStrategy {
        if (address(stakingReward) == address(0)) revert NoStakingReward();
        stakingReward.getReward();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(WithRewards, AdapterBase)
        returns (bool)
    {
        return
            interfaceId == type(IWithRewards).interfaceId ||
            interfaceId == type(IAdapter).interfaceId;
    }
}

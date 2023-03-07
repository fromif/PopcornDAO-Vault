// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;
import {AdapterBase, IERC20, IERC20Metadata, SafeERC20, ERC20, Math, IStrategy, IAdapter} from "../abstracts/AdapterBase.sol";
import {WithRewards, IWithRewards} from "../abstracts/WithRewards.sol";
import {IEulerEToken} from "./IEulerEToken.sol";
import {IEulerMarkets} from "./IEulerMarkets.sol";
import {IStakingRewards} from "./IStakingRewards.sol";
import {IPermissionRegistry} from "../../../interfaces/vault/IPermissionRegistry.sol";

contract EulerAdapter is AdapterBase, WithRewards {
    using SafeERC20 for IERC20;
    using Math for uint256;

    string internal _name;
    string internal _symbol;

    address public eulerToken;
    IEulerMarkets public eulerMarket;
    IEulerEToken public eulerEToken;
    IStakingRewards public stakingReward;

    error NotEndorsed(address eulerMarket);

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

        if (!IPermissionRegistry(registry).endorsed(_eulerMarket))
            revert NotEndorsed(_eulerMarket);
        eulerToken = _eulerToken;
        eulerMarket = IEulerMarkets(_eulerMarket);
        eulerEToken = IEulerEToken(eulerMarket.underlyingToEToken(asset()));

        if (_stakingReward != address(0)) {
            stakingReward = IStakingRewards(_stakingReward);
            eulerEToken.approve(address(stakingReward), type(uint256).max);
        }

        _name = string.concat(
            "Popcorn Euler",
            IERC20Metadata(asset()).name(),
            " Adapter"
        );
        _symbol = string.concat("popE-", IERC20Metadata(asset()).symbol());

        IERC20(asset()).approve(address(eulerToken), type(uint256).max);
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
        if (address(stakingReward) == address(0))
            return eulerEToken.balanceOfUnderlying(address(this));
        return
            eulerEToken.balanceOfUnderlying(address(this)) +
            stakingReward.balanceOf(address(this));
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
            stakingReward.withdraw(amount);
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

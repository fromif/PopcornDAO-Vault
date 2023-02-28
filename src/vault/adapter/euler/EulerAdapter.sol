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

    address public eulerToken;
    IEulerMarkets public eulerMarket;
    IEulerEToken public eulerEToken;
    IStakingRewards public stakingRewards;

    function initialize(
        bytes memory adapterInitData,
        address registry,
        bytes memory eulerInitData
    ) external initializer {
        __AdapterBase_init(adapterInitData);
        (
            address _eulerToken,
            address _eulerMarket,
            address _stakingRewards
        ) = abi.decode(eulerInitData, (address, address, address));

        eulerToken = _eulerToken;
        eulerMarket = IEulerMarkets(_eulerMarket);
        eulerEToken = IEulerEToken(eulerMarket.underlyingToEToken(asset()));

        if (_stakingRewards != address(0)) {
            stakingRewards = IStakingRewards(_stakingRewards);
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
    /// @notice Emulate yearns total asset calculation to return the total assets of the vault.
    function _totalAssets() internal view override returns (uint256) {
        return eulerEToken.balanceOfUnderlying(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit into beefy vault and optionally into the booster given its configured
    function _protocolDeposit(uint256 amount, uint256)
        internal
        virtual
        override
    {
        eulerEToken.deposit(0, amount);
    }

    /// @notice Withdraw from the beefy vault and optionally from the booster given its configured
    function _protocolWithdraw(uint256 amount, uint256)
        internal
        virtual
        override
    {
        eulerEToken.withdraw(0, amount);
    }
}

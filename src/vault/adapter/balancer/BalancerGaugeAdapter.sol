// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { AdapterBase, IERC20, IERC20Metadata, SafeERC20, ERC20, Math, IStrategy, IAdapter } from "../abstracts/AdapterBase.sol";
import { WithRewards, IWithRewards } from "../abstracts/WithRewards.sol";
import { IPermissionRegistry } from "../../../interfaces/vault/IPermissionRegistry.sol";
import { IGauge, IMinter } from "./IBalancer.sol";

contract BalancerGaugeAdapter is AdapterBase, WithRewards {
    using SafeERC20 for IERC20;
    using Math for uint256;

    string internal _name;
    string internal _symbol;

    address public balancerGauge;
    address public balancerMinter;

    error NotEndorsed(address _balancerGauge);
    error Disabled();

    /**
    * @notice Initialize a new Balancer Adapter.
    * @param adapterInitData Encoded data for the base adapter initialization.
    * @param registry Endorsement Registry to check if the balancer adapter is endorsed.
    * @param balancerInitData Encoded data for the balancer adapter initialization.
    * @dev `_balancerMinter` - the address of Balancer Minter.
    * @dev `_balancerGauge` - the address of Balancer Gauge.
    * @dev This function is called by the factory contract when deploying a new vault.
    */
    function initialize(
        bytes memory adapterInitData,
        address registry,
        bytes memory balancerInitData
    ) external initializer {
        (address _balancerGauge, address _balancerMinter) = abi.decode(balancerInitData, (address,address));
        __AdapterBase_init(adapterInitData);

        if (!IPermissionRegistry(registry).endorsed(_balancerGauge)) revert NotEndorsed(_balancerGauge);

        _name = string.concat("Popcorn Balancer", IERC20Metadata(asset()).name(), " Adapter");
        _symbol = string.concat("popB-", IERC20Metadata(asset()).symbol());

        if(IGauge(_balancerGauge).is_killed()) revert Disabled();
        balancerGauge = _balancerGauge;
        balancerMinter = _balancerMinter;

        IERC20(asset()).approve(_balancerGauge, type(uint256).max);
    }

    function name() public view override(IERC20Metadata, ERC20) returns (string memory) {
        return _name;
    }

    function symbol() public view override(IERC20Metadata, ERC20) returns (string memory) {
        return _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function _totalAssets() internal view override returns (uint256) {
        return IGauge(balancerGauge).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice The amount of beefy shares to withdraw given an amount of adapter shares
    function convertToUnderlyingShares(uint256, uint256 shares) public view override returns (uint256) {

        uint256 supply = totalSupply();
        return supply == 0 ? shares : shares.mulDiv(_totalAssets(), supply, Math.Rounding.Up);
        
    }

    function _protocolDeposit(uint256 amount, uint256)
        internal
        virtual
        override
    {
        IGauge(balancerGauge).deposit(amount, address(this), false);
    }

    function _protocolWithdraw(uint256, uint256 share)
        internal
        virtual
        override
    {
        uint256 _lpShare = convertToUnderlyingShares(0, share);
        IGauge(balancerGauge).withdraw(_lpShare, false);
    }

    function claim() public override onlyStrategy {
        IMinter(balancerMinter).mint(balancerGauge);
    }

    /// @notice The token rewarded
    function rewardTokens() external view override returns (address[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = IMinter(balancerMinter).getBalancerToken();
        return _rewardTokens;
    }

    /*//////////////////////////////////////////////////////////////
                      EIP-165 LOGIC
    //////////////////////////////////////////////////////////////*/

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
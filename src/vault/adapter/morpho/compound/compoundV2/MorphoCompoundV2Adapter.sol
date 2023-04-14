// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;
import {AdapterBase, IERC20, IERC20Metadata, SafeERC20, ERC20, Math, IStrategy, IAdapter} from "../../../abstracts/AdapterBase.sol";
import {ICompoundSupplyVault} from "./ICompoundSupplyVault.sol";
import {WithRewards, IWithRewards} from "../../../abstracts/WithRewards.sol";
import {IPermissionRegistry} from "../../../../../interfaces/vault/IPermissionRegistry.sol";

contract MorphoCompoundV2Adapter is AdapterBase, WithRewards {
    using SafeERC20 for IERC20;
    using Math for uint256;

    string internal _name;
    string internal _symbol;

    ICompoundSupplyVault public supplyVault;

    error NotEndorsed(address supplyVault);

    function initialize(
        bytes memory adapterInitData,
        address registry,
        bytes memory morphoInitData
    ) external initializer {
        __AdapterBase_init(adapterInitData);
        address _supplyVault = abi.decode(morphoInitData, (address));

        if (!IPermissionRegistry(registry).endorsed(_supplyVault))
            revert NotEndorsed(_supplyVault);

        supplyVault = ICompoundSupplyVault(_supplyVault);

        _name = string.concat(
            "Popcorn Morpho CompoundV2 ",
            IERC20Metadata(asset()).name(),
            " Adapter"
        );
        _symbol = string.concat("popMCv2-", IERC20Metadata(asset()).symbol());

        IERC20(asset()).approve(address(supplyVault), type(uint256).max);
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

    function _totalAssets() internal view override returns (uint256) {
        return
            supplyVault.convertToAssets(supplyVault.balanceOf(address(this)));
    }

    function rewardTokens() external view override returns (address[] memory) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = supplyVault.comp();
        return _rewardTokens;
    }

    function _protocolDeposit(
        uint256 amount,
        uint256
    ) internal virtual override {
        supplyVault.deposit(amount, address(this));
    }

    function _protocolWithdraw(
        uint256,
        uint256 shares
    ) internal virtual override {
        uint256 amount = _convertToAssets(shares, Math.Rounding.Down);
        supplyVault.withdraw(amount, address(this), address(this));
    }

    function claim() public override onlyStrategy returns (bool success) {
        try supplyVault.claimRewards(address(this)) {
            success = true;
        } catch {}
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(WithRewards, AdapterBase) returns (bool) {
        return
            interfaceId == type(IWithRewards).interfaceId ||
            interfaceId == type(IAdapter).interfaceId;
    }
}

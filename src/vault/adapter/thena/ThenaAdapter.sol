// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {AdapterBase, IERC20, IERC20Metadata, SafeERC20, ERC20, Math, IStrategy, IAdapter} from "../abstracts/AdapterBase.sol";
import {WithRewards, IWithRewards} from "../abstracts/WithRewards.sol";
import {IPermissionRegistry} from "../../../interfaces/vault/IPermissionRegistry.sol";

interface GaugeV2 {
    function getReward() external;

    function deposit(uint256) external;

    function withdraw(uint256) external;

    function depositAll() external;

    function withdrawAll() external;

    function earned(address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function rewardToken() external view returns (ERC20);

    function TOKEN() external view returns (address);
}

interface VoterV3 {
    function gauges(ERC20) external view returns (GaugeV2);
}

contract ThenaAdapter is AdapterBase, WithRewards {

    using SafeERC20 for IERC20;
    using Math for uint256;

    string internal _name;
    string internal _symbol;

    GaugeV2 public gauge;

    // VoterV3 public constant GAUGES_FACTORY_VOTER =
        // VoterV3(0x3A1D0952809F4948d15EBCe8d345962A282C4fCb);
    VoterV3 public GAUGES_FACTORY_VOTER;

    /**
     * @notice Initialize a new DotDot Adapter.
     * @param adapterInitData Encoded data for the base adapter initialization.
     * @param registry Endorsement Registry to check if the Thena GAUGES_FACTORY_VOTER is endorsed.
     */
    function initialize(
        bytes memory adapterInitData,
        address registry,
        bytes memory thenaInitData
    ) external initializer {
        __AdapterBase_init(adapterInitData);

        GAUGES_FACTORY_VOTER = VoterV3(registry);

        gauge = GAUGES_FACTORY_VOTER.gauges(ERC20(asset()));
        _name = string.concat(
            "Popcorn Thena",
            IERC20Metadata(asset()).name(),
            " Adapter"
        );
        _symbol = string.concat("popT-", IERC20Metadata(asset()).symbol());

        IERC20(asset()).approve(address(gauge), type(uint256).max);

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

    function _protocolDeposit(uint256 amount, uint256) internal virtual override {
        gauge.deposit(amount);
    }

    function _protocolWithdraw(uint256 amount, uint256) internal virtual override {
        gauge.withdraw(amount);
    }

    function _totalAssets() internal view override returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                            STRATEGY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim rewards from the lpStaking given its configured
    function claim() public override onlyStrategy returns (bool success) {
        try gauge.getReward() {
            success = true;
        } catch {}
    }

    /// @notice The token rewarded if a thena is configured
    function rewardTokens()
        external
        view
        override
        returns (address[] memory _rewardTokens)
    {
        _rewardTokens = new address[](1);
        _rewardTokens[0] = address(gauge.rewardToken());
    }

    /*//////////////////////////////////////////////////////////////
                      EIP-165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(WithRewards, AdapterBase) returns (bool) {
        return
            interfaceId == type(IWithRewards).interfaceId ||
            interfaceId == type(IAdapter).interfaceId;
    }
}
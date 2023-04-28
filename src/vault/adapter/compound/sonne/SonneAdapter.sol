// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import {CompoundV2Adapter} from "../compoundV2/CompoundV2Adapter.sol";
import {ICToken} from "../compoundV2/ICompoundV2.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {LibSonne} from "./LibSonne.sol";
/**
 * @title   SonneAdapter Adapter
 * @author  amatureApe
 * @notice  ERC4626 wrapper for SonneAdapter Vaults.
 *
 * An ERC4626 compliant Wrapper for https://sonne.finance/.
 */
contract SonneAdapter is CompoundV2Adapter {
    
    using FixedPointMathLib for uint256;

    function _viewUnderlyingBalanceOf(address token, address user) internal override view returns (uint256) {
        ICToken token = ICToken(token);
        return LibSonne.viewUnderlyingBalanceOf(token, user);
    }
}

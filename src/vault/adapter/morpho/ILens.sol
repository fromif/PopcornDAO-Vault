// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;
import {Types} from "./Types.sol";

interface ILens {
    function isMarketCreated(address _poolToken) external view returns (bool);

    function getMarketPauseStatus(
        address _poolToken
    ) external view returns (Types.MarketPauseStatus memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC4626} from "../../interfaces/IERC4626.sol";

/// @title VaultLib
/// @author Pyth Data Association
/// @notice Library exposing functions to price shares of an ERC4626 vault
/// @dev This library provides share-to-asset conversion for ERC-4626 vaults used in price calculations.
/// Users should only use vaults with manipulation-resistant designs and trusted governance.

library VaultLib {
    /// @notice Converts vault shares to underlying asset amount
    /// @param vault The ERC-4626 vault contract, or address(0) to return 1
    /// @param shares The amount of vault shares to convert
    /// @return The equivalent amount of underlying assets
    /// @dev When `vault` is address(0), returns 1 (useful for skipping vault conversion)
    function getAssets(IERC4626 vault, uint256 shares) internal view returns (uint256) {
        if (address(vault) == address(0)) return 1;

        return vault.convertToAssets(shares);
    }
}

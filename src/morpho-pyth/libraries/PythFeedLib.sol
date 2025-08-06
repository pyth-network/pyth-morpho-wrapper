// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {PythErrorsLib} from "./PythErrorsLib.sol";
/// @title PythFeedLib
/// @author Pyth Data Association
/// @notice Library exposing functions to interact with a Pyth feed
/// @dev This library provides basic price fetching from Pyth feeds with staleness protection.
///
/// SECURITY LIMITATION: This implementation ignores Pyth's confidence intervals (conf field).
/// Pyth aggregates prices from multiple providers and returns both the price and a confidence
/// interval indicating price uncertainty. Large confidence intervals suggest unreliable prices
/// that should potentially be rejected.

library PythFeedLib {
    /// @notice Returns the price of a Pyth price feed
    /// @param pyth The Pyth contract instance
    /// @param priceId The Pyth price feed identifier, or bytes32(0) to return 1
    /// @param maxAge Maximum acceptable price age in seconds
    /// @return The price value (always positive)
    /// @dev When `priceId` is bytes32(0), returns 1 (useful for omitting feeds in calculations)
    /// @dev Reverts with `0x19abf40e` StalePrice error if price is older than `maxAge`
    /// @dev Reverts if price is negative (should not occur with valid Pyth feeds)
    ///
    /// SECURITY WARNING: This function ignores the confidence interval (price.conf) returned by Pyth.
    function getPrice(IPyth pyth, bytes32 priceId, uint256 maxAge) internal view returns (uint256) {
        if (priceId == bytes32(0)) return 1;

        PythStructs.Price memory price = pyth.getPriceNoOlderThan(priceId, maxAge);
        require(int256(price.price) >= 0, PythErrorsLib.NEGATIVE_ANSWER);

        // NOTE: price.conf (confidence interval) is not validated here
        // Large conf values indicate uncertain prices that may need rejection

        return uint256(int256(price.price));
    }
    /// @notice Returns the number of decimal places for a Pyth price feed
    /// @param pyth The Pyth contract instance
    /// @param priceId The Pyth price feed identifier, or bytes32(0) to return 0
    /// @return The number of decimal places for the price feed
    /// @dev When `priceId` is bytes32(0), returns 0 (useful for omitting feeds in calculations)
    /// @dev Uses getPriceUnsafe() which does not validate price age - only for decimal retrieval
    /// @dev Converts negative exponent to positive decimal count (e.g., expo=-8 returns 8)

    function getDecimals(IPyth pyth, bytes32 priceId) internal view returns (uint256) {
        if (priceId == bytes32(0)) return 0;

        PythStructs.Price memory price = pyth.getPriceUnsafe(priceId);
        return uint256(-1 * int256(price.expo));
    }
}

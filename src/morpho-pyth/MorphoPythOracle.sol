// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IOracle} from "../../lib/morpho-blue/src/interfaces/IOracle.sol";
import {IMorphoPythOracle} from "./interfaces/IMorphoPythOracle.sol";
import {Math} from "../../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC4626, VaultLib} from "./libraries/VaultLib.sol";
import {PythErrorsLib} from "./libraries/PythErrorsLib.sol";
import {PythFeedLib} from "./libraries/PythFeedLib.sol";

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

/// @title MorphoPythOracle
/// @author Pyth Data Association
/// @notice Morpho oracle implementation that combines Pyth price feeds with ERC-4626 vault pricing
/// @dev This oracle calculates prices by combining multiple data sources:
///      - Up to 2 Pyth price feeds each for base and quote assets
///      - Optional ERC-4626 vault share-to-asset conversion for base and quote
///      - Configurable staleness checks for price feed age validation
///
/// Price Calculation Formula:
/// price = SCALE_FACTOR * (baseVaultAssets * baseFeed1 * baseFeed2) / (quoteVaultAssets * quoteFeed1 * quoteFeed2)
///
/// Security Considerations:
/// - Single priceFeedMaxAge used for all feeds may not suit different asset volatilities
/// - ERC-4626 vaults can be manipulated through donations, flash loans, or fee changes
/// - Pyth confidence intervals are not validated, potentially accepting uncertain prices
/// - Conversion samples must be large enough to avoid rounding to zero
///
/// @dev This contract follows Morpho's design philosophy prioritizing flexibility over safety.
///      Users must validate all configuration parameters and monitor oracle behavior.
contract MorphoPythOracle is IMorphoPythOracle {
    using Math for uint256;

    IPyth public immutable pyth;

    using VaultLib for IERC4626;

    /* IMMUTABLES */

    /// @inheritdoc IMorphoPythOracle
    IERC4626 public immutable BASE_VAULT;

    /// @inheritdoc IMorphoPythOracle
    uint256 public immutable BASE_VAULT_CONVERSION_SAMPLE;

    /// @inheritdoc IMorphoPythOracle
    IERC4626 public immutable QUOTE_VAULT;

    /// @inheritdoc IMorphoPythOracle
    uint256 public immutable QUOTE_VAULT_CONVERSION_SAMPLE;

    /// @inheritdoc IMorphoPythOracle
    bytes32 public immutable BASE_FEED_1;

    /// @inheritdoc IMorphoPythOracle
    bytes32 public immutable BASE_FEED_2;

    /// @inheritdoc IMorphoPythOracle
    bytes32 public immutable QUOTE_FEED_1;

    /// @inheritdoc IMorphoPythOracle
    bytes32 public immutable QUOTE_FEED_2;

    /// @inheritdoc IMorphoPythOracle
    uint256 public immutable SCALE_FACTOR;

    /// @inheritdoc IMorphoPythOracle
    /// @dev WARNING: Single staleness threshold applied to all feeds regardless of asset characteristics.
    ///      Fast-moving assets may need shorter max age (e.g., 15s) while stable assets could tolerate longer (e.g.,
    /// 60s).
    ///      Using a universal value may reject valid stable prices or accept stale volatile prices.
    ///      Consider asset-specific staleness checks for improved accuracy and reliability.
    uint256 public PRICE_FEED_MAX_AGE;

    /// @notice Initializes a new MorphoPythOracle instance
    /// @dev Constructor performs parameter validation but cannot prevent all misconfigurations.
    ///      Users must ensure parameters are appropriate for their use case.
    ///
    /// @param pyth_ Address of the Pyth contract - must be the official Pyth contract for the chain
    /// @param baseVault ERC-4626 vault for base asset, or address(0) to skip vault conversion
    /// @param baseVaultConversionSample Sample shares amount for base vault conversion (must provide adequate
    /// precision)
    /// @param baseFeed1 First Pyth price feed ID for base asset, or bytes32(0) for price=1
    /// @param baseFeed2 Second Pyth price feed ID for base asset, or bytes32(0) for price=1
    /// @param baseTokenDecimals Decimal places for base token
    /// @param quoteVault ERC-4626 vault for quote asset, or address(0) to skip vault conversion
    /// @param quoteVaultConversionSample Sample shares amount for quote vault conversion (must provide adequate
    /// precision)
    /// @param quoteFeed1 First Pyth price feed ID for quote asset, or bytes32(0) for price=1
    /// @param quoteFeed2 Second Pyth price feed ID for quote asset, or bytes32(0) for price=1
    /// @param quoteTokenDecimals Decimal places for quote token
    /// @param priceFeedMaxAge Maximum acceptable age in seconds for price feeds (applies to all feeds)
    ///
    /// @dev CRITICAL: Conversion samples must be large enough that convertToAssets() returns non-zero values.
    ///      Small samples may round to zero, breaking price calculations. Test with actual vault implementations!
    ///
    /// @dev VAULT SECURITY: If using vaults, ensure they are trusted implementations resistant to:
    ///      - Share price manipulation via direct token transfers
    ///      - Flash loan attacks that temporarily affect asset/share ratios
    ///      - Dynamic fee changes that alter convertToAssets() results
    ///      - First depositor attacks setting malicious initial exchange rates
    constructor(
        address pyth_,
        IERC4626 baseVault,
        uint256 baseVaultConversionSample,
        bytes32 baseFeed1,
        bytes32 baseFeed2,
        uint256 baseTokenDecimals,
        IERC4626 quoteVault,
        uint256 quoteVaultConversionSample,
        bytes32 quoteFeed1,
        bytes32 quoteFeed2,
        uint256 quoteTokenDecimals,
        uint256 priceFeedMaxAge
    ) {
        // The ERC4626 vault parameters are used to price their respective conversion samples of their respective
        // shares, so it requires multiplying by `QUOTE_VAULT_CONVERSION_SAMPLE` and dividing
        // by `BASE_VAULT_CONVERSION_SAMPLE` in the `SCALE_FACTOR` definition.
        // Verify that vault = address(0) => vaultConversionSample = 1 for each vault.
        require(
            address(baseVault) != address(0) || baseVaultConversionSample == 1,
            PythErrorsLib.VAULT_CONVERSION_SAMPLE_IS_NOT_ONE
        );
        require(
            address(quoteVault) != address(0) || quoteVaultConversionSample == 1,
            PythErrorsLib.VAULT_CONVERSION_SAMPLE_IS_NOT_ONE
        );
        require(baseVaultConversionSample != 0, PythErrorsLib.VAULT_CONVERSION_SAMPLE_IS_ZERO);
        require(quoteVaultConversionSample != 0, PythErrorsLib.VAULT_CONVERSION_SAMPLE_IS_ZERO);
        BASE_VAULT = baseVault;
        BASE_VAULT_CONVERSION_SAMPLE = baseVaultConversionSample;
        QUOTE_VAULT = quoteVault;
        QUOTE_VAULT_CONVERSION_SAMPLE = quoteVaultConversionSample;
        BASE_FEED_1 = baseFeed1;
        BASE_FEED_2 = baseFeed2;
        QUOTE_FEED_1 = quoteFeed1;
        QUOTE_FEED_2 = quoteFeed2;

        pyth = IPyth(pyth_);
        SCALE_FACTOR = (
            10
                ** (
                    36 + quoteTokenDecimals + PythFeedLib.getDecimals(pyth, QUOTE_FEED_1)
                        + PythFeedLib.getDecimals(pyth, QUOTE_FEED_2) - baseTokenDecimals
                        - PythFeedLib.getDecimals(pyth, BASE_FEED_1) - PythFeedLib.getDecimals(pyth, BASE_FEED_2)
                ) * quoteVaultConversionSample
        ) / baseVaultConversionSample;

        PRICE_FEED_MAX_AGE = priceFeedMaxAge;
    }

    /* PRICE */

    /// @inheritdoc IOracle
    /// @notice Calculates the current price by combining vault asset values and Pyth feed prices
    /// @return The calculated price with 18 decimal precision
    /// @dev Price calculation: SCALE_FACTOR * (baseAssets * baseFeeds) / (quoteAssets * quoteFeeds)
    ///
    /// SECURITY WARNINGS:
    /// - Vault prices can be manipulated if vaults are not manipulation-resistant
    /// - Single PRICE_FEED_MAX_AGE applied to all feeds regardless of asset volatility
    /// - Pyth confidence intervals are ignored - uncertain prices may be accepted
    /// - No per-block deviation caps - prices can change drastically within one block
    ///
    /// @dev This function will revert if:
    ///      - Any Pyth feed returns a negative price
    ///      - Any feed is older than PRICE_FEED_MAX_AGE
    ///      - Vault convertToAssets calls fail
    ///      - Arithmetic overflow in multiplication/division
    function price() external view returns (uint256) {
        return SCALE_FACTOR.mulDiv(
            BASE_VAULT.getAssets(BASE_VAULT_CONVERSION_SAMPLE)
                * PythFeedLib.getPrice(pyth, BASE_FEED_1, PRICE_FEED_MAX_AGE)
                * PythFeedLib.getPrice(pyth, BASE_FEED_2, PRICE_FEED_MAX_AGE),
            QUOTE_VAULT.getAssets(QUOTE_VAULT_CONVERSION_SAMPLE)
                * PythFeedLib.getPrice(pyth, QUOTE_FEED_1, PRICE_FEED_MAX_AGE)
                * PythFeedLib.getPrice(pyth, QUOTE_FEED_2, PRICE_FEED_MAX_AGE)
        );
    }
}

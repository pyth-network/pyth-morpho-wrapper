// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IMorphoPythOracle} from "./interfaces/IMorphoPythOracle.sol";
import {IMorphoPythOracleFactory} from "./interfaces/IMorphoPythOracleFactory.sol";
import {IERC4626} from "./libraries/VaultLib.sol";

import {MorphoPythOracle} from "./MorphoPythOracle.sol";

/// @title MorphoPythOracleFactory
/// @author Pyth Data Association
/// @notice Factory contract for creating MorphoPythOracle instances with permissionless deployment
/// @dev This factory provides a permissionless way to deploy MorphoPythOracle contracts. Users should carefully
///      validate all parameters and resulting oracle configurations before use in production environments.
///
/// Security Considerations:
/// - This factory accepts arbitrary Pyth contract addresses and feed IDs without validation
/// - Market creators and users must verify oracle addresses and configurations independently
/// - The factory only tracks that an oracle was deployed via this factory, not that it's safe to use
/// - Malicious actors can deploy oracles with fake Pyth contracts or manipulated vault addresses
///
/// @dev Following Morpho's design philosophy, this factory prioritizes flexibility over built-in safety checks.
///      See Morpho documentation on oracle risks and validation requirements.
contract MorphoPythOracleFactory is IMorphoPythOracleFactory {
    /* STORAGE */

    /// @inheritdoc IMorphoPythOracleFactory
    /// @dev This mapping only indicates that an oracle was deployed via this factory.
    ///      It does NOT guarantee the oracle configuration is safe or uses trusted parameters.
    ///      Users must independently verify oracle parameters including Pyth address and vault addresses.
    mapping(address => bool) public isMorphoPythOracle;

    /* EXTERNAL */

    /// @inheritdoc IMorphoPythOracleFactory
    /// @dev SECURITY WARNING: This function accepts arbitrary addresses and parameters without validation.
    ///      Callers can provide malicious Pyth contracts, manipulable vaults, or invalid feed IDs.
    ///
    /// Critical Validation Required by Users:
    /// - Verify `pyth` address matches the official Pyth contract for your chain
    /// - Validate all feed IDs exist and correspond to intended price feeds
    /// - Ensure vault addresses are trusted ERC-4626 implementations if used
    /// - Check that conversion samples provide adequate precision without overflow
    /// - Verify `priceFeedMaxAge` is appropriate for all asset types involved
    ///
    /// @dev Following Morpho's trust model: "Market creators and users need to carefully validate
    ///      the oracle address and its configuration." This includes all parameters passed to this function.
    function createMorphoPythOracle(
        address pyth,
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
        uint256 priceFeedMaxAge,
        bytes32 salt
    ) external returns (IMorphoPythOracle oracle) {
        oracle = new MorphoPythOracle{salt: salt}(
            pyth,
            baseVault,
            baseVaultConversionSample,
            baseFeed1,
            baseFeed2,
            baseTokenDecimals,
            quoteVault,
            quoteVaultConversionSample,
            quoteFeed1,
            quoteFeed2,
            quoteTokenDecimals,
            priceFeedMaxAge
        );

        isMorphoPythOracle[address(oracle)] = true;

        emit CreateMorphoPythOracle(msg.sender, address(oracle));
    }
}

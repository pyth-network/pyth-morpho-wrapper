// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MorphoPythOracleFactory} from "../src/morpho-pyth/MorphoPythOracleFactory.sol";
import {IMorphoPythOracle} from "../src/morpho-pyth/interfaces/IMorphoPythOracle.sol";
import {IERC4626} from "../src/interfaces/IERC4626.sol";

contract MorphoPythOracleDeploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the Pyth contract address for your chain from:
        // https://docs.pyth.network/price-feeds/contract-addresses/evm
        address pythPriceFeedsContract = vm.envAddress("PYTH_ADDRESS");

        // Get the address of the base vault
        address baseVault = vm.envAddress("BASE_VAULT");
        // Get the base vault conversion sample
        uint256 baseVaultConversionSample = vm.envUint("BASE_VAULT_CONVERSION_SAMPLE");

        // Get the base Price Feeds from
        // https://www.pyth.network/developers/price-feed-ids
        bytes32 baseFeed1 = vm.envBytes32("BASE_PRICE_FEED_1");
        bytes32 baseFeed2 = vm.envBytes32("BASE_PRICE_FEED_2");
        uint256 baseTokenDecimals = vm.envUint("BASE_TOKEN_DECIMALS");

        // Get the address of the quote vault
        address quoteVault = vm.envAddress("QUOTE_VAULT");
        // Get the quote vault conversion sample
        uint256 quoteVaultConversionSample = vm.envUint("QUOTE_VAULT_CONVERSION_SAMPLE");

        // Get the quote Price Feeds from
        // https://www.pyth.network/developers/price-feed-ids
        bytes32 quoteFeed1 = vm.envBytes32("QUOTE_PRICE_FEED_1");
        bytes32 quoteFeed2 = vm.envBytes32("QUOTE_PRICE_FEED_2");
        uint256 quoteTokenDecimals = vm.envUint("QUOTE_TOKEN_DECIMALS");

        // Set the price feed max age in seconds
        uint256 priceFeedMaxAge = vm.envUint("PRICE_FEED_MAX_AGE");

        // Get the salt for the oracle deployment
        bytes32 salt = vm.envBytes32("SALT");

        // Get the Factory address on your chain
        address factoryAddress = vm.envAddress("MORPHO_PYTH_ORACLE_FACTORY");

        MorphoPythOracleFactory factory = MorphoPythOracleFactory(factoryAddress);
        IMorphoPythOracle oracle = factory.createMorphoPythOracle(
            pythPriceFeedsContract,
            IERC4626(baseVault),
            baseVaultConversionSample,
            baseFeed1,
            baseFeed2,
            baseTokenDecimals,
            IERC4626(quoteVault),
            quoteVaultConversionSample,
            quoteFeed1,
            quoteFeed2,
            quoteTokenDecimals,
            priceFeedMaxAge,
            salt
        );

        console.log("Oracle deployed at:", address(oracle));

        vm.stopBroadcast();
    }
}
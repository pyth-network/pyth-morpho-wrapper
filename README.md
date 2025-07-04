# Pyth Morpho Wrapper

Pyth Morpho Wrapper is a wrapper around the Pyth oracle that can be used as an oracle for markets on [Morpho Blue](https://github.com/morpho-org/morpho-blue).

## MorphoPythOracle

The `MorphoPythOracle` is an oracle that uses Pyth to provide price data.

This oracle handles the following cases among others (let's say that our pair is A/B):

- A/B is a feed (typically, WBTC/BTC).
- B/A is a feed (typically, BTC/USD).
- A/C and B/C are feeds (typically, WBTC/BTC and BTC/USD).
- A/C, C/D and B/D are feeds (typically, WBTC/BTC, BTC/USD, USDC/USD).
- A/D, and B/C, C/D are feeds (typically, USDC/USD, WBTC/BTC, BTC/USD).
- A/C, C/D and B/E, E/D are feeds.
- A/C and C/B are feeds (typically, WBTC/BTC and BTC/ETH).

## Deploy an Oracle

To deploy a `MorphoPythOracle` on Ethereum, it is highly recommended to use the factory `MorphoPythOracleFactory`.
To do so, call the `createMorphoPythOracle` function with the following parameters:

- `pyth`: The Pyth contract address. This is the address of the Pyth contract deployed on the chain. You can find the address of the Pyth contract for each chain [here](https://docs.pyth.network/price-feeds/contract-addresses/evm).
- `baseVault`: The ERC4626 token vault for the base asset.
- `baseVaultConversionSample`: A sample amount for converting base vault units.
- `baseFeed1`, `baseFeed2`: Pyth price feed ids for the base asset. You can find the price feed ids for each asset [here](https://www.pyth.network/developers/price-feed-ids).
- `baseTokenDecimals`: Decimal precision of the base asset.  
- `quoteVault`: The ERC4626 token vault for the quote asset.
- `quoteVaultConversionSample`: A sample amount for converting quote vault units.
- `quoteFeed1`, `quoteFeed2`: Pyth price feed ids for the quote asset. You can find the price feed ids for each asset [here](https://www.pyth.network/developers/price-feed-ids).
- `quoteTokenDecimals`: Decimal precision of the quote asset.
- `priceFeedMaxAge`: The maximum age of the price feed in seconds. *Note: This adds a extra safety net to avoid using stale prices.*
- `salt`: A unique identifier to create deterministic addresses for deployed oracles.

**Warning:** If there is an ERC4626-compliant vault for `baseVault` or `quoteVault`, the `baseTokenDecimals` or `quoteTokenDecimals` are still the decimals of the underlying asset of the vault, and not the decimals of the Vault itself.
E.g: for a MetaMorpho WETH vault, as `baseVault`, the `baseTokenDecimals` is 18 as WETH has 18 decimals.

### Addresses

TODO:
The address on Ethereum of this factory is [](https://etherscan.io/address/#code).

### Examples

Below are the arguments to fill for the creation of the WBTC/USDT oracle on Base Mainnet:

```json
"pyth": "0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a",
"baseVault": "0x0000000000000000000000000000000000000000",
"baseVaultConversionSample": 1,
"baseFeed1": "0xc9d8b075a5c69303365ae23633d4e085199bf5c520a3b90fed1322a0342ffc33",
"baseFeed2": "0x0000000000000000000000000000000000000000000000000000000000000000",
"baseTokenDecimals": 8,
"quoteVault":"0x0000000000000000000000000000000000000000",
"quoteVaultConversionSample": 1,
"quoteFeed1": "0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b",
"quoteFeed2": "0x0000000000000000000000000000000000000000000000000000000000000000",
"quoteTokenDecimals": 6,
"priceFeedMaxAge": 3600,
"salt": "<user-defined value used to make the address unique>",
```


## Developers

Install dependencies: `forge install`

Install Pyth SDK:
```bash
npm init -y
npm install @pythnetwork/pyth-sdk-solidity
```

Run test: `forge test`

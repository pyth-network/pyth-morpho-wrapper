// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IMorphoPythOracle} from "../src/morpho-pyth/interfaces/IMorphoPythOracle.sol";
import {IERC4626} from "../src/interfaces/IERC4626.sol";

contract MorphoPythOracleRead is Script {
    function run() public {
        // Use an RPC fork so external calls hit the real chain state
        string memory rpcUrl = vm.envString("RPC");
        vm.createSelectFork(rpcUrl);

        // Get the Factory address on your chain
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        console.log("Oracle address:", oracleAddress);

        IMorphoPythOracle oracle = IMorphoPythOracle(oracleAddress);
        console.log("Pyth address:", address(oracle.pyth()));

        console2.log("Max age:", oracle.PRICE_FEED_MAX_AGE());

        console2.log("Price:", oracle.price());
    }
}

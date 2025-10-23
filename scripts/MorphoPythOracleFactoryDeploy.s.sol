// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MorphoPythOracleFactory} from "../src/morpho-pyth/MorphoPythOracleFactory.sol";

contract MorphoPythOracleFactoryDeploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MorphoPythOracleFactory factory = new MorphoPythOracleFactory();
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}

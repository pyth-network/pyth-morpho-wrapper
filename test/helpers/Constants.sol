// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC4626} from "../../src/interfaces/IERC4626.sol";

IERC4626 constant vaultZero = IERC4626(address(0));

// Pyth contract addresses
address constant pythBaseContractAddress = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;
address constant pythEthereumContractAddress = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;

// Pyth Price Feed IDs
bytes32 constant pythFeedZero = 0x0000000000000000000000000000000000000000000000000000000000000000;
bytes32 constant pythWbtcUsdFeed = 0xc9d8b075a5c69303365ae23633d4e085199bf5c520a3b90fed1322a0342ffc33;
uint256 constant pythWbtcUsdTokenDecimals = 8;
bytes32 constant pythEthUsdFeed = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
bytes32 constant pythUsdtUsdFeed = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;
uint256 constant pythUsdtUsdTokenDecimals = 6;
bytes32 constant pythCbethUsdFeed = 0x15ecddd26d49e1a8f1de9376ebebc03916ede873447c1255d2d5891b92ce5717;
// Time constants
uint256 constant oneHour = 3600;
uint256 constant oneMinute = 60;

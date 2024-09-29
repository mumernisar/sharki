// script/DeploySharky.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Sharky.sol";

contract DeploySharky is Script {
    function run() external {
        vm.startBroadcast();
        SharkFactory sharkFactory = new SharkFactory();
        vm.stopBroadcast();
        console.log("SharkFactory deployed at:", address(sharkFactory));
    }
}
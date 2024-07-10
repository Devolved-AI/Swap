// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/AMM.sol";

contract DeployAMM is Script {
    function run() external {
        // Get the WETH address from the environment variable
        address wethAddress = vm.envAddress("WETH_ADDRESS");
        require(wethAddress != address(0), "WETH address not set");

        vm.startBroadcast();

        // Deploy AMM contract with WETH address
        AMM amm = new AMM(wethAddress);

        console.log("AMM deployed at:", address(amm));

        vm.stopBroadcast();
    }
}

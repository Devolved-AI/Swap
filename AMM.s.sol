// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/AMM.sol";

contract DeployAMM is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the AMM contract
        AMM amm = new AMM();

        console.log("AMM deployed at:", address(amm));
        console.log("To initialize the AMM, call the initialize function with your chosen token addresses.");

        vm.stopBroadcast();
    }
}

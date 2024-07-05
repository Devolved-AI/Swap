// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/AMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployAMM is Script {
    function run() external {
        vm.startBroadcast();

        // Create mock tokens
        address token0 = address(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238); // USDC Address - Sepolia
        address token1 = address(0x8320a21f1088a97De8d2Aa288A715181Dd4142e3); // AGC Address - Sepolia
        AMM amm = new AMM(token0, token1);

        vm.stopBroadcast();
    }
}

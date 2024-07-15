// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./src/AMM.sol";

contract EchidnaTests is Test {
    AMM contractInstance;
    address constant WETH_ADDRESS = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    function setUp() public {
        contractInstance = new AMM(WETH_ADDRESS);
    }

    function testCreatePair() public {
        // Generate random token addresses
        address token0 = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))));
        address token1 = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))));

        // Call createPair with generated addresses
        contractInstance.createPair(token0, token1);
    }

    function testAddLiquidity() public {
        // Generate random pair ID, token amounts
        uint256 pairId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        uint256 amount0 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        uint256 amount1 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        // Attempt to add liquidity
        contractInstance.addLiquidity(pairId, amount0, amount1);
    }

    function testRemoveLiquidity() public {
        // Generate random pair ID, share amount
        uint256 pairId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        uint256 shares = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        // Attempt to remove liquidity
        contractInstance.removeLiquidity(pairId, shares);
    }

    function testSwap() public {
        // Generate random pair ID, token address, amount
        uint256 pairId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        address tokenIn = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))));
        uint256 amountIn = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        // Attempt to swap
        contractInstance.swap(pairId, tokenIn, amountIn);
    }

    function testWrap() public payable {
        // Send some Ether to the contract
        contractInstance.wrap{value: 1 ether}();

        // Assuming you have determined the pairId and accountAddress somehow 
        uint256 pairId = 1;
        address accountAddress = 0xd7Bc9888A66Bf8683521d65A7938A839406C2e0E;
 
        // Now, call getBalance with the correct arguments
        assertEq(contractInstance.getBalance(pairId, accountAddress), 1 ether);

        // Check balance
        assertEq(contractInstance.getBalance(pairId, accountAddress), 1 ether);
    }

    function testUnwrap() public {
        // Assuming you have determined the pairId and accountAddress somehow
        // uint256 pairId = 1;
        // address accountAddress = 0xd7Bc9888A66Bf8683521d65A7938A839406C2e0E;

        // Corrected call to getBalance with both required arguments
        // assertEq(contractInstance.getBalance(pairId, accountAddress), 1 ether);

        // Assume some Ether has been wrapped previously
        contractInstance.unwrap(1 ether);
    }
}

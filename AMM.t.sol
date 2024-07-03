// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract AMMTest is Test {
    AMM public amm;
    MockERC20 public token0;
    MockERC20 public token1;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        amm = new AMM();
        amm.initialize(address(token0), address(token1));
    }

    function testAddLiquidity() public {
        token0.approve(address(amm), 1000);
        token1.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        assertEq(amm.balanceOf(address(this)), 1000);
    }

    function testRemoveLiquidity() public {
        token0.approve(address(amm), 1000);
        token1.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        amm.removeLiquidity(1000);
        assertEq(amm.balanceOf(address(this)), 0);
    }

    function testSwap() public {
        token0.approve(address(amm), 1000);
        token1.approve(address(amm), 1000);
        amm.addLiquidity(1000, 1000);
        token0.approve(address(amm), 100);
        uint amountOut = amm.swap(address(token0), 100);
        assertGt(amountOut, 0);
    }

    function testFailAddLiquidityZeroAmount() public {
        amm.addLiquidity(0, 0);
    }

    function testFailRemoveLiquidityInsufficientShares() public {
        amm.removeLiquidity(1000);
    }

    function testFailSwapInvalidToken() public {
        MockERC20 invalidToken = new MockERC20("InvalidToken", "ITK");
        invalidToken.approve(address(amm), 100);
        amm.swap(address(invalidToken), 100);
    }
}

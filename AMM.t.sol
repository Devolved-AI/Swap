// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract AMMTest is Test {
    AMM public amm;
    MockERC20 public token0;
    MockERC20 public token1;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        amm = new AMM(address(token0), address(token1));
    }

    function addInitialLiquidity() internal {
        uint256 amount0 = 1000 * 10**18; // 1000 tokens
        uint256 amount1 = 1000 * 10**18; // 1000 tokens

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);

        token0.approve(address(amm), amount0);
        token1.approve(address(amm), amount1);

        amm.addLiquidity(amount0, amount1);
    }

    function testAddLiquidity() public {
        uint256 amount0 = 1000 * 10**18; // 1000 tokens
        uint256 amount1 = 1000 * 10**18; // 1000 tokens

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);

        token0.approve(address(amm), amount0);
        token1.approve(address(amm), amount1);

        uint256 shares = amm.addLiquidity(amount0, amount1);
        assertGt(shares, 0, "Shares should be greater than 0");
    }

    function testRemoveLiquidity() public {
        addInitialLiquidity();
    
        uint256 shares = amm.balanceOf(address(this));
        require(shares > 0, "No shares minted");

        amm.removeLiquidity(shares);

        assertEq(amm.balanceOf(address(this)), 0, "All shares should be burned");
        assertGt(token0.balanceOf(address(this)), 0, "Should have received token0");
        assertGt(token1.balanceOf(address(this)), 0, "Should have received token1");
    }
    
    function testSwap() public {
        addInitialLiquidity();

        uint256 swapAmount = 100 * 10**18; // 100 tokens
        token0.mint(address(this), swapAmount);
        token0.approve(address(amm), swapAmount);

        uint256 token1BalanceBefore = token1.balanceOf(address(this));
        amm.swap(address(token0), swapAmount);
        uint256 token1BalanceAfter = token1.balanceOf(address(this));

        assertGt(token1BalanceAfter, token1BalanceBefore, "Should have received token1");
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

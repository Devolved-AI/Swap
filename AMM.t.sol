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

contract MockWETH is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {}
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }
    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}

contract AMMTest is Test {
    AMM public amm;
    MockERC20 public token0;
    MockERC20 public token1;
    MockWETH public weth;
    uint256 public pairId;

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        weth = new MockWETH();
        amm = new AMM(address(weth));
        pairId = amm.createPair(address(token0), address(token1));
    }

    function addInitialLiquidity() internal {
        uint256 amount0 = 1000 * 10**18; // 1000 tokens
        uint256 amount1 = 1000 * 10**18; // 1000 tokens
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(amm), amount0);
        token1.approve(address(amm), amount1);
        amm.addLiquidity(pairId, amount0, amount1);
    }

    function testAddLiquidity() public {
        uint256 amount0 = 1000 * 10**18; // 1000 tokens
        uint256 amount1 = 1000 * 10**18; // 1000 tokens
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(amm), amount0);
        token1.approve(address(amm), amount1);
        uint256 shares = amm.addLiquidity(pairId, amount0, amount1);
        assertGt(shares, 0, "Shares should be greater than 0");
    }

    function testRemoveLiquidity() public {
        addInitialLiquidity();
    
        uint256 shares = amm.getBalance(pairId, address(this));
        require(shares > 0, "No shares minted");
        amm.removeLiquidity(pairId, shares);
        assertEq(amm.getBalance(pairId, address(this)), 0, "All shares should be burned");
        assertGt(token0.balanceOf(address(this)), 0, "Should have received token0");
        assertGt(token1.balanceOf(address(this)), 0, "Should have received token1");
    }
    
    function testSwap() public {
        addInitialLiquidity();
        uint256 swapAmount = 100 * 10**18; // 100 tokens
        token0.mint(address(this), swapAmount);
        token0.approve(address(amm), swapAmount);
        uint256 token1BalanceBefore = token1.balanceOf(address(this));
        amm.swap(pairId, address(token0), swapAmount);
        uint256 token1BalanceAfter = token1.balanceOf(address(this));
        assertGt(token1BalanceAfter, token1BalanceBefore, "Should have received token1");
    }

    function testWrap() public {
        uint256 wrapAmount = 1 ether;
        uint256 balanceBefore = weth.balanceOf(address(this));
        amm.wrap{value: wrapAmount}();
        uint256 balanceAfter = weth.balanceOf(address(this));
        assertEq(balanceAfter - balanceBefore, wrapAmount, "Should have received WETH");
    }

    function testUnwrap() public {
        uint256 wrapAmount = 1 ether;
        amm.wrap{value: wrapAmount}();
        weth.approve(address(amm), wrapAmount);
        uint256 ethBalanceBefore = address(this).balance;
        amm.unwrap(wrapAmount);
        uint256 ethBalanceAfter = address(this).balance;
        assertEq(ethBalanceAfter - ethBalanceBefore, wrapAmount, "Should have received ETH");
    }

    function testFailAddLiquidityZeroAmount() public {
        amm.addLiquidity(pairId, 0, 0);
    }

    function testFailRemoveLiquidityInsufficientShares() public {
        amm.removeLiquidity(pairId, 1000);
    }

    function testFailSwapInvalidToken() public {
        MockERC20 invalidToken = new MockERC20("InvalidToken", "ITK");
        invalidToken.approve(address(amm), 100);
        amm.swap(pairId, address(invalidToken), 100);
    }

    function testFailWrapZeroAmount() public {
        amm.wrap{value: 0}();
    }

    function testFailUnwrapZeroAmount() public {
        amm.unwrap(0);
    }

    receive() external payable {}
}

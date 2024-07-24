// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract AMMTest is Test {
    AMM public amm;
    ERC20Mock public token0;
    ERC20Mock public token1;
    address public wethAddress;
    address public owner;

    function setUp() public {
        wethAddress = address(0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14);
        amm = new AMM(wethAddress);
        owner = address(this);

        token0 = new ERC20Mock("Token0", "TK0", 10000 * 10**18);
        token1 = new ERC20Mock("Token1", "TK1", 10000 * 10**18);

        // Approve AMM contract to spend tokens
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);
    }

    function testCreatePair() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));

        (uint256 id, address t0, address t1) = amm.getPairInfo(pairId);

        assertEq(id, pairId);
        assertEq(t0, address(token0));
        assertEq(t1, address(token1));
    }

    function testAddLiquidity() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));
        uint256 amount0 = 100 * 10**18;
        uint256 amount1 = 100 * 10**18;
    
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
    
        console.log("Token0 balance:", token0.balanceOf(address(this)));
        console.log("Token1 balance:", token1.balanceOf(address(this)));
        console.log("AMM allowance for Token0:", token0.allowance(address(this), address(amm)));
        console.log("AMM allowance for Token1:", token1.allowance(address(this), address(amm)));
    
        uint256 shares = amm.addLiquidity(pairId, amount0, amount1);
    
        console.log("Shares minted:", shares);
        assertGt(shares, 0, "Should have minted some shares");
        assertEq(shares, amm.getBalance(pairId, address(this)), "Balance should match minted shares");
        assertEq(amm.getReserve0(pairId), amount0, "Reserve0 should match deposited amount");
        assertEq(amm.getReserve1(pairId), amount1, "Reserve1 should match deposited amount");
    }

    function testSwap() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));
        uint256 amount0 = 100 * 10**18;
        uint256 amount1 = 100 * 10**18;
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        amm.addLiquidity(pairId, amount0, amount1);

        uint256 amountIn = 10 * 10**18;
        token0.mint(address(this), amountIn);
        token0.approve(address(amm), amountIn);

        // Record the initial balance of token1
        uint256 initialToken1Balance = token1.balanceOf(address(this));

        // Calculate the expected amount out (this is a simplified calculation)
        uint256 expectedAmountOut = (amountIn * 997 * amount1) / (amount0 * 1000 + amountIn * 997);
    
        // Set minAmountOut to 95% of the expected amount out
        uint256 minAmountOut = (expectedAmountOut * 95) / 100;

        uint256 amountOut = amm.swap(pairId, address(token0), amountIn, minAmountOut);
    
        // Check that amountOut is greater than 0
        assertGt(amountOut, 0, "Amount out should be greater than 0");
    
        // Check that amountOut is greater than or equal to minAmountOut
        assertGe(amountOut, minAmountOut, "Amount out should be greater than or equal to minimum amount out");
    
        // Check that the actual change in token1 balance matches amountOut
        uint256 finalToken1Balance = token1.balanceOf(address(this));
        uint256 actualToken1Received = finalToken1Balance - initialToken1Balance;
    
        assertEq(actualToken1Received, amountOut, "Actual token1 received should match amountOut");

        // Print values for debugging
        console.log("Expected amount out:", expectedAmountOut);
        console.log("Minimum amount out:", minAmountOut);
        console.log("Actual amount out:", amountOut);
        console.log("Initial token1 balance:", initialToken1Balance);
        console.log("Final token1 balance:", finalToken1Balance);
        console.log("Actual token1 received:", actualToken1Received);
    }

    function testRemoveLiquidity() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));
        uint256 amount0 = 100 * 10**18;
        uint256 amount1 = 100 * 10**18;
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        uint256 shares = amm.addLiquidity(pairId, amount0, amount1);

        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        (uint256 removedAmount0, uint256 removedAmount1) = amm.removeLiquidity(pairId, shares);

        assertGt(removedAmount0, 0, "Should have removed some token0");
        assertGt(removedAmount1, 0, "Should have removed some token1");
        assertEq(token0.balanceOf(address(this)), initialBalance0 + removedAmount0, "Token0 balance should increase");
        assertEq(token1.balanceOf(address(this)), initialBalance1 + removedAmount1, "Token1 balance should increase");
        assertEq(amm.getBalance(pairId, address(this)), 0, "Should have no shares left");
    }

    function testSetSwapFee() public {
        uint256 newFee = 50; // 0.5%
        amm.setSwapFee(newFee);
        assertEq(amm.swapFee(), newFee, "Swap fee should be updated");
    }

    function testWithdrawFees() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));
        uint256 amount0 = 1000 * 10**18;
        uint256 amount1 = 1000 * 10**18;
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        amm.addLiquidity(pairId, amount0, amount1);

        uint256 swapAmount = 100 * 10**18;
        token0.mint(address(this), swapAmount);
        amm.swap(pairId, address(token0), swapAmount, 0);

        uint256 initialBalance = token0.balanceOf(owner);
        uint256 fees = amm.getAccumulatedFees();
        assertGt(fees, 0, "Should have accumulated some fees");

        vm.prank(owner);  // Set the next call's sender to be the owner
        amm.withdrawFees();

        assertEq(token0.balanceOf(owner), initialBalance + fees, "Owner should receive accumulated fees");
        assertEq(amm.getAccumulatedFees(), 0, "Accumulated fees should be reset to 0");
    }

    function testWrapAndUnwrap() public {
        uint256 amount = 1 ether;
    
        // Test wrap
        amm.wrap{value: amount}();
        assertEq(IERC20(wethAddress).balanceOf(address(this)), amount, "Should have received WETH");

        // Test unwrap
        IERC20(wethAddress).approve(address(amm), amount);
        uint256 initialBalance = address(this).balance;
        amm.unwrap(amount);
        assertEq(address(this).balance, initialBalance + amount, "Should have received ETH");
        assertEq(IERC20(wethAddress).balanceOf(address(this)), 0, "Should have no WETH left");
    }

    function testWrapWithZeroValue() public {
        vm.expectRevert("Must send ETH to wrap");
        amm.wrap{value: 0}();
    }

    function testUnwrapWithZeroAmount() public {
        vm.expectRevert("Amount must be greater than 0");
        amm.unwrap(0);
    }

    function testPauseAndUnpause() public {
        // Ensure the contract is not paused initially
        assertFalse(amm.paused(), "Contract should not be paused initially");

        // Pause the contract
        vm.prank(owner);
        amm.pause();
        assertTrue(amm.paused(), "Contract should be paused");

        // Try to create a pair while paused
        vm.expectRevert(bytes("Pausable: paused"));
        amm.createPair(address(token0), address(token1));

        // Unpause the contract
        vm.prank(owner);
        amm.unpause();
        assertFalse(amm.paused(), "Contract should be unpaused");

        // Create a pair when unpaused
        uint256 pairId = amm.createPair(address(token0), address(token1));
        assertGt(pairId, 0, "Should be able to create pair when unpaused");
    }

    receive() external payable {}

}

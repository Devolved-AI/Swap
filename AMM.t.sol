// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockWETH is IWETH {
    mapping(address => uint256) public balances;

    function deposit() external payable override {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external override {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function totalSupply() external pure returns (uint256) {
        return 1000000 ether;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function allowance(address owner, address spender) external pure returns (uint256) {
        return 0;
    }

    function approve(address spender, uint256 amount) external pure returns (bool) {
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        balances[sender] -= amount;
        balances[recipient] += amount;
        return true;
    }
}

contract MockERC20 is IERC20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupplyValue;
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol, uint256 initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupplyValue = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    function totalSupply() external view override returns (uint256) {
        return totalSupplyValue;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        balances[to] += amount;
        totalSupplyValue += amount;
    }
}

contract AMMTest is Test {
    AMM public amm;
    MockWETH public weth;
    MockERC20 public token0;
    MockERC20 public token1;
    address public owner;

    receive() external payable {}

    function setUp() public {
        owner = address(this);
        weth = new MockWETH();
        amm = new AMM(address(weth));
        token0 = new MockERC20("Token0", "TKN0", 1000000 ether);
        token1 = new MockERC20("Token1", "TKN1", 1000000 ether);
    }

    function testCreatePair() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));
        assertEq(pairId, 1, "Pair ID should be 1");

        (uint256 returnedPairId, address returnedToken0, address returnedToken1) = amm.getPairInfo(pairId);
        assertEq(returnedPairId, pairId, "Returned pair ID should match");
        assertEq(returnedToken0, address(token0), "Returned token0 should match");
        assertEq(returnedToken1, address(token1), "Returned token1 should match");
    }

    function testAddLiquidity() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;

        token0.approve(address(amm), amount0);
        token1.approve(address(amm), amount1);

        uint256 shares = amm.addLiquidity(pairId, amount0, amount1);
        assertGt(shares, 0, "Shares should be greater than 0");

        assertEq(amm.getBalance(pairId, address(this)), shares, "Balance should match shares");
        assertEq(amm.getReserve0(pairId), amount0, "Reserve0 should match amount0");
        assertEq(amm.getReserve1(pairId), amount1, "Reserve1 should match amount1");
    }

    function testRemoveLiquidity() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;

        token0.approve(address(amm), amount0);
        token1.approve(address(amm), amount1);

        uint256 shares = amm.addLiquidity(pairId, amount0, amount1);
        
        (uint256 removed0, uint256 removed1) = amm.removeLiquidity(pairId, shares);
        assertGt(removed0, 0, "Removed amount0 should be greater than 0");
        assertGt(removed1, 0, "Removed amount1 should be greater than 0");

        assertEq(amm.getBalance(pairId, address(this)), 0, "Balance should be 0 after removing all liquidity");
    }

    function testSwap() public {
        uint256 pairId = amm.createPair(address(token0), address(token1));
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;

        token0.approve(address(amm), amount0);
        token1.approve(address(amm), amount1);

        amm.addLiquidity(pairId, amount0, amount1);

        uint256 swapAmount = 10 ether;
        token0.approve(address(amm), swapAmount);

        uint256 amountOut = amm.swap(pairId, address(token0), swapAmount, 1);
        assertGt(amountOut, 0, "Swap amount out should be greater than 0");
    }

    function testSetSwapFee() public {
        uint256 newFee = 50; // 0.5%
        amm.setSwapFee(newFee);
        assertEq(amm.swapFee(), newFee, "Swap fee should be updated");
    }

    function testWrap() public {
        uint256 wrapAmount = 1 ether;
        amm.wrap{value: wrapAmount}();
        assertEq(weth.balanceOf(address(this)), wrapAmount, "WETH balance should match wrapped amount");
    }

    function testUnwrap() public {
        uint256 wrapAmount = 1 ether;
        amm.wrap{value: wrapAmount}();

        weth.approve(address(amm), wrapAmount);
        uint256 balanceBefore = address(this).balance;
        amm.unwrap(wrapAmount);
        uint256 balanceAfter = address(this).balance;

        assertEq(balanceAfter - balanceBefore, wrapAmount, "ETH balance should increase by unwrapped amount");
    }

    function testPause() public {
        amm.pause();
        assertTrue(amm.paused(), "Contract should be paused");
    }

    function testUnpause() public {
        amm.pause();
        amm.unpause();
        assertFalse(amm.paused(), "Contract should be unpaused");
    }
}

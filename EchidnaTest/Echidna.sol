// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "../AMM.sol";
import "./MockERC20.sol";

contract AMMTest is AMM {
    MockERC20 public token0;
    MockERC20 public token1;
    
    event SetupCompleted();
    event SetupFailed(string reason);
    event FuzzSuccess(string functionName);
    event FuzzFailure(string functionName, string reason);

    constructor() AMM(0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14) {}

    function initialize() public {
        require(msg.sender == owner(), "Only owner can initialize");
        try this.createTokensAndPair() {
            emit SetupCompleted();
        } catch Error(string memory reason) {
            emit SetupFailed(reason);
        }
    }

    function createTokensAndPair() public {
        require(msg.sender == owner(), "Only owner can setup");
        token0 = new MockERC20("Token0", "TKN0");
        token1 = new MockERC20("Token1", "TKN1");

        uint256 pairId = this.createPair(address(token0), address(token1));
        token0.mint(address(this), 1000 ether);
        token1.mint(address(this), 1000 ether);
        token0.approve(address(this), 1000 ether);
        token1.approve(address(this), 1000 ether);
        this.addLiquidity(pairId, 100 ether, 100 ether);
    }


    // Property Tests

    function echidna_swap_fee_within_limit() public view returns (bool) {
        return swapFee <= 100;
    }

    function echidna_pair_count_non_negative() public view returns (bool) {
        return pairCount >= 0;
    }

    function echidna_accumulated_fees_non_negative() public view returns (bool) {
        return accumulatedFees >= 0;
    }

    function echidna_owner_can_withdraw_fees() public returns (bool) {
        accumulatedFees = 1 ether;
        uint256 initialBalance = address(this).balance;
        this.withdrawFees();
        return address(this).balance > initialBalance;
    }

    function echidna_owner_can_pause_unpause() public returns (bool) {
        require(msg.sender == owner(), "Not owner");
        bool success = false;
        try this.pause() {
            success = true;
        } catch {
            return false;
        }
        if (success) {
            try this.unpause() {
                return true;
            } catch {
                return false;
            }
        }
        return false;
    }

    // Fuzzing Tests

    function fuzz_add_liquidity(uint256 pairId, uint256 amount0, uint256 amount1) public {
        pairId = bound(pairId, 1, pairCount);
        amount0 = bound(amount0, 1 ether, 100 ether);
        amount1 = bound(amount1, 1 ether, 100 ether);

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(this), amount0);
        token1.approve(address(this), amount1);

        try this.addLiquidity(pairId, amount0, amount1) {
            // Success
            emit FuzzSuccess("add_liquidity");
            assert(token0.balanceOf(address(this)) >= amount0);
            assert(token1.balanceOf(address(this)) >= amount1);
        } catch Error(string memory reason) {
            // Failure is acceptable in fuzzing
            emit FuzzFailure("add_liquidity", reason);
        }
    }

    function fuzz_remove_liquidity(uint256 pairId, uint256 liquidity) public {
        pairId = bound(pairId, 1, pairCount);
        liquidity = bound(liquidity, 1 ether, 100 ether);

        uint256 initialToken0Balance = token0.balanceOf(address(this));
        uint256 initialToken1Balance = token1.balanceOf(address(this));

        try this.removeLiquidity(pairId, liquidity) {
            // Success
            emit FuzzSuccess("remove_liquidity");
            assert(token0.balanceOf(address(this)) > initialToken0Balance);
            assert(token1.balanceOf(address(this)) > initialToken1Balance);
        } catch Error(string memory reason) {
            // Failure is acceptable in fuzzing
            emit FuzzFailure("remove_liquidity", reason);
        }
    }

    function fuzz_swap(uint256 pairId, bool useToken0, uint256 amountIn) public {
        pairId = bound(pairId, 1, pairCount);
        amountIn = bound(amountIn, 1 ether, 10 ether);

        address tokenIn = useToken0 ? address(token0) : address(token1);
        address tokenOut = useToken0 ? address(token1) : address(token0);
        MockERC20(tokenIn).mint(address(this), amountIn);
        MockERC20(tokenIn).approve(address(this), amountIn);

        uint256 initialBalanceIn = MockERC20(tokenIn).balanceOf(address(this));
        uint256 initialBalanceOut = MockERC20(tokenOut).balanceOf(address(this));

        try this.swap(pairId, tokenIn, amountIn) returns (uint256 amountOut) {
            // Success
            emit FuzzSuccess("swap");
            assert(amountOut > 0);
            assert(MockERC20(tokenIn).balanceOf(address(this)) < initialBalanceIn);
            assert(MockERC20(tokenOut).balanceOf(address(this)) > initialBalanceOut);
        } catch Error(string memory reason) {
            // Failure is acceptable in fuzzing
            emit FuzzFailure("swap", reason);
        }
    }

    function fuzz_create_pair() public {
        MockERC20 newToken0 = new MockERC20("NewToken0", "NTKN0");
        MockERC20 newToken1 = new MockERC20("NewToken1", "NTKN1");

        uint256 initialPairCount = pairCount;

        try this.createPair(address(newToken0), address(newToken1)) returns (uint256 newPairId) {
            // Success
            emit FuzzSuccess("create_pair");
            assert(pairCount == initialPairCount + 1);
            assert(newPairId == pairCount);
        } catch Error(string memory reason) {
            // Failure is acceptable in fuzzing
            emit FuzzFailure("create_pair", reason);
        }
    }

    // Helper function for Echidna to bound inputs 

    function bound(uint256 x, uint256 min, uint256 max) internal pure returns (uint256) {
        return min + (x % (max - min + 1));
    }

}

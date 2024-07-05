// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract AMM is ReentrancyGuard, Pausable {
    struct LiquidityPair {
        IERC20 token0;
        IERC20 token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        mapping(address => uint256) balanceOf;
    }

    struct PairInfo {
        address token0;
        address token1;
    }

    mapping(uint256 => LiquidityPair) public liquidityPairs;
    mapping(uint256 => PairInfo) public pairInfo;
    mapping(address => mapping(address => uint256)) public getPairId;
    uint256 public pairCount;

    uint256 private constant MINIMUM_LIQUIDITY = 1000;
    uint256 private unlocked = 1;

    event PairCreated(address indexed token0, address indexed token1, uint256 pairId);
    event LiquidityAdded(uint256 indexed pairId, address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event LiquidityRemoved(uint256 indexed pairId, address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event Swap(uint256 indexed pairId, address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);

    modifier lock() {
        require(unlocked == 1, "AMM: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function createPair(address _token0, address _token1) external returns (uint256 pairId) {
        require(_token0 != address(0) && _token1 != address(0), "Invalid token address");
        require(_token0 != _token1, "Tokens must be different");
        require(getPairId[_token0][_token1] == 0, "Pair already exists");

        pairCount++;
        pairId = pairCount;

        liquidityPairs[pairId].token0 = IERC20(_token0);
        liquidityPairs[pairId].token1 = IERC20(_token1);
        pairInfo[pairId] = PairInfo({token0: _token0, token1: _token1});
        getPairId[_token0][_token1] = pairId;
        getPairId[_token1][_token0] = pairId;

        emit PairCreated(_token0, _token1, pairId);
    }

    function getPairInfo(uint256 _pairId) external view returns (uint256, address, address) {
        require(_pairId > 0 && _pairId <= pairCount, "Invalid pair ID");
        PairInfo memory info = pairInfo[_pairId];
        return (_pairId, info.token0, info.token1);
    }

    function addLiquidity(uint256 _pairId, uint256 _amount0, uint256 _amount1)
        external
        nonReentrant
        lock
        whenNotPaused
        returns (uint256 shares)
    {
        require(_pairId > 0 && _pairId <= pairCount, "Pair does not exist");
        LiquidityPair storage pair = liquidityPairs[_pairId];
        require(_amount0 > 0 && _amount1 > 0, "Amounts must be greater than 0");

        uint256 balance0Before = pair.token0.balanceOf(address(this));
        uint256 balance1Before = pair.token1.balanceOf(address(this));

        pair.token0.transferFrom(msg.sender, address(this), _amount0);
        pair.token1.transferFrom(msg.sender, address(this), _amount1);

        uint256 balance0After = pair.token0.balanceOf(address(this));
        uint256 balance1After = pair.token1.balanceOf(address(this));

        uint256 amount0 = balance0After - balance0Before;
        uint256 amount1 = balance1After - balance1Before;

        if (pair.totalSupply == 0) {
            shares = _sqrt(amount0 * amount1);
            require(shares > MINIMUM_LIQUIDITY, "Initial liquidity too low");
            _mint(_pairId, address(0), MINIMUM_LIQUIDITY);
            shares -= MINIMUM_LIQUIDITY;
        } else {
            shares = _min(
                (amount0 * pair.totalSupply) / pair.reserve0,
                (amount1 * pair.totalSupply) / pair.reserve1
            );
        }

        require(shares > 0, "Shares = 0");
        _mint(_pairId, msg.sender, shares);

        _update(_pairId, balance0After, balance1After);

        emit LiquidityAdded(_pairId, msg.sender, amount0, amount1, shares);
    }

    function removeLiquidity(uint256 _pairId, uint256 _shares)
        external
        nonReentrant
        lock
        whenNotPaused
        returns (uint256 amount0, uint256 amount1)
    {
        require(_pairId > 0 && _pairId <= pairCount, "Pair does not exist");
        LiquidityPair storage pair = liquidityPairs[_pairId];
        require(_shares > 0, "Shares must be greater than 0");
        require(pair.balanceOf[msg.sender] >= _shares, "Insufficient shares");

        uint256 bal0 = pair.token0.balanceOf(address(this));
        uint256 bal1 = pair.token1.balanceOf(address(this));

        amount0 = (_shares * bal0) / pair.totalSupply;
        amount1 = (_shares * bal1) / pair.totalSupply;

        require(amount0 > 0 && amount1 > 0, "Insufficient liquidity");

        _burn(_pairId, msg.sender, _shares);
        _update(_pairId, bal0 - amount0, bal1 - amount1);

        pair.token0.transfer(msg.sender, amount0);
        pair.token1.transfer(msg.sender, amount1);

        emit LiquidityRemoved(_pairId, msg.sender, amount0, amount1, _shares);
    }

    function swap(uint256 _pairId, address _tokenIn, uint256 _amountIn)
        external
        nonReentrant
        lock
        whenNotPaused
        returns (uint256 amountOut)
    {
        require(_pairId > 0 && _pairId <= pairCount, "Pair does not exist");
        LiquidityPair storage pair = liquidityPairs[_pairId];
        require(
            _tokenIn == address(pair.token0) || _tokenIn == address(pair.token1),
            "Invalid token"
        );
        require(_amountIn > 0, "Amount in = 0");
        
        bool isToken0 = _tokenIn == address(pair.token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) = isToken0
            ? (pair.token0, pair.token1, pair.reserve0, pair.reserve1)
            : (pair.token1, pair.token0, pair.reserve1, pair.reserve0);

        uint256 amountInWithFee = (_amountIn * 997) / 1000;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        require(amountOut > 0 && amountOut <= reserveOut, "Insufficient output amount");

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        tokenOut.transfer(msg.sender, amountOut);

        _update(
            _pairId,
            pair.token0.balanceOf(address(this)),
            pair.token1.balanceOf(address(this))
        );

        emit Swap(_pairId, msg.sender, _tokenIn, _amountIn, amountOut);
    }

    function getBalance(uint256 _pairId, address _account) public view returns (uint256) {
        require(_pairId > 0 && _pairId <= pairCount, "Invalid pair ID");
        return liquidityPairs[_pairId].balanceOf[_account];
    }

    function _mint(uint256 _pairId, address _to, uint256 _amount) private {
        LiquidityPair storage pair = liquidityPairs[_pairId];
        pair.balanceOf[_to] += _amount;
        pair.totalSupply += _amount;
    }

    function _burn(uint256 _pairId, address _from, uint256 _amount) private {
        LiquidityPair storage pair = liquidityPairs[_pairId];
        pair.balanceOf[_from] -= _amount;
        pair.totalSupply -= _amount;
    }

    function _update(uint256 _pairId, uint256 _reserve0, uint256 _reserve1) private {
        LiquidityPair storage pair = liquidityPairs[_pairId];
        pair.reserve0 = _reserve0;
        pair.reserve1 = _reserve1;
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }
}

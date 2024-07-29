// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AMM is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;
    address public immutable wethAddress;

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

    struct SwapInfo {
        uint256 pairId;
        bool isToken0;
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 protocolFee;
    }

    struct AddLiquidityParams {
        uint256 pairId;
        uint256 amount0;
        uint256 amount1;
        uint256 balance0Before;
        uint256 balance1Before;
        uint256 balance0After;
        uint256 balance1After;
    }

    mapping(uint256 => LiquidityPair) public liquidityPairs;
    mapping(uint256 => PairInfo) public pairInfo;
    mapping(address => mapping(address => uint256)) public getPairId;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public pairCount;

    uint256 private constant MINIMUM_LIQUIDITY = 1;
    uint256 private unlocked = 1;

    uint256 public swapFee = 30; // 0.3% default fee (30 / 10000)
    uint256 private constant LP_FEE_SHARE = 85; // 85% of the fee goes to LP

    event PairCreated(address indexed token0, address indexed token1, uint256 pairId);
    event LiquidityAdded(uint256 indexed pairId, address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event LiquidityRemoved(uint256 indexed pairId, address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event Swap(uint256 indexed pairId, address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
    event SwapFeeUpdated(uint256 newFee);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier lock() {
        require(unlocked == 1, "AMM: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _wethAddress) payable Ownable(msg.sender) {
        require(_wethAddress != address(0), "Invalid WETH address");
        wethAddress = _wethAddress;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal returns (bool) {
        require(owner != address(0), "ERC20: zero address");
        require(spender != address(0), "ERC20: zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function setSwapFee(uint256 _swapFee) external onlyOwner {
        require(_swapFee < 101, "Fee cannot exceed 1%");
        if (swapFee != _swapFee) {
            swapFee = _swapFee;
            emit SwapFeeUpdated(_swapFee);
        }
    }

    function wrap() external payable {
        require(msg.value != 0, "Must send ETH to wrap");
        IWETH(wethAddress).deposit{value: msg.value}();
        require(IWETH(wethAddress).transfer(msg.sender, msg.value), "WETH transfer failed");
    }

    function unwrap(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
    
        // Transfer WETH from user to contract
        IWETH weth = IWETH(wethAddress);
        require(weth.transferFrom(msg.sender, address(this), amount), "WETH transfer failed");
    
        // Withdraw ETH from WETH contract
        weth.withdraw(amount);
    
        // Transfer ETH to user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function createPair(address _token0, address _token1) external whenNotPaused returns (uint256 pairId) {
        require(_token0 != address(0) && _token1 != address(0), "Invalid token address");
        require(_token0 != _token1, "Tokens must be different");
        require(getPairId[_token0][_token1] == 0, "Pair already exists");

        pairCount++;
        pairId = pairCount;

        liquidityPairs[pairId].token0 = IERC20(_token0);
        liquidityPairs[pairId].token1 = IERC20(_token1);

        require(liquidityPairs[pairId].token0.totalSupply() != 0, "Token0 not ERC20");
        require(liquidityPairs[pairId].token1.totalSupply() != 0, "Token1 not ERC20");

        pairInfo[pairId] = PairInfo({token0: _token0, token1: _token1});
        getPairId[_token0][_token1] = pairId;
        getPairId[_token1][_token0] = pairId;

        emit PairCreated(_token0, _token1, pairId);
    }

    function getPairInfo(uint256 _pairId) external view returns (uint256, address, address) {
        require(_pairId > 0 && _pairId < pairCount + 1, "Invalid pair ID");
        PairInfo memory info = pairInfo[_pairId];
        return (_pairId, info.token0, info.token1);
    }

    function getReserve0(uint256 pairId) public view returns (uint256) {
        return liquidityPairs[pairId].reserve0;
    }

    function getReserve1(uint256 pairId) public view returns (uint256) {
        return liquidityPairs[pairId].reserve1;
    }

    function getBalance(uint256 _pairId, address _account) public view returns (uint256) {
        require(_pairId > 0 && _pairId < pairCount + 1, "Invalid pair ID");
        return liquidityPairs[_pairId].balanceOf[_account];
    }

    function _update(uint256 _pairId, uint256 _reserve0, uint256 _reserve1) internal {
        liquidityPairs[_pairId].reserve0 = _reserve0;
        liquidityPairs[_pairId].reserve1 = _reserve1;
    }

    function addLiquidity(uint256 _pairId, uint256 _amount0, uint256 _amount1)
        external
        nonReentrant
        lock
        whenNotPaused
        returns (uint256 shares)
    {
        require(_pairId > 0 && _pairId < pairCount + 1, "Pair does not exist");
        require(_amount0 != 0 && _amount1 != 0, "Amounts must be greater than 0");

        LiquidityPair storage pair = liquidityPairs[_pairId];
        uint256 reserve0 = pair.reserve0;
        uint256 reserve1 = pair.reserve1;

        uint256 balance0After = reserve0 + _amount0;
        uint256 balance1After = reserve1 + _amount1;

        // Calculate shares
        if (pair.totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
            require(shares > MINIMUM_LIQUIDITY, "Initial liquidity too low");
            _mint(_pairId, address(0), MINIMUM_LIQUIDITY);
            shares -= MINIMUM_LIQUIDITY;
        } else {
            shares = _min(
                (_amount0 * pair.totalSupply) / reserve0,
                (_amount1 * pair.totalSupply) / reserve1
            );
        }

        require(shares != 0, "Shares = 0");

        // Update state variables
        _update(_pairId, balance0After, balance1After);
        _mint(_pairId, msg.sender, shares);

        // Transfer tokens to contract
        pair.token0.safeTransferFrom(msg.sender, address(this), _amount0);
        pair.token1.safeTransferFrom(msg.sender, address(this), _amount1);

        emit LiquidityAdded(_pairId, msg.sender, _amount0, _amount1, shares);

        return shares;
    }

    function removeLiquidity(uint256 _pairId, uint256 _shares)
        external
        nonReentrant
        lock
        whenNotPaused
        returns (uint256 amount0, uint256 amount1)
    {
        require(_pairId != 0 && _pairId <= pairCount, "Pair does not exist");
        LiquidityPair storage pair = liquidityPairs[_pairId];
        require(_shares != 0, "Shares must be greater than 0");
        require(pair.balanceOf[msg.sender] > _shares - 1, "Insufficient shares");

        uint256 reserve0 = pair.reserve0;
        uint256 reserve1 = pair.reserve1;

                amount0 = (_shares * reserve0) / pair.totalSupply;
        amount1 = (_shares * reserve1) / pair.totalSupply;

        require(amount0 != 0 && amount1 != 0, "Insufficient liquidity");

        _burn(_pairId, msg.sender, _shares);
        _update(_pairId, reserve0 - amount0, reserve1 - amount1);

        pair.token0.safeTransfer(msg.sender, amount0);
        pair.token1.safeTransfer(msg.sender, amount1);

        emit LiquidityRemoved(_pairId, msg.sender, amount0, amount1, _shares);
    }

    function swap(
        uint256 _pairId,
        address _tokenIn,
        uint256 _amountIn,
        uint256 _minAmountOut
    )
        external
        nonReentrant
        lock
        whenNotPaused
        returns (uint256 amountOut)
    {
        require(_pairId > 0 && _pairId < pairCount + 1, "Pair does not exist");
        LiquidityPair storage pair = liquidityPairs[_pairId];
        require(
            _tokenIn == address(pair.token0) || _tokenIn == address(pair.token1),
            "Invalid token"
        );
        require(_amountIn != 0, "Amount in = 0");
        require(_minAmountOut < 1001, "Slippage tolerance too high"); // Max 10% slippage

        bool isToken0 = _tokenIn == address(pair.token0);
        uint256 reserveIn = isToken0 ? pair.reserve0 : pair.reserve1;
        uint256 reserveOut = isToken0 ? pair.reserve1 : pair.reserve0;

        uint256 amountInWithFee = _amountIn * (10000 - swapFee);
        amountOut = (amountInWithFee * reserveOut) / ((reserveIn * 10000) + amountInWithFee);

        require(amountOut > _minAmountOut - 1, "Insufficient output amount");

        // Update reserves
        uint256 newReserveIn = reserveIn + _amountIn;
        uint256 newReserveOut = reserveOut - amountOut;
        _update(_pairId, isToken0 ? newReserveIn : newReserveOut, isToken0 ? newReserveOut : newReserveIn);

        // Transfer fees to the owner
        uint256 fee = (_amountIn * swapFee) / 10000;
        IERC20(isToken0 ? pair.token0 : pair.token1).safeTransferFrom(msg.sender, owner(), fee);

        // Transfer tokens
        IERC20(isToken0 ? pair.token0 : pair.token1).safeTransferFrom(msg.sender, address(this), _amountIn - fee);
        IERC20(isToken0 ? pair.token1 : pair.token0).safeTransfer(msg.sender, amountOut);

        emit Swap(_pairId, msg.sender, _tokenIn, _amountIn, amountOut);

        return amountOut;
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

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y >= 3) {
            z = y;
            uint256 x = (y >> 1) + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) >> 1;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    function pause() external payable onlyOwner {
        _pause();
    }

    function unpause() external payable onlyOwner {
        _unpause();
    }

    receive() external payable {}

    function getUnlocked() external view returns (uint256) {
        return unlocked;
    }
}

pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Ownable2Step {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed currentOwner, address indexed pendingOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(_owner, newOwner);
    }

    function acceptOwnership() public {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pending owner");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}

contract AMM is ReentrancyGuard, Pausable, Ownable2Step {
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

    mapping(uint256 => LiquidityPair) public liquidityPairs;
    mapping(uint256 => PairInfo) public pairInfo;
    mapping(address => mapping(address => uint256)) public getPairId;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public accumulatedFees;

    uint256 public pairCount;
    uint256 private constant MINIMUM_LIQUIDITY = 1;
    uint256 private unlocked = 1;
    uint256 public swapFee = 30; // 0.3% default fee (30 / 10000)
    uint256 private constant LP_FEE_SHARE = 85; // 85% of the fee goes to LP

    // Emergency withdrawal flag
    bool public emergencyWithdrawEnabled;

    // Custom Errors
    error InvalidWETHAddress();
    error InvalidAddress();
    error PairAlreadyExists();
    error TokenNotERC20();
    error PairDoesNotExist();
    error AmountMustBeGreaterThanZero();
    error InsufficientShares();
    error InsufficientLiquidity();
    error NoFeesAvailable();
    error InitialLiquidityTooLow();
    error SharesAreZero();
    error FeeExceedsOnePercent();
    error TokenAddressMismatch();
    error SlippageTooHigh();

    event PairCreated(address indexed token0, address indexed token1, uint256 pairId);
    event LiquidityAdded(uint256 indexed pairId, address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event LiquidityRemoved(uint256 indexed pairId, address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event Swap(uint256 indexed pairId, address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
    event SwapFeeUpdated(uint256 newFee);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FeePaid(uint256 indexed pairId, address indexed tokenIn, uint256 feeAmount);
    event EmergencyWithdrawEnabled();
    event EmergencyWithdrawExecuted(address indexed user, uint256 indexed pairId, uint256 amount0, uint256 amount1);

    constructor(address _wethAddress) payable {
        if (_wethAddress == address(0)) revert InvalidWETHAddress();
        wethAddress = _wethAddress;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal returns (bool) {
        if (owner == address(0) || spender == address(0)) revert InvalidAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function setSwapFee(uint256 _swapFee) external onlyOwner {
        if (_swapFee >= 101) revert FeeExceedsOnePercent();
        if (swapFee != _swapFee) {
            swapFee = _swapFee;
            emit SwapFeeUpdated(_swapFee);
        }
    }

    function createPair(address _token0, address _token1) external whenNotPaused returns (uint256 pairId) {
        if (_token0 == address(0) || _token1 == address(0)) revert InvalidAddress();
        if (_token0 == _token1) revert TokenAddressMismatch();
        if (getPairId[_token0][_token1] != 0) revert PairAlreadyExists();

        pairCount++;
        pairId = pairCount;

        liquidityPairs[pairId].token0 = IERC20(_token0);
        liquidityPairs[pairId].token1 = IERC20(_token1);

        if (liquidityPairs[pairId].token0.totalSupply() == 0) revert TokenNotERC20();
        if (liquidityPairs[pairId].token1.totalSupply() == 0) revert TokenNotERC20();

        pairInfo[pairId] = PairInfo({token0: _token0, token1: _token1});
        getPairId[_token0][_token1] = pairId;
        getPairId[_token1][_token0] = pairId;

        emit PairCreated(_token0, _token1, pairId);
    }

    function getPairInfo(uint256 _pairId) external view returns (uint256, address, address) {
        if (_pairId == 0 || _pairId > pairCount) revert PairDoesNotExist();
        PairInfo memory info = pairInfo[_pairId];
        return (_pairId, info.token0, info.token1);
    }

    function getBalance(uint256 _pairId, address _account) external view returns (uint256) {
        if (_pairId == 0 || _pairId > pairCount) revert PairDoesNotExist();
        return liquidityPairs[_pairId].balanceOf[_account];
    }

    function _update(uint256 _pairId, uint256 _reserve0, uint256 _reserve1) internal {
        liquidityPairs[_pairId].reserve0 = _reserve0;
        liquidityPairs[_pairId].reserve1 = _reserve1;
    }

    function addLiquidity(uint256 _pairId, uint256 _amount0, uint256 _amount1)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        if (_pairId == 0 || _pairId > pairCount) revert PairDoesNotExist();
        if (_amount0 == 0 || _amount1 == 0) revert AmountMustBeGreaterThanZero();

        LiquidityPair storage pair = liquidityPairs[_pairId];
        uint256 reserve0 = pair.reserve0;
        uint256 reserve1 = pair.reserve1;

        uint256 balance0After = reserve0 + _amount0;
        uint256 balance1After = reserve1 + _amount1;

        // Calculate shares
        if (pair.totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
            if (shares <= MINIMUM_LIQUIDITY) revert InitialLiquidityTooLow();
            _mint(_pairId, address(0), MINIMUM_LIQUIDITY);
            shares -= MINIMUM_LIQUIDITY;
        } else {
            shares = _min(
                (_amount0 * pair.totalSupply) / reserve0,
                (_amount1 * pair.totalSupply) / reserve1
            );
        }

        if (shares == 0) revert SharesAreZero();

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
        whenNotPaused
        returns (uint256 amount0, uint256 amount1)
    {
        if (_pairId == 0 || _pairId > pairCount) revert PairDoesNotExist();
        LiquidityPair storage pair = liquidityPairs[_pairId];
        if (_shares == 0) revert AmountMustBeGreaterThanZero();
        if (pair.balanceOf[msg.sender] < _shares) revert InsufficientShares();

        uint256 reserve0 = pair.reserve0;
        uint256 reserve1 = pair.reserve1;

        amount0 = (_shares * reserve0) / pair.totalSupply;
        amount1 = (_shares * reserve1) / pair.totalSupply;

        if (amount0 == 0 || amount1 == 0) revert AmountMustBeGreaterThanZero();

        // Update state variables
        _update(_pairId, reserve0 - amount0, reserve1 - amount1);
        _internalBurn(_pairId, msg.sender, _shares);

        // Transfer tokens to user
        pair.token0.safeTransfer(msg.sender, amount0);
        pair.token1.safeTransfer(msg.sender, amount1);

        emit LiquidityRemoved(_pairId, msg.sender, amount0, amount1, _shares);

        return (amount0, amount1);
    }

    function burn(uint256 _pairId, uint256 _amount) external onlyOwner {
        LiquidityPair storage pair = liquidityPairs[_pairId];
        _internalBurn(_pairId, msg.sender, _amount);
        emit LiquidityRemoved(_pairId, msg.sender, 0, 0, _amount); // Adjusted to pass zeros for amount0 and amount1 since it's a burn
    }

    function _internalBurn(uint256 _pairId, address _from, uint256 _amount) internal {
        LiquidityPair storage pair = liquidityPairs[_pairId];
        pair.balanceOf[_from] -= _amount;
        pair.totalSupply -= _amount;
    }

    function swap(
        uint256 _pairId,
        address _tokenIn,
        uint256 _amountIn,
        uint256 _minAmountOut // New parameter for slippage protection
    )
        external
        nonReentrant
        whenNotPaused
        returns (uint256 amountOut)
    {
        if (_pairId == 0 || _pairId > pairCount) revert PairDoesNotExist();
        LiquidityPair storage pair = liquidityPairs[_pairId];

        address tokenOut = (address(pair.token0) == _tokenIn) ? address(pair.token1) : address(pair.token0);

        (uint256 reserveIn, uint256 reserveOut) = (_tokenIn == address(pair.token0)) ? (pair.reserve0, pair.reserve1) : (pair.reserve1, pair.reserve0);
        
        // Scaling numerator to prevent precision loss
        uint256 amountInWithFee = (_amountIn * (10000 - swapFee)) * 1e18;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + amountInWithFee / 1e18;
        amountOut = numerator / denominator / 1e18;

        if (amountOut > reserveOut) revert InsufficientLiquidity();
        if (amountOut < _minAmountOut) revert SlippageTooHigh(); // Check for slippage

        // Update state variables
        _update(_pairId, (_tokenIn == address(pair.token0)) ? (reserveIn + _amountIn) : (reserveIn - _amountIn), (_tokenIn == address(pair.token0)) ? (reserveOut - amountOut) : (reserveOut + amountOut));

        // Transfer tokens
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        // Update accumulated fees
        accumulatedFees[_tokenIn] += (_amountIn * swapFee) / 10000;

        emit Swap(_pairId, msg.sender, _tokenIn, _amountIn, amountOut);
        emit FeePaid(_pairId, _tokenIn, (_amountIn * swapFee) / 10000);

        return amountOut;
    }

    function withdrawFees(address _token) external onlyOwner {
        uint256 feeAmount = accumulatedFees[_token];
        if (feeAmount == 0) revert NoFeesAvailable();

        accumulatedFees[_token] = 0;
        IERC20(_token).safeTransfer(msg.sender, feeAmount);
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
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

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function _mint(uint256 _pairId, address _to, uint256 _amount) internal {
        liquidityPairs[_pairId].balanceOf[_to] += _amount;
        liquidityPairs[_pairId].totalSupply += _amount;
    }

    // Emergency Functions

    function enableEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawEnabled = true;
        emit EmergencyWithdrawEnabled();
    }

    function emergencyWithdraw(uint256 _pairId) external nonReentrant {
        require(emergencyWithdrawEnabled, "Emergency withdrawal not enabled");
        LiquidityPair storage pair = liquidityPairs[_pairId];
        uint256 userShares = pair.balanceOf[msg.sender];
        require(userShares > 0, "No shares to withdraw");

        uint256 reserve0 = pair.reserve0;
        uint256 reserve1 = pair.reserve1;

        uint256 amount0 = (userShares * reserve0) / pair.totalSupply;
        uint256 amount1 = (userShares * reserve1) / pair.totalSupply;

        // Update state variables
        _update(_pairId, reserve0 - amount0, reserve1 - amount1);
        _internalBurn(_pairId, msg.sender, userShares);

        // Transfer tokens to user
        pair.token0.safeTransfer(msg.sender, amount0);
        pair.token1.safeTransfer(msg.sender, amount1);

        emit EmergencyWithdrawExecuted(msg.sender, _pairId, amount0, amount1);
    }
}

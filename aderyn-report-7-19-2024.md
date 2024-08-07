# Aderyn Analysis Report
## Conducted by Pavon Dunbar on 7-19-2024

This report was generated by [Aderyn](https://github.com/Cyfrin/aderyn), a static analysis tool built by [Cyfrin](https://cyfrin.io), a blockchain security company. This report is not a substitute for manual audit or security review. It should not be relied upon for any purpose other than to assist in the identification of potential security vulnerabilities.
# Table of Contents

- [Summary](#summary)
  - [Files Summary](#files-summary)
  - [Files Details](#files-details)
  - [Issue Summary](#issue-summary)
- [Low Issues](#low-issues)
  - [L-1: Centralization Risk for trusted owners](#l-1-centralization-risk-for-trusted-owners)
  - [L-2: Unsafe ERC20 Operations should not be used](#l-2-unsafe-erc20-operations-should-not-be-used)
  - [L-3: `public` functions not used internally could be marked `external`](#l-3-public-functions-not-used-internally-could-be-marked-external)
  - [L-4: Define and use `constant` variables instead of using literals](#l-4-define-and-use-constant-variables-instead-of-using-literals)
  - [L-5: Event is missing `indexed` fields](#l-5-event-is-missing-indexed-fields)
  - [L-6: Large literal values multiples of 10000 can be replaced with scientific notation](#l-6-large-literal-values-multiples-of-10000-can-be-replaced-with-scientific-notation)


# Summary

## Files Summary

| Key | Value |
| --- | --- |
| .sol Files | 1 |
| Total nSLOC | 313 |


## Files Details

| Filepath | nSLOC |
| --- | --- |
| src/AMM.sol | 313 |
| **Total** | **313** |


## Issue Summary

| Category | No. of Issues |
| --- | --- |
| High | 0 |
| Low | 6 |


# Low Issues

## L-1: Centralization Risk for trusted owners

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

<details><summary>6 Found Instances</summary>


- Found in src/AMM.sol [Line: 15](src/AMM.sol#L15)

        ```solidity
        contract AMM is ReentrancyGuard, Pausable, Ownable {
        ```

- Found in src/AMM.sol [Line: 106](src/AMM.sol#L106)

        ```solidity
            function setSwapFee(uint256 _swapFee) external onlyOwner {
        ```

- Found in src/AMM.sol [Line: 157](src/AMM.sol#L157)

        ```solidity
            function getAccumulatedFees() external view onlyOwner returns (uint256) {
        ```

- Found in src/AMM.sol [Line: 161](src/AMM.sol#L161)

        ```solidity
            function withdrawFees() external onlyOwner {
        ```

- Found in src/AMM.sol [Line: 399](src/AMM.sol#L399)

        ```solidity
            function pause() external onlyOwner {
        ```

- Found in src/AMM.sol [Line: 403](src/AMM.sol#L403)

        ```solidity
            function unpause() external onlyOwner {
        ```

</details>



## L-2: Unsafe ERC20 Operations should not be used

ERC20 functions may not behave as expected. For example: return values are not always meaningful. It is recommended to use OpenZeppelin's SafeERC20 library.

<details><summary>3 Found Instances</summary>


- Found in src/AMM.sol [Line: 114](src/AMM.sol#L114)

        ```solidity
                bool success = weth.transfer(msg.sender, msg.value);
        ```

- Found in src/AMM.sol [Line: 119](src/AMM.sol#L119)

        ```solidity
                require(weth.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        ```

- Found in src/AMM.sol [Line: 121](src/AMM.sol#L121)

        ```solidity
                payable(msg.sender).transfer(amount);
        ```

</details>



## L-3: `public` functions not used internally could be marked `external`

Instead of marking a function as `public`, consider marking it as `external` if it is not used internally.

<details><summary>6 Found Instances</summary>


- Found in src/AMM.sol [Line: 87](src/AMM.sol#L87)

        ```solidity
            function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        ```

- Found in src/AMM.sol [Line: 92](src/AMM.sol#L92)

        ```solidity
            function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        ```

- Found in src/AMM.sol [Line: 152](src/AMM.sol#L152)

        ```solidity
            function getBalance(uint256 _pairId, address _account) public view returns (uint256) {
        ```

- Found in src/AMM.sol [Line: 217](src/AMM.sol#L217)

        ```solidity
            function getReserve0(uint256 pairId) public view returns (uint256) {
        ```

- Found in src/AMM.sol [Line: 221](src/AMM.sol#L221)

        ```solidity
            function getReserve1(uint256 pairId) public view returns (uint256) {
        ```

- Found in src/AMM.sol [Line: 225](src/AMM.sol#L225)

        ```solidity
            function getTotalSupply(uint256 pairId) public view returns (uint256) {
        ```

</details>



## L-4: Define and use `constant` variables instead of using literals

If the same constant literal value is used multiple times, create a constant state variable and reference it throughout the contract.

<details><summary>4 Found Instances</summary>


- Found in src/AMM.sol [Line: 347](src/AMM.sol#L347)

        ```solidity
                    protocolFee: (_amountIn * swapFee) / 10000
        ```

- Found in src/AMM.sol [Line: 352](src/AMM.sol#L352)

        ```solidity
                uint256 numerator = swapInfo.amountIn * (10000 - swapInfo.protocolFee) * swapInfo.reserveOut;
        ```

- Found in src/AMM.sol [Line: 353](src/AMM.sol#L353)

        ```solidity
                uint256 denominator = (swapInfo.reserveIn * 10000) + (swapInfo.amountIn * (10000 - swapInfo.protocolFee));
        ```

</details>



## L-5: Event is missing `indexed` fields

Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.

<details><summary>7 Found Instances</summary>


- Found in src/AMM.sol [Line: 68](src/AMM.sol#L68)

        ```solidity
            event PairCreated(address indexed token0, address indexed token1, uint256 pairId);
        ```

- Found in src/AMM.sol [Line: 69](src/AMM.sol#L69)

        ```solidity
            event LiquidityAdded(uint256 indexed pairId, address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
        ```

- Found in src/AMM.sol [Line: 70](src/AMM.sol#L70)

        ```solidity
            event LiquidityRemoved(uint256 indexed pairId, address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
        ```

- Found in src/AMM.sol [Line: 71](src/AMM.sol#L71)

        ```solidity
            event Swap(uint256 indexed pairId, address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
        ```

- Found in src/AMM.sol [Line: 72](src/AMM.sol#L72)

        ```solidity
            event FeesWithdrawn(address indexed owner, uint256 amount);
        ```

- Found in src/AMM.sol [Line: 73](src/AMM.sol#L73)

        ```solidity
            event SwapFeeUpdated(uint256 newFee);
        ```

- Found in src/AMM.sol [Line: 74](src/AMM.sol#L74)

        ```solidity
            event Approval(address indexed owner, address indexed spender, uint256 value);
        ```

</details>



## L-6: Large literal values multiples of 10000 can be replaced with scientific notation

Use `e` notation, for example: `1e18`, instead of its full numeric value.

<details><summary>4 Found Instances</summary>


- Found in src/AMM.sol [Line: 347](src/AMM.sol#L347)

        ```solidity
                    protocolFee: (_amountIn * swapFee) / 10000
        ```

- Found in src/AMM.sol [Line: 352](src/AMM.sol#L352)

        ```solidity
                uint256 numerator = swapInfo.amountIn * (10000 - swapInfo.protocolFee) * swapInfo.reserveOut;
        ```

- Found in src/AMM.sol [Line: 353](src/AMM.sol#L353)

        ```solidity
                uint256 denominator = (swapInfo.reserveIn * 10000) + (swapInfo.amountIn * (10000 - swapInfo.protocolFee));
        ```

</details>

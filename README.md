# Update 7-19-2024

Several tests were ran and issues were resolved to satisfaction.

**Mythril** analysis passed. No issues detected.

<img width="673" alt="Screenshot 2024-07-19 at 3 07 19 PM" src="https://github.com/user-attachments/assets/75a74c5d-35e2-4ccb-a656-d11461867b27">

**Slither** analysis passed with no medium or high severity issues.

<img width="788" alt="Screenshot 2024-07-19 at 3 08 17 PM" src="https://github.com/user-attachments/assets/8b4edd56-7e47-4e94-829f-0f737d1185f7">

**Aderyn** tests had low issues, nothing of major concern. Check out the ***aderyn-report-7-19-2024.md*** file above for more information.

# Update 7-15-2024

I've performed fuzzing test analysis on the smart contract by creating Fuzz.sol and uploaded it here to Github.  

The program I used is Echidna, a popular smart contract fuzzing application that uses invariants to break functions in your smart contract.

The command to run Echidna is 
```
echidna --workers 5 ./Fuzz.sol --test-mode assertion --rpc-url https://sepolia.infura.io/v3/[YOUR-PROJECT-ID]
```

The results of the tests are below:

<img width="1512" alt="Screenshot 2024-07-15 at 3 36 32 PM" src="https://github.com/user-attachments/assets/a5f7ec86-ce46-499c-9e36-596e673a5f88">


**PLEASE MAKE SURE FUZZ.SOL IS IN THE PROJECT ROOT DIRECTORY, NOT THE /SRC OR /TEST DIRECTORY IF USING FOUNDRY.**



# Automated Market Maker (AMM) Smart Contract

This contract implements an Automated Market Maker (AMM) for two ERC20 tokens. Below is a brief explanation of what this contract does and its security features.

A sample deployment of this smart contract and proof of its verification can be found [on the Sepolia testnet](https://sepolia.etherscan.io/address/0x1d826a7f7846750b6d6d340f57616741b3b2eb36).


## Functionality:

1. Users can wrap native tokens to wrapped tokens at a 1:1 ratio
2. Users can unwrap wrapped tokens back to native tokens at a 1:1 ratio
3. Allows users to swap between two tokens.
4. Enables users to add liquidity by depositing both tokens.
5. Allows liquidity providers to remove their liquidity and receive tokens back.

## Security Features:

### 1. ReentrancyGuard:
- Prevents reentrant calls to critical functions like `swap`, `addLiquidity`, and `removeLiquidity`.
- Protects against potential reentrancy attacks.

### 2. Ownable:
- Restricts certain functions (like `pause` and `unpause`) to the contract owner.
- Provides basic access control.

### 3. Pausable:
- Allows the owner to pause and unpause contract functionality.
- Useful for emergency situations or upgrades.

### 4. Custom Lock Mechanism:
- The `lock` modifier prevents concurrent execution of critical functions.
- Adds an extra layer of protection against potential exploits.

### 5. Input Validation:
- Checks for valid token addresses in the constructor.
- Ensures input amounts are greater than zero in various functions.

### 6. Minimum Liquidity:
- Implements a minimum liquidity mechanism to prevent division by zero errors.

### 7. Immutable State Variables:
- `token0` and `token1` are declared as `immutable`, preventing accidental modifications.

### 8. Events:
- Emits events for important actions (`LiquidityAdded`, `LiquidityRemoved`, `Swap`).
- Allows for off-chain monitoring and tracking of contract activities.

### 9. Constant Values:
- Uses `constant` for fixed values like `MINIMUM_LIQUIDITY`.

### 10. Internal Functions:
- Uses `private` functions for internal operations, limiting external access.

### 11. Checks-Effects-Interactions Pattern:
- Generally follows this pattern in functions like `swap` and `addLiquidity`.

**Note:** While these security features provide a good foundation, it's important to note that no smart contract is 100% secure, and additional measures like formal verification and thorough auditing are recommended for production use.


# START
**This repo's instructions are assuming you are using Foundry. You are more than welome to use another IDE (ex Hardhat), but the instructions may be different.**
```
forge init AMM
```

This will create a directory called AMM with all the necessary files and subdirectories.

Next, create an .env file in the AMM root directory

```
nano .env
```

Modify the .env file and provide your **private key** and your etherscan, polygonscan, etc. **api key**
```
PRIVATE_KEY=[YOUR-PRIVATE-KEY-GOES-HERE]
ETHERSCAN_API_KEY=[YOUR-ETHERSCAN-API-KEY-GOES-HERE]
```

Next, clone the OpenZeppelin library by running this command in the root directory.
```
forge install --no-commit OpenZeppelin/openzeppelin-contracts
```

Manually do the following after installing OpenZeppelin contracts:
```
1. Copy the foundry.toml file and place it in the AMM root directory
2. Copy the AMM.sol file and place it in the /src directory
3. Copy the AMM.t.sol file and place it in the /test directory
4. Copy the AMM.s.sol file and place it in the /script directory
```

# Run Tests
```
forge test
```

If all test pass, run the deploy script **from the AMM root directory** to deploy to the blockchain of your choosing. Please make sure you have an API key for the blockchain's explorer of your choice so it passes the verification part.

```
WETH_ADDRESS=[WETH-CONTRACT-ADDRESS] forge script script/AMM.s.sol:DeployAMM --rpc-url [YOUR-BLOCKCHAIN-RPC-URL] --broadcast --verify -vvvv
```

NOTE: Pass the WETH contract address if you are using WETH as your wrapped token. If you are passing a different token contract address (WMATIC, etc), pass that value instead.

Your contract should be successfully deployed and verified on the blockchain. **Make note of the contract addresses.**

If you decide to commit this codebase to your Github repo, **DO NOT COPY OVER YOUR .ENV FILE CREDENTIALS!!!**

Great job! Now, it is time to interact with the newly deployed contract.

# INTERACTION

Run this command **from the AMM root directory** to output a list of the functions:
```
cat out/AMM.sol/AMM.json | jq -r '.abi | map(select(.type == "function")) | .[] | "\(.name)(\(.inputs | map(.type + " " + .name) | join(", ")))"'
```

If done correctly, a list fo the function should output to the console along with their arguments and data types like below:

```
LP_FEE_SHARE()
MINIMUM_LIQUIDITY()
accumulatedFees()
addLiquidity(uint256 _pairId, uint256 _amount0, uint256 _amount1)
createPair(address _token0, address _token1)
decreaseAllowance(address spender, uint256 subtractedValue)
getAccumulatedFees()
getBalance(uint256 _pairId, address _account)
getPairId(address , address )
getPairInfo(uint256 _pairId)
getReserve0(uint256 pairId)
getReserve1(uint256 pairId)
getTotalSupply(uint256 pairId)
getUnlocked()
increaseAllowance(address spender, uint256 addedValue)
liquidityPairs(uint256 )
owner()
pairCount()
pairInfo(uint256 )
pause()
paused()
removeLiquidity(uint256 _pairId, uint256 _shares)
renounceOwnership()
setSwapFee(uint256 _swapFee)
swap(uint256 _pairId, address _tokenIn, uint256 _amountIn, uint256 _minAmountOut)
swapFee()
transferOwnership(address newOwner)
unpause()
unwrap(uint256 amount)
weth()
wethAddress()
withdrawFees()
wrap()
```

# CREATE ENVIRONMENTAL VARIABLES
Run these commands to set environmental variables **during this session only.**
```
export PRIV=[YOUR-PRIVATE-KEY]
export RPC=[YOUR-RPC-URL]
export ADD=[YOUR-AMM-CONTRACT-ADDRESS]
export T0=[CONTRACT-ADDRESS-OF-TOKEN-0]
export T1=[CONTRACT-ADDRESS-OF-TOKEN-1]
EXPORT WETH=[WRAPPED-ETHER-CONTRACT-ADDRESS]
  - If you are using a different wrapped token (ex: WMATIC), use that key and pass the value instead.
```

## wrap() A NATIVE TOKEN TO CONVERT IT TO A WRAPPED TOKEN AT A 1:1 RATIO
```
cast send $ADD "wrap()" --value [VALUE-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

## createPair() BETWEEN 2 TOKENS TO BEGIN THE LIQUIDITY POOL:
```
cast send $ADD "createPair(address,address)" $T0 $T1 --rpc-url $RPC --private-key $PRIV
```

## GET THE pairId() FOR YOUR CREATED PAIR

The PairID plays an important role because it issues an ID number that is associated with your liquidity pair and is stored in a mapping array on the blockchain.

Run the code below to get the PairID. **PLEASE NOTATE THIS ID NUMBER** because you will need it to **add liquidity to the pool.**
```
cast call $ADD "getPairId(address,address)(uint256)" $T0 $T1 --rpc-url $RPC
```

## approve() THE AMM SWAP CONTRACT TO SPEND TOKENS ON YOUR BEHALF

For Token 0
```
cast send $T0 "approve(address,uint256)" $ADD [AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

For Token 1
```
cast send $T1 "approve(address,uint256)" $ADD [AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

**PLEASE NOTE:** The approval amounts must be specified in wei since Foundry cast does not support decimals or floating point numbers. To convert your decimals and numbers to Wei format, [Go Here](https://eth-converter.com)

Also, if you are creating a pair that has a token with 6 decimal places (ex: USDC) and a token that has 18 decimal places, you must use the appropriate zeros in the conversion.

EX: 20 USDC would be 20000000 (20 with 6 zeros) and 20 AGC would be 20000000000000000000 (20 with 18 zeros). This would create a pool of 20 USDC and 20 AGC making the ratio 1 USDC = 1 AGC.

## unwrap() A WRAPPED TOKEN TO CONVERT IT BACK TO A NATIVE TOKEN AT A 1:1 RATIO
```
// Approve the contract to spend your wrapped tokens
cast send $WETH "approve(address,uint256)" $ADD [AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV

// Convert the Wrapped Tokens back to the Native Tokens at a 1:1 ratio
cast send $ADD "unwrap(uint256)" [AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV 
```

## addLiquidity() TO THE LIQUIDITY PAIR:
```
cast send $ADD "addLiquidity(uint256,uint256,uint256)" [PAIR-ID-FROM-ABOVE-STEP] [TOKEN-0-AMOUNT-IN-WEI] [TOKEN-1-AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

The above command will add funds to the liquidity pair with Token 0 = Token 1. For example, if you wanted to make 1 WETH equal to 5000 AGC with a Pair ID of 20, you would run the command like this:

```
cast send $ADD "addLiquidity(uint256,uint256,uint256)" 20 1000000000000000000 5000000000000000000000 --rpc-url $RPC --private-key $PRIV
```

# THE SWAP FUNCTION

The swap function takes in 4 arguments:
- The Pair ID
- The Token Contract Address
- The Amount (in wei)
- The Slippage Tolerance (**NEW as of 7-25-2024**)

Users can now set their slippage tolerance to any number relative to **basis points**. However, the maximum is 1000 basis point, or 10% slippage.

A slippage tolerance of 0 will do the following:
- No slippage protection: The swap will execute regardless of how unfavorable the exchange rate becomes. This means you're accepting any output amount, no matter how small.
- Increased vulnerability to front-running: Malicious actors could potentially manipulate the price just before your transaction is processed, resulting in you receiving a much smaller amount of tokens than expected.
- Higher risk of significant losses: In volatile markets or low liquidity situations, you might receive far fewer tokens than anticipated.
- Always successful swaps: Your swap transactions will almost always succeed (barring other issues), as there's no minimum threshold for the output amount.
- Potential for zero output: In extreme cases, it's theoretically possible to receive 0 tokens in return, though this is unlikely in most practical scenarios.

A slippage tolerance of 1000 will do the following:
- The swap function will only execute successfully if the calculated amountOut is greater than or equal to 1000. This acts as a slippage protection mechanism.
- If the calculated amountOut is less than 1000, the transaction will revert with the error message "Insufficient output amount".
- Setting a high _minAmountOut value like 1000 could potentially cause many swap attempts to fail, especially if the liquidity in the pool is low, the input amount is small, or the price difference between the two tokens is large
- It effectively sets a minimum price for the swap. For example, if you're swapping token A for token B, setting _minAmountOut to 1000 means you're saying "I want at least 1000 of token B for my token A, otherwise don't do the swap".
- This high value could protect you from large price movements or slippage, but it also increases the chance that your swap will not execute at all.

**TO BE SAFE AND HAVE SUCCESSFUL SWAPS, SET SLIPPAGE FROM 25 (0.25%) - 100 (1%)**

## PERFORM THE swap() FROM TOKEN 0 TO TOKEN 1
```
cast send $ADD "swap(uint256,address,uint256,uint256)" [PAIR ID] $T0 [AMOUNT-IN-WEI] [SLIPPAGE TOLERANCE] --rpc-url $RPC --private-key $PRIV
```

## PERFORM THE swap() FROM TOKEN 1 TO TOKEN 0
```
cast send $ADD "swap(uint256,address,uint256,uint256)" [PAIR ID] $T1 [AMOUNT-IN-WEI] [SLIPPAGE TOLERANCE] --rpc-url $RPC --private-key $PRIV
```

## removeLiquidity() FROM THE POOL:
```
/// RETRIEVE THE BALANCE IN THE POOL
cast call $ADD "getBalance(uint256,address)(uint256)" [PAIR-ID] [PAIR-CREATOR-WALLET-ADDRESS] --rpc-url $RPC

/// REMOVE ALL OR PART OF THE LIQUIDITY IN THE POOL
cast send $ADD "removeLiquidity(uint256,uint256)" [PAIR-ID] [AMOUNT] --rpc-url $RPC --private-key $PRIV
```

# READ FUNCTIONS (These DO NOT modify the state of the blockchain so no gas will be charged to call these functions)

## Get information on the **liquidityPairs()**.
```
cast call $ADD "liquidityPairs(uint256)(address,address,uint256,uint256,uint256)" [PAIR-ID] --rpc-url $RPC
```

This will output the following:
```
Token0 Contract Address
Token0 Reserve Amount (in wei)
Token1 Contract Address 
Token1 Reserve Amount (in wei)
Total Amount in Pool (in wei)
```

## Get the **pairID()** for a liquidity pair:
```
cast call $ADD "getPairId(address,address)(uint256)" $T1 $T2 --rpc-url $RPC
```

## Get the **pairCount()** (total number of liquidity pairs) in the swap altogether:
```
cast call $ADD "pairCount()(uint256)" --rpc-url $RPC
```

## Get The **pairInfo() (also as getPairInfo()):**

**This function is better suited with the ***liquidityPairs()*** function above. Better to use that one since it outputs more relevant information.**

## Get the **weth()** contract address (mainnet):
```
cast call $ADD "weth()(address)" --rpc-url $RPC
```

## Get the **wethAddress()** contract address (testnet):
```
cast call $ADD "wethAddress()(address)" --rpc-url $RPC
```

## Get the **owner()** of the contract
```
cast call $ADD "owner()(address)" --rpc-url $RPC
```

## **getBalance()** of the pool:
```
cast call $ADD "getBalance(uint256,address)(uint256)" [PAIR-ID] [PAIR-CREATOR-WALLET-ADDRESS] --rpc-url $RPC
```
The output would be the amount in wei that the liquidity pair creator can withdraw from the pool.

## **pause()** the swap:

This function **can only be called by the owner of the contract** (the entity who deployed the contract on the blockchain).

Calling this function will pause the contract so no tansactions can be done on the contract.
```
cast send $ADD "pause()" --rpc-url $RPC --private-key $PRIV
```

Check to see if the swap is **paused()**:

Calling this function will let you know if the swap is paused (true) or not (false).

The output will be a ***boolean*** value.
```
cast call $ADD "paused()(bool)" --rpc-url $RPC
```

## **unpause()** the swap:

This function will unpause the swap so normal transactions can resume.

This function **can only be called by the owner (deployer) of the contract**
```
cast send $ADD "unpause()" --rpc-url $RPC --private-key $PRIV
```

## **transferOwnership()** of the swap to a new owner:
```
cast send $ADD "transferOwnership(address)" [NEW-OWNER-WALLET-ADDRESS] --rpc-url $RPC --private-key $PRIV
```

## ***renounceOwnership()** of the swap:

**NOTE: THIS IS A DANGEROUS FUNCTION CALL THAT RELINQUISHES OWNERSHIP OF THE SWAP IN ITS ENTIRETY. THIS FUNCTION IS IRREVERSIBLE AND NO ONE WALLET ADDRESS CAN CALL FUNCTIONS THAT ARE
PRIVILEGED. USE THIS FUNCTION AT YOUR OWN RISK!!**
```
cast send $ADD "renounceOwnership()" --rpc-url $RPC --private-key $PRIV
```

This function sets the owner of the contract to 0x0000000000000000000000000000000000000000. The pause(), unpause(), transferOwnership(), and renounceOwnership() functions will no longer be valid and usable. 

## GET THE LP_FEE_SHARE() AMOUNT IN PERCENTAGE
```
cast call $ADD "LP_FEE_SHARE()(uint256)" --rpc-url $RPC
```

The output should be a number. This number is a percentage. For example, if the ouput number is 85, that means the liquidity pool provider will get 85% of the swap fee for a swap done against his or her liquidity pool.

## getAccumulatedFees() TO SEE HOW MUCH TOTAL THE PROTOCOL HAS EARNED FROM SWAP FEES
```
cast call $ADD "getAccumulatedFees()(uint256)" --rpc-url $RPC --private-key $PRIV
```

## GET THE swapFee() AMOUNT THE PROTOCOL IS CHARGING TO DO SWAPS
```
cast call $ADD "swapFee()(uint256)" --rpc-url $RPC
```

The number that is outputted would be represented in a percentage amount that is designated in DOLLARS and CENTS. For example, an output of 30 would be equivalent to 0.3%.

That means for every $100 worth of tokens an individual swaps, they would pay $0.30 in swap fees.

## GET THE totalSupply() OF THE POOL
```
cast call $ADD "getTotalSupply(uint256)(uint256)" [PAIR-ID] --rpc-url $RPC
```

## setSwapFee() 

This function **can only be called by the owner of the contract**
```
cast send $ADD "setSwapFee(uint256)(uint256)" [AMOUNT] --rpc-url $RPC --private-key $PRIV
```
For the [AMOUNT] field, specify a value. For example, 10 would equal 0.1%, 30 would equal 0.3%. 

For example, if value is set to 10, that means that for every $100 a person exchanges, they will pay a fee of $0.10. 

## GET THE allowance() OF A WALLET

This command will enable someone to se the spending limit approved and allocated to a wallet address.
```
cast call $T1 "allowance(address,address)(uint256)" [WALLET ADDRESS] $ADD --rpc-url $RPC
```

## GET balanceOf() A WALLET ADDRESS FOR A PARTICULAR TOKEN (in wei)
```
cast call $T1 "balanceOf(address)(uint256)" [WALLET ADDRESS] --rpc-url $RPC
``` 




# TODOS:

1. Incorporate Impermnent Loss at 3%
2. Incorporate Max Leverage at 5%
3. Incprporate Swap Staking (not validator staking) for 30 days
4. Incorporate Vesting for 1 year
5. Incorporate a withdrawal cooldown of 48 hours
6. Enhance security of swap to make it more robust

# QUESTIONS

Please reach out to me on Slack if you have any questions with the swap or if you are having issues. Or, you can open an issue here on Github.


















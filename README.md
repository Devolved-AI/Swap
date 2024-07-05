# Automated Market Maker (AMM) Smart Contract

This contract implements an Automated Market Maker (AMM) for two ERC20 tokens. Below is a brief explanation of what this contract does and its security features.

A sample deployment of this smart contract and proof of its verification can be found [on the Sepolia testnet (https://sepolia.etherscan.io/address/0x1d826a7f7846750b6d6d340f57616741b3b2eb36).


## Functionality:

1. Allows users to swap between two tokens.
2. Enables users to add liquidity by depositing both tokens.
3. Allows liquidity providers to remove their liquidity and receive tokens back.

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
forge script script/AMM.s.sol:DeployAMM --rpc-url [YOUR-BLOCKCHAIN-RPC-URL] --broadcast --verify -vvvv
```

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
addLiquidity(uint256 _amount0, uint256 _amount1)
balanceOf(address )
owner()
pause()
paused()
removeLiquidity(uint256 _shares)
renounceOwnership()
reserve0()
reserve1()
swap(address _tokenIn, uint256 _amountIn)
token0()
token1()
totalSupply()
transferOwnership(address newOwner)
unpause()
```


# CREATE ENVIRONMENTAL VARIABLES
Run these commands to set environmental variables **during this session only.**
```
export PRIV=[YOUR-PRIVATE-KEY]
export RPC=[YOUR-RPC-URL]
export ADD=[YOUR-AMM-CONTRACT-ADDRESS]
export T1=[CONTRACT-ADDRESS-OF-TOKEN-1]
export T2=[CONTRACT-ADDRESS-OF-TOKEN-2]
```

# CREATE TOKEN PAIR
```
cast send $ADD "initialize(address,address)" $T1 $2 --rpc-url $RPC --private-key $PRIV
```

# APPROVE THE AMM SWAP CONTRACT TO SPEND TOKENS ON YOUR BEHALF

For Token 1
```
cast send $T1 "approve(address,uint256)" $ADD [AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

For Token 2
```
cast send $T2 "approve(address,uint256)" $ADD [AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

**PLEASE NOTE:** The approval amounts must be specified in wei since Foundry cast does not support decimals or floating point numbers. To convert your decimals and numbers to Wei format, [Go Here](https://eth-converter.com)

# ADD LIQUIDITY
```
cast send $ADD "addLiquidity(uint256,uint256)" [TOKEN-1-AMOUNT-IN-WEI] [TOKEN-2-AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

The above command will initialize the liquidity pair with Token 1 = Token 2. For example, if you wanted to make 1 WETH equal to 5000 AGC, you would run the command like this:

```
cast send $ADD "addLiquidity(uint256,uint256)" 1000000000000000000 5000000000000000000000 --rpc-url $RPC --private-key $PRIV
```

# PERFORM THE SWAP FROM TOKEN 1 TO TOKEN 2
```
cast send $ADD "swap(address,uint256)" $T1 [AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

# PERFORM THE SWAP FROM TOKEN 2 TO TOKEN 1
```
cast send $ADD "swap(address,uint256)" $T2 [AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

# REMOVE LIQUIDITY
```
CURRENTLY TESTING. WILL UPDATE SOON.
```

# READ FUNCTIONS (These DO NOT modify the state of the blockchain so no gas will be charged to call these functions)

Check to see if liquidity pair is intialized:
```
cast call $ADD "initialized()(uint256)" --rpc-url $RPC
```
The output of the above will be a **boolean** value. 0 = FALSE (no liquidity pair was initialized) or 1 = TRUE (liquidity pair was initalized)

Get total supply of pool:
```
cast call $ADD "totalSupply()(uint256)" --rpc-url $RPC
```

Get Token 1 contract address:
```
cast call $T1 "token0()(address)" --rpc-url $RPC
```

Get Token 2 contract address:
```
cast call $T2 "token1()(address)" --rpc-url $RPC
```

Get Token 1 pool reserves:
```
cast call $ADD "reserve0()(uint256)" --rpc-url $RPC
```

Get Token 2 pool reserves:
```
cast call $ADD "reserve1()(uint256)" --rpc-url $RPC
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


















<<<<<<< HEAD
# Automated Market Maker (AMM) Smart Contract

This contract implements an Automated Market Maker (AMM) for two ERC20 tokens. Below is a brief explanation of what this contract does and its security features.

A sample deployment of this smart contract and proof of its verification can be found [on the Sepolia testnet](https://sepolia.etherscan.io/address/0x1d826a7f7846750b6d6d340f57616741b3b2eb36).


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
addLiquidity(uint256 _pairId, uint256 _amount0, uint256 _amount1)
createPair(address _token0, address _token1)
getBalance(uint256 _pairId, address _account)
getPairId(address , address )
getPairInfo(uint256 _pairId)
liquidityPairs(uint256 )
pairCount()
pairInfo(uint256 )
pause()
paused()
removeLiquidity(uint256 _pairId, uint256 _shares)
swap(uint256 _pairId, address _tokenIn, uint256 _amountIn)
unpause()
```

# CREATE ENVIRONMENTAL VARIABLES
Run these commands to set environmental variables **during this session only.**
```
export PRIV=[YOUR-PRIVATE-KEY]
export RPC=[YOUR-RPC-URL]
export ADD=[YOUR-AMM-CONTRACT-ADDRESS]
export T0=[CONTRACT-ADDRESS-OF-TOKEN-0]
export T1=[CONTRACT-ADDRESS-OF-TOKEN-1]
```

# createPair() BETWEEN 2 TOKENS TO BEGIN THE LIQUIDITY POOL:
```
cast send $ADD "createPair(address,address)" $T0 $T1 --rpc-url $RPC --private-key $PRIV
```

# GET THE pairId() FOR YOUR CREATED PAIR

The PairID plays an important role because it issues an ID number that is associated with your liquidity pair and is stored in a mapping array on the blockchain.

Run the code below to get the PairID. **PLEASE NOTATE THIS ID NUMBER** because you will need it to **add liquidity to the pool.**
```
cast call $ADD "getPairId(address,address)(uint256)" $T0 $T1 --rpc-url $RPC
```

# approve() THE AMM SWAP CONTRACT TO SPEND TOKENS ON YOUR BEHALF

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

# addLiquidity() TO THE LIQUIDITY PAIR:
```
cast send $ADD "addLiquidity(uint256,uint256,uint256)" [PAIR-ID-FROM-ABOVE-STEP] [TOKEN-0-AMOUNT-IN-WEI] [TOKEN-1-AMOUNT-IN-WEI] --rpc-url $RPC --private-key $PRIV
```

The above command will add funds to the liquidity pair with Token 0 = Token 1. For example, if you wanted to make 1 WETH equal to 5000 AGC with a Pair ID of 20, you would run the command like this:

```
cast send $ADD "addLiquidity(uint256,uint256,uint256)" 20 1000000000000000000 5000000000000000000000 --rpc-url $RPC --private-key $PRIV
```

# PERFORM THE swap() FROM TOKEN 0 TO TOKEN 1
```
cast send $ADD "swap(uint256,address,uint256)" [PAIR-ID] --rpc-url $RPC $T0 [AMOUNT-IN-WEI] --private-key $PRIV
```

# PERFORM THE swap() FROM TOKEN 1 TO TOKEN 0
```
cast send $ADD "swap(uint256,address,uint256)" [PAIR-ID] --rpc-url $RPC $T1 [AMOUNT-IN-WEI] --private-key $PRIV
```

# removeLiquidity() FROM THE POOL:
```
/// RETRIEVE THE BALANCE IN THE POOL
cast call $ADD "getBalance(uint256,address)(uint256)" [PAIR-ID] [PAIR-CREATOR-WALLET-ADDRESS] --rpc-url $RPC

/// REMOVE ALL OR PART OF THE LIQUIDITY IN THE POOL
cast send $ADD "removeLiquidity(uint256,uint256)" [PAIR-ID] [AMOUNT] --rpc-url $RPC --private-key $PRIV
```

# READ FUNCTIONS (These DO NOT modify the state of the blockchain so no gas will be charged to call these functions)

Get information on the **liquidityPairs()**.
```
cast call $ADD "liquidityPairs(uint256)(address,address,uint256,uint256,uint256)" [PAIR-ID] --rpc-url $RPC
```

This will output the following:
```
Token0 Contract Address
Token0 Reserve Amount (in wei)
Token1 Contract Address 
Token1 Reserve Amount (in wei)
Total Amount in Pool (in ETH)
```

Get the **pairID()** for a liquidity pair:
```
cast call $ADD "getPairId(address,address)(uint256)" $T1 $T2 --rpc-url $RPC
```

Get the **pairCount()** (total number of liquidity pairs) in the swap altogether:
```
cast call $ADD "pairCount()(uint256)" --rpc-url $RPC
```

Get The Pair information:

**This function is better suited with the ***liquidityPairs()*** function above. Better to use that one since it outputs more relevant information.**


**getBalance()** of the pool:
```
cast call $ADD "getBalance(uint256,address)(uint256)" [PAIR-ID] [PAIR-CREATOR-WALLET-ADDRESS] --rpc-url $RPC
```
The output would be the amount in wei that the liquidity pair creator can withdraw from the pool.

**pause()** the swap:

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

**unpause()** the swap:

This function will unpause the swap so normal transactions can resume.

This function **can only be called by the owner (deployer) of the contract**
```
cast send $ADD "unpause()" --rpc-url $RPC --private-key $PRIV
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

















=======
# Getting Started with Create React App

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page will reload when you make changes.\
You may also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can't go back!**

If you aren't satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you're on your own.

You don't have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn't feel obligated to use this feature. However we understand that this tool wouldn't be useful if you couldn't customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

### Code Splitting

This section has moved here: [https://facebook.github.io/create-react-app/docs/code-splitting](https://facebook.github.io/create-react-app/docs/code-splitting)

### Analyzing the Bundle Size

This section has moved here: [https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size](https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size)

### Making a Progressive Web App

This section has moved here: [https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app](https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app)

### Advanced Configuration

This section has moved here: [https://facebook.github.io/create-react-app/docs/advanced-configuration](https://facebook.github.io/create-react-app/docs/advanced-configuration)

### Deployment

This section has moved here: [https://facebook.github.io/create-react-app/docs/deployment](https://facebook.github.io/create-react-app/docs/deployment)

### `npm run build` fails to minify

This section has moved here: [https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify](https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify)
>>>>>>> 0b48836 (Initial Frontend Swap Commit)

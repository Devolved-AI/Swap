# Simple Swap

A Command Line Crypto Exchange Script

## Description

This script allows you to perform various cryptocurrency actions such as swapping tokens, depositing tokens, adding liquidity, and performing cross-chain swaps using the command line.

## Prerequisites

- Node.js (v12 or higher)
- npm (Node Package Manager)
- Ethers.js (install using `npm install ethers`)
- An Infura project ID (for connecting to the Ethereum network)

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/DevolvedAI/Swap
    cd Swap
    ```

2. Install the required dependencies:
    ```sh
    npm install ethers
    ```

## Set Environmental Variables

It is recommended you set environmental variables for the following:

- **RPC** (this would be the RPC URL of the blockchain you are connected to)
- **T1** (This is the token contract of the native token (ex: MATIC on the Polygon network, ETH on the Ethereum network))
- **T2** (This would be the wrapped token contract address when you call the *deposit()* function)
- **FROM** (this is the wallet address the funds are coming FROM)
- **TO** (this is the wallet address the funds are going TO)
- **PRIV** (This is the Private Key corresponding to the FROM wallet address. This address needs to sign (approve) the transaction)

## Usage

To use the script, run the following command in your terminal:

**DEPOSIT (Convert Native Token To Wrapped Token at 1:1 ratio)**
```
node swap.js $RPC $T1 $T2 <amount> deposit $PRIV $FROM $TO <gasFee>
    - Set an amount (in ethers, not wei) for <amount> (ex: 100)
    - Set the gas fee (in gwei) for <gasFee> (ex: 10)
```

**LIQUIDITY (Creates Liquidity Pair and Sets Initial Liquidity Pool)**
```
WORK IN PROGRESS. CURRENTLY TESTING.
```

**SWAP (Performs swap between two tokens on same blockchain)**
```
WORK IN PROGRESS. CURRENTLY TESTING.
```

**CROSS CHAIN (Performs swap between two tokens on different blockchains)**
```
WORK IN PROGRESS. CURRENTLY TESTING. THIS COMMAND USES THE BRIDGE CONTRACT WHICH HAS BEEN TESTED IN FOUNDRY AND DEPLOYED ON POLYGON'S AMOY TESTNET.
CONTRACT ADDRESS IS 0x9AfBc22eb8F3101d9D9968D89644380FDCaF3565
```





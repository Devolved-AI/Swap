# Simple Swap

A Command Line Crypto Exchange Script

# Flowchart

[![](https://mermaid.ink/img/pako:eNptU9tuGjEQ_ZWRHyuSD0BqJWAhQQoSLYn6sJsHZz2wbmzP1hcIAv69sw4LVO3b2nN8LjOzB1GTQjEUGy_bBp6Lyo3Kl4D-Fe7uvh3nLqKXdQyw07E5wrhcSO3uf4XXyo0zYiKNCVCTtdKpcITJYbRYwMpKH2FCLnavT5Wr3CTDVzvZQqR3dIwtyif9O2ml4x6WRIZJi4x6aZWMCB7ZyBbDAFqva-zYe8QKnQJKsU3xQje6yoyUAtNzH2FaTjx2jP_ojTJ86WmrFV6YppWb5sJCuwhPy1uJz0KBLQV91S6u2j_Q0hZv5WflOHnX8Txn-EU3p7ihn1Vulgs_udvKyx0Hp5Z81OSkgdBIj0DrWzuz_zXsLz88zW5ALkTJYZhQpTrCmrxNRh7hofyAL7CHr_DOvh7O6XjsVju8bXw_8e8JPYd6LKcfdSPdBmHu1sRvH8_x-6H1wSCktjX7AWCs73mHrlT9euXtAooNeihwpjuXkWoyrDwv8820prAPES0LzT83jyzPQL5pk5vMtGIgLPuWWvFCHyoHUAnmtFiJIX8qXMtkYiUqd2KoTJFWe1eLYfQJB8JT2jRiuJYm8CnljhZa8o9hz7enPyeXHGA?type=png)](https://mermaid.live/edit#pako:eNptU9tuGjEQ_ZWRHyuSD0BqJWAhQQoSLYn6sJsHZz2wbmzP1hcIAv69sw4LVO3b2nN8LjOzB1GTQjEUGy_bBp6Lyo3Kl4D-Fe7uvh3nLqKXdQyw07E5wrhcSO3uf4XXyo0zYiKNCVCTtdKpcITJYbRYwMpKH2FCLnavT5Wr3CTDVzvZQqR3dIwtyif9O2ml4x6WRIZJi4x6aZWMCB7ZyBbDAFqva-zYe8QKnQJKsU3xQje6yoyUAtNzH2FaTjx2jP_ojTJ86WmrFV6YppWb5sJCuwhPy1uJz0KBLQV91S6u2j_Q0hZv5WflOHnX8Txn-EU3p7ihn1Vulgs_udvKyx0Hp5Z81OSkgdBIj0DrWzuz_zXsLz88zW5ALkTJYZhQpTrCmrxNRh7hofyAL7CHr_DOvh7O6XjsVju8bXw_8e8JPYd6LKcfdSPdBmHu1sRvH8_x-6H1wSCktjX7AWCs73mHrlT9euXtAooNeihwpjuXkWoyrDwv8820prAPES0LzT83jyzPQL5pk5vMtGIgLPuWWvFCHyoHUAnmtFiJIX8qXMtkYiUqd2KoTJFWe1eLYfQJB8JT2jRiuJYm8CnljhZa8o9hz7enPyeXHGA)

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

## Usage

To use the script, run the following command in your terminal:

**WRAP(Convert Native Token To Wrapped Token at 1:1 ratio)**
```
node main.js <Rpc_Url> <Wrapped_Token_Contract_Address> 0x0000000000000000000000000000000000000000 <Amount> wrap <Private_Key> <From_Wallet_Address> <To_Wallet_Address> <Gas_Fee>
    - Set an amount (in ethers, not wei) for <Amount> (ex: 0.1, 6.25, 100)
    - Set the gas fee (in gwei) for <GasFee> (ex: 10)
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





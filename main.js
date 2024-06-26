const { ethers } = require('ethers');
const wrap = require('./wrap');
const swapTokens = require('./swap');
const addLiquidity = require('./liquidity');
const unwrap = require('./unwrap');

// Parse command-line arguments
const args = process.argv.slice(2);
const network = args[0];
const tokenAddress1 = args[1];
const amount1 = args[2];
const privateKey = args[3];
const fromAddress = args[4];
const toAddress = args[5];
const gasFee = args[6];
const action = args[7];

let tokenAddress2, amount2;

// Validation Logic
if (action !== 'swap' && action !== 'wrap' && action !== 'liquidity' && action !== 'unwrap') {
  console.error('Invalid action. Use "swap", "wrap", "liquidity", or "unwrap"');
  process.exit(1);
}

// Validate other arguments based on the action
if (!ethers.utils.isAddress(tokenAddress1)) {
  console.error('Invalid token address for tokenAddress1');
  process.exit(1);
}

if (action === 'swap' || action === 'liquidity') {
  tokenAddress2 = args[8];
  amount2 = args[9];
  
  if (!ethers.utils.isAddress(tokenAddress2)) {
    console.error('Invalid token address for tokenAddress2');
    process.exit(1);
  }
  
  if (isNaN(parseFloat(amount2)) || parseFloat(amount2) <= 0) {
    console.error('Invalid amount2');
    process.exit(1);
  }
}

if (isNaN(parseFloat(amount1)) || parseFloat(amount1) <= 0) {
  console.error('Invalid amount1');
  process.exit(1);
}

if (!ethers.utils.isHexString(privateKey, 32)) {
  console.error('Invalid private key');
  process.exit(1);
}

if (!ethers.utils.isAddress(fromAddress) || !ethers.utils.isAddress(toAddress)) {
  console.error('Invalid from address or to address');
  process.exit(1);
}

if (isNaN(parseFloat(gasFee)) || parseFloat(gasFee) <= 0) {
  console.error('Invalid gas fee');
  process.exit(1);
}

// Main function to execute the appropriate action
async function main() {
  console.log(`Connecting to network: ${network}`);
  console.log(`RPC URL: ${network}`);
  
  try {
    const provider = new ethers.providers.JsonRpcProvider(network);
    
    console.log('Checking network connection...');
    const networkInfo = await provider.getNetwork();
    console.log(`Connected to network: ${networkInfo.name} (chainId: ${networkInfo.chainId})`);
    
    const gasPrice = ethers.utils.parseUnits(gasFee, 'gwei');
    const gasLimit = 300000; // Adjust as needed

    if (action === 'swap') {
      const amountInEther = ethers.utils.parseEther(amount1);
      await swapTokens(provider, privateKey, tokenAddress1, tokenAddress2, amountInEther, gasPrice, gasLimit);
    } else if (action === 'wrap') {
      const nativeTokenAmount = ethers.utils.parseEther(amount1);
      await wrap(provider, privateKey, nativeTokenAmount, tokenAddress1);
    } else if (action === 'liquidity') {
      const amount1InEther = ethers.utils.parseEther(amount1);
      const amount2InEther = ethers.utils.parseEther(amount2);
      await addLiquidity(provider, privateKey, tokenAddress1, tokenAddress2, amount1InEther, amount2InEther, gasPrice, gasLimit);
    } else if (action === 'unwrap') {
      const wrappedTokenAmount = ethers.utils.parseEther(amount1);
      await unwrap(provider, privateKey, tokenAddress1, wrappedTokenAmount);
    }
  } catch (error) {
    console.error('An error occurred:', error.message);
    if (error.reason) console.error('Reason:', error.reason);
    if (error.code) console.error('Error code:', error.code);
    if (error.event) console.error('Error event:', error.event);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

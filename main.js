const { ethers } = require('ethers');
const wrap = require('./wrap');
const swapTokens = require('./swap');
const addLiquidity = require('./liquidity');

// Get the network, token addresses, amounts, action, private key, from address, to address, and gas fee from command-line arguments
const network = process.argv[2];
const tokenAddress1 = process.argv[3];
const tokenAddress2 = process.argv[4];
const amount1 = process.argv[5];
const action = process.argv[6]; // 'swap', 'wrap', or 'liquidity'
const privateKey = process.argv[7];
const fromAddress = process.argv[8];
const toAddress = process.argv[9];
const gasFee = process.argv[10]; // Gas fee in Gwei

// Validate the action first
if (action !== 'swap' && action !== 'wrap' && action !== 'liquidity') {
  console.error('Invalid action. Use "swap", "wrap", or "liquidity"');
  process.exit(1);
}

// Validate other arguments based on the action
if (!ethers.utils.isAddress(tokenAddress1) || !ethers.utils.isAddress(tokenAddress2)) {
  console.error('Invalid token address');
  process.exit(1);
}

if (isNaN(parseFloat(amount1)) || parseFloat(amount1) <= 0) {
  console.error('Invalid amount1');
  process.exit(1);
}

if (action === 'liquidity') {
  const amount2 = process.argv[6];
  if (isNaN(parseFloat(amount2)) || parseFloat(amount2) <= 0) {
    console.error('Invalid amount2 for liquidity');
    process.exit(1);
  }
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
  console.log(`RPC URL: ${process.argv[2]}`);
  
  try {
    const provider = new ethers.providers.JsonRpcProvider(process.argv[2]);
    
    console.log('Checking network connection...');
    const network = await provider.getNetwork();
    console.log(`Connected to network: ${network.name} (chainId: ${network.chainId})`);
    
    const signer = new ethers.Wallet(privateKey, provider);

    const gasPrice = ethers.utils.parseUnits(gasFee, 'gwei');
    const gasLimit = 300000; // Adjust as needed

    if (action === 'swap') {
      await swapTokens(signer, tokenAddress1, tokenAddress2, amount1, gasPrice, gasLimit);
    } else if (action === 'wrap') {
      const nativeTokenAmount = ethers.utils.parseEther(amount1);
      await wrap(signer, nativeTokenAmount, tokenAddress1);
    } else if (action === 'liquidity') {
      const amount2 = process.argv[6];
      await addLiquidity(signer, tokenAddress1, tokenAddress2, amount1, amount2, gasPrice, gasLimit);
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

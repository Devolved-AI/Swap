// Simple Swap
// A Command Line Crypto Exchange Script by Pavon Dunbar for DevolvedAI

const { ethers } = require('ethers');

// Get the network, token addresses, amounts, action, private key, from address, to address, and gas fee from command-line arguments
const network = process.argv[2];
const tokenAddress1 = process.argv[3];
const tokenAddress2 = process.argv[4];
const amount1 = process.argv[5];
const action = process.argv[6]; // 'swap', 'deposit', 'liquidity', or 'cross-chain-swap'
const privateKey = process.argv[7];
const fromAddress = process.argv[8];
const toAddress = process.argv[9];
const gasFee = process.argv[10]; // Gas fee in Gwei
// Add new arguments for cross-chain swap
const destinationChain = process.argv[11]; // e.g., 'sepolia'
const destinationRPC = process.argv[12]; // RPC URL for the destination chain

// Validate the action first
if (action !== 'swap' && action !== 'deposit' && action !== 'liquidity' && action !== 'cross-chain-swap') {
  console.error('Invalid action. Use "swap", "deposit", "liquidity", or "cross-chain-swap"');
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

if (action === 'cross-chain-swap' && (!destinationChain || !destinationRPC)) {
  console.error('Destination chain and RPC URL are required for cross-chain-swap');
  process.exit(1);
}

async function deposit(signer, wrappedTokenAddress, amount) {
  const wrappedTokenContract = new ethers.Contract(
    wrappedTokenAddress,
    ['function deposit() payable'],
    signer
  );

  const tx = await wrappedTokenContract.deposit({ value: amount });
  const receipt = await tx.wait();

  console.log('Deposit successful');
  console.log('Transaction Hash:', tx.hash);
  console.log('Gas Used:', receipt.gasUsed.toString());
  console.log('Block Hash:', receipt.blockHash);
  console.log('Block Number:', receipt.blockNumber);
  console.log('Timestamp:', (await signer.provider.getBlock(receipt.blockNumber)).timestamp);
}

async function swapTokens(signer, tokenAddress1, tokenAddress2, amountIn, gasPrice, gasLimit) {
  // Get the token decimals
  const tokenContract1 = new ethers.Contract(tokenAddress1, [
    'function decimals() view returns (uint8)',
    'function approve(address spender, uint256 amount) external payable returns (bool)',
  ], signer);
  const tokenDecimals1 = await tokenContract1.decimals();

  const tokenContract2 = new ethers.Contract(tokenAddress2, [
    'function decimals() view returns (uint8)',
  ], signer);
  const tokenDecimals2 = await tokenContract2.decimals();

  // Set the swap path based on the swap type
  const path = [tokenAddress1, tokenAddress2];

  // Approve the router to spend tokens
  const routerAddress = '0x586A31a288E178369FFF020bA63d2224cf8661E9'; // Replace with the actual router address
  console.log('Approving token spending...');
  const approveTx = await tokenContract1.approve(routerAddress, amountIn, { gasLimit: gasLimit });
  const approveReceipt = await approveTx.wait();
  console.log('Token spending approved');
  console.log('Approval Transaction Hash:', approveTx.hash);
  console.log('Gas Used:', approveReceipt.gasUsed.toString());
  console.log('Block Hash:', approveReceipt.blockHash);
  console.log('Block Number:', approveReceipt.blockNumber);
  console.log('Timestamp:', (await signer.provider.getBlock(approveReceipt.blockNumber)).timestamp);

  // Execute the swap
  console.log('Executing swap...');
  const routerContract = new ethers.Contract(
    routerAddress,
    [
      'function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts)',
    ],
    signer
  );

  const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20 minutes from the current Unix time
  const amountOutMin = 0; // Set to 0 to allow any amount of output tokens

  const tx = await routerContract.swapExactTokensForTokens(
    amountIn,
    amountOutMin,
    path,
    toAddress,
    deadline,
    { gasPrice: gasPrice, gasLimit: gasLimit }
  );

  console.log('Swap transaction hash:', tx.hash);
  const receipt = await tx.wait();
  console.log('Swap transaction confirmed');
  console.log('Gas Used:', receipt.gasUsed.toString());
  console.log('Block Hash:', receipt.blockHash);
  console.log('Block Number:', receipt.blockNumber);
  console.log('Timestamp:', (await signer.provider.getBlock(receipt.blockNumber)).timestamp);
  console.log('Transaction receipt:', receipt);
}

async function addLiquidity(signer, tokenAddress1, tokenAddress2, amount1, amount2, gasPrice, gasLimit) {
  // Get the token decimals
  const tokenContract1 = new ethers.Contract(tokenAddress1, [
    'function decimals() view returns (uint8)',
    'function approve(address spender, uint256 amount) external payable returns (bool)',
  ], signer);
  const tokenDecimals1 = await tokenContract1.decimals();

  const tokenContract2 = new ethers.Contract(tokenAddress2, [
    'function decimals() view returns (uint8)',
    'function approve(address spender, uint256 amount) external payable returns (bool)',
  ], signer);
  const tokenDecimals2 = await tokenContract2.decimals();

  // Approve the router to spend tokens
  const routerAddress = '0x586A31a288E178369FFF020bA63d2224cf8661E9'; // Replace with the actual router address
  console.log('Approving token spending...');
  const approveTx1 = await tokenContract1.approve(routerAddress, amount1, { gasLimit: gasLimit });
  await approveTx1.wait();
  const approveTx2 = await tokenContract2.approve(routerAddress, amount2, { gasLimit: gasLimit });
  await approveTx2.wait();
  console.log('Token spending approved');

  // Add liquidity
  console.log('Adding liquidity...');
  const routerContract = new ethers.Contract(
    routerAddress,
    [
      'function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)',
    ],
    signer
  );

  const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20 minutes from the current Unix time
  const amountAMin = 0; // Set to 0 to allow any amount of token A
  const amountBMin = 0; // Set to 0 to allow any amount of token B

  const tx = await routerContract.addLiquidity(
    tokenAddress1,
    tokenAddress2,
    amount1,
    amount2,
    amountAMin,
    amountBMin,
    toAddress,
    deadline,
    { gasPrice: gasPrice, gasLimit: gasLimit }
  );

  console.log('Liquidity add transaction hash:', tx.hash);
  const receipt = await tx.wait();
  console.log('Liquidity add transaction confirmed');
  console.log('Transaction receipt:', receipt);
}

async function crossChainSwap(sourceSigner, destinationSigner, sourceTokenAddress, destinationTokenAddress, amount, gasPrice, gasLimit) {
  console.log('Initiating cross-chain swap...');

  // 1. Approve the bridge contract to spend tokens on the source chain
  const sourceTokenContract = new ethers.Contract(sourceTokenAddress, [
    'function approve(address spender, uint256 amount) external returns (bool)',
    'function balanceOf(address account) external view returns (uint256)'
  ], sourceSigner);

  const bridgeAddress = '0x9AfBc22eb8F3101d9D9968D89644380FDCaF3565'; // Replace with actual bridge address

  console.log('Approving token spending on source chain...');
  const approveTx = await sourceTokenContract.approve(bridgeAddress, amount, { gasLimit: gasLimit });
  await approveTx.wait();
  console.log('Token spending approved on source chain');

  // 2. Call the bridge contract to initiate the cross-chain transfer
  const bridgeContract = new ethers.Contract(bridgeAddress, [
    'function initiateTransfer(address token, uint256 amount, uint256 destinationChainId) external returns (uint256 transferId)'
  ], sourceSigner);

  console.log('Initiating transfer on bridge contract...');
  const transferTx = await bridgeContract.initiateTransfer(sourceTokenAddress, amount, destinationChainId, { gasPrice: gasPrice, gasLimit: gasLimit });
  const transferReceipt = await transferTx.wait();
  const transferId = transferReceipt.events.find(e => e.event === 'TransferInitiated').args.transferId;
  console.log(`Transfer initiated. Transfer ID: ${transferId}`);

  // 3. Wait for the transfer to be confirmed on the destination chain
  const destinationBridgeAddress = '0x0987654321098765432109876543210987654321'; // Replace with actual destination bridge address
  const destinationBridgeContract = new ethers.Contract(destinationBridgeAddress, [
    'function claimTransfer(uint256 transferId) external',
    'function isTransferReady(uint256 transferId) external view returns (bool)'
  ], destinationSigner);

  console.log('Waiting for transfer to be ready on destination chain...');
  while (true) {
    const isReady = await destinationBridgeContract.isTransferReady(transferId);
    if (isReady) break;
    await new Promise(resolve => setTimeout(resolve, 15000)); // Wait 15 seconds before checking again
  }

  // 4. Claim the transfer on the destination chain
  console.log('Claiming transfer on destination chain...');
  const claimTx = await destinationBridgeContract.claimTransfer(transferId, { gasPrice: gasPrice, gasLimit: gasLimit });
  await claimTx.wait();
  console.log('Transfer claimed on destination chain');

  // 5. Swap the received tokens on the destination chain
  console.log('Swapping tokens on destination chain...');
  await swapTokens(destinationSigner, destinationTokenAddress, destinationSigner.address, amount, gasPrice, gasLimit);
  
  console.log('Cross-chain swap completed successfully');
}

// Main function to execute the appropriate action
async function main() {
  const provider = new ethers.providers.JsonRpcProvider(`https://${network}.infura.io/v3/YOUR_INFURA_PROJECT_ID`);
  const signer = new ethers.Wallet(privateKey, provider);

  const gasPrice = ethers.utils.parseUnits(gasFee, 'gwei');
  const gasLimit = 300000; // Adjust as needed

  if (action === 'swap') {
    await swapTokens(signer, tokenAddress1, tokenAddress2, amount1, gasPrice, gasLimit);
  } else if (action === 'deposit') {
    await deposit(signer, tokenAddress1, amount1);
  } else if (action === 'liquidity') {
    const amount2 = process.argv[6];
    await addLiquidity(signer, tokenAddress1, tokenAddress2, amount1, amount2, gasPrice, gasLimit);
  } else if (action === 'cross-chain-swap') {
    const destinationProvider = new ethers.providers.JsonRpcProvider(destinationRPC);
    const destinationSigner = new ethers.Wallet(privateKey, destinationProvider);
    await crossChainSwap(signer, destinationSigner, tokenAddress1, tokenAddress2, amount1, gasPrice, gasLimit);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

const { ethers } = require('ethers');

async function swapTokens(provider, privateKey, tokenAddress1, tokenAddress2, amountIn, gasPrice, gasLimit) {
  const wallet = new ethers.Wallet(privateKey, provider);

  // Get the token decimals
  const tokenContract1 = new ethers.Contract(tokenAddress1, [
    'function decimals() view returns (uint8)',
    'function approve(address spender, uint256 amount) external payable returns (bool)',
  ], wallet);
  const tokenDecimals1 = await tokenContract1.decimals();

  const tokenContract2 = new ethers.Contract(tokenAddress2, [
    'function decimals() view returns (uint8)',
  ], wallet);
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
  console.log('Timestamp:', (await wallet.provider.getBlock(approveReceipt.blockNumber)).timestamp);

  // Execute the swap
  console.log('Executing swap...');
  const routerContract = new ethers.Contract(
    routerAddress,
    [
      'function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts)',
    ],
    wallet
  );

  const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20 minutes from the current Unix time
  const amountOutMin = 0; // Set to 0 to allow any amount of output tokens

  const tx = await routerContract.swapExactTokensForTokens(
    amountIn,
    amountOutMin,
    path,
    wallet.address,
    deadline,
    { gasPrice: gasPrice, gasLimit: gasLimit }
  );

  console.log('Swap transaction hash:', tx.hash);
  const receipt = await tx.wait();
  console.log('Swap transaction confirmed');
  console.log('Gas Used:', receipt.gasUsed.toString());
  console.log('Block Hash:', receipt.blockHash);
  console.log('Block Number:', receipt.blockNumber);
  console.log('Timestamp:', (await wallet.provider.getBlock(receipt.blockNumber)).timestamp);
  console.log('Transaction receipt:', receipt);
}

module.exports = swapTokens;

const { ethers } = require('ethers');

async function addLiquidity(provider, privateKey, tokenAddress1, tokenAddress2, amount1, amount2, gasPrice, gasLimit) {
  const wallet = new ethers.Wallet(privateKey, provider);

  // Get the token decimals
  const tokenContract1 = new ethers.Contract(tokenAddress1, [
    'function decimals() view returns (uint8)',
    'function approve(address spender, uint256 amount) external payable returns (bool)',
  ], wallet);
  const tokenDecimals1 = await tokenContract1.decimals();

  const tokenContract2 = new ethers.Contract(tokenAddress2, [
    'function decimals() view returns (uint8)',
    'function approve(address spender, uint256 amount) external payable returns (bool)',
  ], wallet);
  const tokenDecimals2 = await tokenContract2.decimals();

  // Approve the router to spend tokens
  const routerAddress = '0x586A31a288E178369FFF020bA63d2224cf8661E9'; // Replace with the actual router address
  console.log('Approving token spending...');
  const approveTx1 = await tokenContract1.approve(routerAddress, amount1, { gasLimit: gasLimit });
  await approveTx1.wait();
  console.log('Token 1 spending approved');
  console.log('Approval Transaction Hash:', approveTx1.hash);
  console.log('Gas Used:', (await approveTx1.wait()).gasUsed.toString());
  console.log('Block Hash:', (await approveTx1.wait()).blockHash);
  console.log('Block Number:', (await approveTx1.wait()).blockNumber);
  console.log('Timestamp:', (await wallet.provider.getBlock((await approveTx1.wait()).blockNumber)).timestamp);

  const approveTx2 = await tokenContract2.approve(routerAddress, amount2, { gasLimit: gasLimit });
  await approveTx2.wait();
  console.log('Token 2 spending approved');
  console.log('Approval Transaction Hash:', approveTx2.hash);
  console.log('Gas Used:', (await approveTx2.wait()).gasUsed.toString());
  console.log('Block Hash:', (await approveTx2.wait()).blockHash);
  console.log('Block Number:', (await approveTx2.wait()).blockNumber);
  console.log('Timestamp:', (await wallet.provider.getBlock((await approveTx2.wait()).blockNumber)).timestamp);

  // Add liquidity
  console.log('Adding liquidity...');
  const routerContract = new ethers.Contract(
    routerAddress,
    [
      'function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)',
    ],
    wallet
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
    wallet.address,
    deadline,
    { gasPrice: gasPrice, gasLimit: gasLimit }
  );

  console.log('Liquidity add transaction hash:', tx.hash);
  const receipt = await tx.wait();
  console.log('Liquidity add transaction confirmed');
  console.log('Gas Used:', receipt.gasUsed.toString());
  console.log('Block Hash:', receipt.blockHash);
  console.log('Block Number:', receipt.blockNumber);
  console.log('Timestamp:', (await wallet.provider.getBlock(receipt.blockNumber)).timestamp);
  console.log('Transaction receipt:', receipt);
}

module.exports = addLiquidity;

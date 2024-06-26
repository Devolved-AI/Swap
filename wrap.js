const { ethers } = require('ethers');

async function wrap(provider, privateKey, nativeTokenAmount, wrappedTokenAddress) {
  const signer = new ethers.Wallet(privateKey, provider);

  const wrappedTokenContract = new ethers.Contract(
    wrappedTokenAddress,
    ['function deposit() payable', 'function withdraw(uint256) public'],
    signer
  );

  try {
    const tx = await wrappedTokenContract.deposit({ value: nativeTokenAmount });
    const receipt = await tx.wait();

    console.log('Wrapping successful');
    console.log('Transaction Hash:', tx.hash);
    console.log('Gas Used:', receipt.gasUsed.toString());
    console.log('Block Hash:', receipt.blockHash);
    console.log('Block Number:', receipt.blockNumber);
    console.log('Timestamp:', (await provider.getBlock(receipt.blockNumber)).timestamp);
  } catch (error) {
    console.error('An error occurred during wrapping:', error);
    throw error;
  }
}

module.exports = wrap;

const { ethers } = require('ethers');

async function wrap(signer, nativeTokenAmount, wrappedTokenAddress) {
  const wrappedTokenContract = new ethers.Contract(
    wrappedTokenAddress,
    ['function deposit() payable', 'function withdraw(uint256) public'],
    signer
  );

  const tx = await wrappedTokenContract.deposit({ value: nativeTokenAmount });
  const receipt = await tx.wait();

  console.log('Wrapping successful');
  console.log('Transaction Hash:', tx.hash);
  console.log('Gas Used:', receipt.gasUsed.toString());
  console.log('Block Hash:', receipt.blockHash);
  console.log('Block Number:', receipt.blockNumber);
  console.log('Timestamp:', (await signer.provider.getBlock(receipt.blockNumber)).timestamp);
}

module.exports = wrap;

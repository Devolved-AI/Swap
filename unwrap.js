const { ethers } = require('ethers');

async function unwrap(provider, privateKey, wrappedTokenAddress, amount) {
  const wallet = new ethers.Wallet(privateKey, provider);
  const wrappedTokenContract = new ethers.Contract(
    wrappedTokenAddress,
    ['function withdraw(uint256) public'],
    wallet
  );

  console.log('Unwrapping token...');
  const tx = await wrappedTokenContract.withdraw(amount);
  console.log('Unwrap transaction hash:', tx.hash);

  const receipt = await tx.wait();
  console.log('Unwrap transaction confirmed');
  console.log('Gas used:', receipt.gasUsed.toString());

  const nativeTokenBalance = await provider.getBalance(wallet.address);
  console.log('Native token balance:', ethers.utils.formatEther(nativeTokenBalance));
}

module.exports = unwrap;

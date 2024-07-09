import React, { useState } from 'react';
import PropTypes from 'prop-types';
import web3 from '../web3';

const Approve = ({ account, contract }) => {
  const [tokenAddress, setTokenAddress] = useState('');
  const [amount, setAmount] = useState('');
  const [transactionDetails, setTransactionDetails] = useState(null);

  const handleApprove = async (event) => {
    event.preventDefault();
    
    if (!account) {
      alert('Please connect your wallet first.');
      return;
    }

    if (!contract) {
      alert('Contract not loaded.');
      return;
    }

    const tokenAbi = [
      {
        "constant": false,
        "inputs": [
          { "name": "_spender", "type": "address" },
          { "name": "_value", "type": "uint256" }
        ],
        "name": "approve",
        "outputs": [{ "name": "", "type": "bool" }],
        "type": "function"
      }
    ];

    const tokenContract = new web3.eth.Contract(tokenAbi, tokenAddress);

    try {
      const transaction = await tokenContract.methods.approve(contract.options.address, web3.utils.toWei(amount, 'ether')).send({ from: account });
      const receipt = await web3.eth.getTransactionReceipt(transaction.transactionHash);
      const block = await web3.eth.getBlock(receipt.blockNumber);

      const details = {
        transactionHash: receipt.transactionHash,
        blockHash: receipt.blockHash,
        blockNumber: receipt.blockNumber,
        timestamp: Number(block.timestamp)  // Convert BigInt to number
      };

      setTransactionDetails(details);

      alert('Approval successful');
    } catch (error) {
      console.error('Approval failed', error);
      alert('Approval failed. Check the console for more details.');
    }
  };

  return (
    <div>
      <form onSubmit={handleApprove}>
        <div>
          <label>Token Address:</label>
          <input value={tokenAddress} onChange={(e) => setTokenAddress(e.target.value)} />
        </div>
        <div>
          <label>Amount:</label>
          <input value={amount} onChange={(e) => setAmount(e.target.value)} />
        </div>
        <button type="submit">Approve</button>
      </form>
      {transactionDetails && (
        <div>
          <h3>Transaction Details:</h3>
          <p><b>Transaction Hash:</b> {transactionDetails.transactionHash}</p>
          <p><b>Block Hash:</b> {transactionDetails.blockHash}</p>
          <p><b>Block Number:</b> {transactionDetails.blockNumber}</p>
          <p><b>Timestamp:</b> {new Date(transactionDetails.timestamp * 1000).toLocaleString()}</p>
        </div>
      )}
    </div>
  );
};

Approve.propTypes = {
  account: PropTypes.string.isRequired,
  contract: PropTypes.object.isRequired
};

export default Approve;


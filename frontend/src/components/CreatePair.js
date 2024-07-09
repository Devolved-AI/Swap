import React, { useState } from 'react';
import web3 from '../web3';
import contract from '../contract';

const CreatePair = () => {
  const [token0, setToken0] = useState('');
  const [token1, setToken1] = useState('');
  const [transactionHash, setTransactionHash] = useState('');
  const [blockHash, setBlockHash] = useState('');
  const [blockNumber, setBlockNumber] = useState('');
  const [timestamp, setTimestamp] = useState('');

  const handleCreatePair = async (event) => {
    event.preventDefault();
    const accounts = await web3.eth.getAccounts();
    try {
      const result = await contract.methods.createPair(token0, token1).send({ from: accounts[0] });

      // Extract transaction details from the result object
      const { transactionHash, blockHash, blockNumber } = result;

      // Fetch block details using blockNumber
      const block = await web3.eth.getBlock(blockNumber);
      const { timestamp } = block;

      // Set state with transaction and block details
      setTransactionHash(transactionHash);
      setBlockHash(blockHash);
      setBlockNumber(Number(blockNumber)); // Convert BigInt to Number explicitly
      setTimestamp(Number(timestamp)); // Convert BigInt to Number explicitly

      alert('Pair created successfully');
    } catch (error) {
      console.error('Create pair failed', error);
      alert('Create pair failed. Check the console for more details.');
    }
  };

  return (
    <div>
      <form onSubmit={handleCreatePair}>
        <div>
          <label>Token 0:</label>
          <input value={token0} onChange={(e) => setToken0(e.target.value)} />
        </div>
        <div>
          <label>Token 1:</label>
          <input value={token1} onChange={(e) => setToken1(e.target.value)} />
        </div>
        <button type="submit">Create Pair</button>
      </form>

      {/* Display transaction and block details if available */}
      {transactionHash && (
        <div>
          <h3><b>Transaction Details</b></h3>
          <p><b>Transaction Hash:</b> {transactionHash}</p>
          <p><b>Block Hash:</b> {blockHash}</p>
          <p><b>Block Number:</b> {blockNumber}</p>
          <p><b>Timestamp:</b> {new Date(timestamp * 1000).toLocaleString()}</p>
        </div>
      )}
    </div>
  );
};

export default CreatePair;


import React, { useState } from 'react';
import web3 from '../web3';
import contract from '../contract';

const RemoveLiquidity = () => {
  const [pairId, setPairId] = useState('');
  const [shares, setShares] = useState('');

  const handleRemoveLiquidity = async (event) => {
    event.preventDefault();
    const accounts = await web3.eth.getAccounts();
    await contract.methods.removeLiquidity(pairId, shares).send({ from: accounts[0] });
  };

  return (
    <form onSubmit={handleRemoveLiquidity}>
      <div>
        <label>Pair ID:</label>
        <input value={pairId} onChange={(e) => setPairId(e.target.value)} />
      </div>
      <div>
        <label>Shares:</label>
        <input value={shares} onChange={(e) => setShares(e.target.value)} />
      </div>
      <button type="submit">Remove Liquidity</button>
    </form>
  );
};

export default RemoveLiquidity;


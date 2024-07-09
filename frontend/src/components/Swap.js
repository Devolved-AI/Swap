import React, { useState } from 'react';
import web3 from '../web3';
import contract from '../contract';

const Swap = () => {
  const [pairId, setPairId] = useState('');
  const [tokenIn, setTokenIn] = useState('');
  const [amountIn, setAmountIn] = useState('');

  const handleSwap = async (event) => {
    event.preventDefault();
    const accounts = await web3.eth.getAccounts();
    await contract.methods.swap(pairId, tokenIn, amountIn).send({ from: accounts[0] });
  };

  return (
    <form onSubmit={handleSwap}>
      <div>
        <label>Pair ID:</label>
        <input value={pairId} onChange={(e) => setPairId(e.target.value)} />
      </div>
      <div>
        <label>Token In:</label>
        <input value={tokenIn} onChange={(e) => setTokenIn(e.target.value)} />
      </div>
      <div>
        <label>Amount In:</label>
        <input value={amountIn} onChange={(e) => setAmountIn(e.target.value)} />
      </div>
      <button type="submit">Swap</button>
    </form>
  );
};

export default Swap;


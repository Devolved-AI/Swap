import React, { useState } from 'react';
import web3 from '../web3';
import contract from '../contract';

const AddLiquidity = () => {
  const [pairId, setPairId] = useState('');
  const [amount0, setAmount0] = useState('');
  const [amount1, setAmount1] = useState('');

  const handleAddLiquidity = async (event) => {
    event.preventDefault();
    const accounts = await web3.eth.getAccounts();
    await contract.methods.addLiquidity(pairId, amount0, amount1).send({ from: accounts[0] });
  };

  return (
    <form onSubmit={handleAddLiquidity}>
      <div>
        <label>Pair ID:</label>
        <input value={pairId} onChange={(e) => setPairId(e.target.value)} />
      </div>
      <div>
        <label>Amount 0:</label>
        <input value={amount0} onChange={(e) => setAmount0(e.target.value)} />
      </div>
      <div>
        <label>Amount 1:</label>
        <input value={amount1} onChange={(e) => setAmount1(e.target.value)} />
      </div>
      <button type="submit">Add Liquidity</button>
    </form>
  );
};

export default AddLiquidity;


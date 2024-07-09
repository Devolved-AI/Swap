import React, { useState } from 'react';
import Approve from './Approve'; // Adjust the import path as needed
import web3 from '../web3'; // Assuming this is where you import your web3 instance
import contract from '../contract'; // Assuming this is where you import your contract instance

const ParentComponent = () => {
  const [account, setAccount] = useState(null); // State to store the connected account

  const connectWallet = async () => {
    try {
      const accounts = await web3.eth.requestAccounts();
      setAccount(accounts[0]);
    } catch (error) {
      console.error('Failed to connect wallet', error);
      alert('Failed to connect wallet. Check the console for more details.');
    }
  };

  return (
    <div>
      <button className="connect-button" onClick={connectWallet}>
        Connect Wallet
      </button>
      {account && (
        <Approve account={account} contract={contract} />
      )}
    </div>
    <div>
  );
};

export default ParentComponent;


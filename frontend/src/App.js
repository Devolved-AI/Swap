import React, { useState, useEffect } from 'react';
import web3 from './web3';
import AddLiquidity from './components/AddLiquidity';
import CreatePair from './components/CreatePair';
import Swap from './components/Swap';
import RemoveLiquidity from './components/RemoveLiquidity';
import Approve from './components/Approve';
import contractABI from './AmmABI.json';

const App = () => {
  const [account, setAccount] = useState('');
  const [contract, setContract] = useState(null);

  useEffect(() => {
    if (web3 && account) {
      const contractAddress = '0x2BFA6a1B4074391E5788f1174CC1fa396dB0aaB2';
      const instance = new web3.eth.Contract(contractABI, contractAddress);
      setContract(instance);
    }
  }, [account]);

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        setAccount(accounts[0]);
      } catch (error) {
        console.error("User denied account access", error);
      }
    } else {
      alert('Please install MetaMask!');
    }
  };

  const changeWallet = async () => {
    if (window.ethereum) {
      try {
        await window.ethereum.request({ method: 'wallet_requestPermissions', params: [{ eth_accounts: {} }] });
        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        if (accounts.length > 0) {
          setAccount(accounts[0]);
        }
      } catch (error) {
        console.error("Error changing account", error);
      }
    } else {
      alert('Please install MetaMask!');
    }
  };

  return (
    <div style={{ textAlign: 'center' }}>
      <h1>Welcome To ArgoSwap</h1>
      {account ? (
        <div>
          <p><b>Wallet Connected At:</b> {account}</p>
          <button onClick={changeWallet} style={styles.button}>Change Wallet</button>
        </div>
      ) : (
        <button onClick={connectWallet} style={styles.button}>Connect Wallet</button>
      )}
      
      <Section title="Create Pair">
        <CreatePair account={account} contract={contract} />
      </Section>

      <Section title="Approve">
        <Approve account={account} contract={contract} />
      </Section>

      <Section title="Add Liquidity">
        <AddLiquidity account={account} contract={contract} />
      </Section>

      <Section title="Swap">
        <Swap account={account} contract={contract} />
      </Section>

      <Section title="Remove Liquidity">
        <RemoveLiquidity account={account} contract={contract} />
      </Section>

      <footer style={{ fontSize: '12px', color: 'black', marginTop: '20px' }}>
        <p>
          Copyright 2024 Argoswap. This swap is maintained by
          <a href="https://www.devolvedAI.com" target="_blank" rel="noopener noreferrer" style={{ color: 'black', textDecoration: 'underline' }}> Devolved AI</a>.
        </p>
      </footer>
    </div>
  );
};

const Section = ({ title, children }) => (
  <div>
    <h2><b>{title}</b></h2>
    {children}
    <br />
  </div>
);

const styles = {
  button: {
    padding: '10px 20px',
    fontSize: '20px',
    fontWeight: 'bold',
    borderRadius: '20px',
    backgroundColor: '#007bff',
    color: 'white',
    border: 'none',
    cursor: 'pointer',
    marginTop: '10px'
  }
};

export default App;

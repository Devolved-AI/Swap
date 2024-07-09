import web3 from './web3';
import contractAbi from './AMM.json'; // Update this path as needed

const contractAddress = '0x1fF77009f6b42Fb3C0C51De154bd201eEA6Da347';
const contract = new web3.eth.Contract(contractAbi.abi, contractAddress);

export default contract;


import { useState, useEffect } from 'react';
import Web3 from 'web3';
import { CONTRACT_ABI, CONTRACT_ADDRESS } from './constants';

const web3 = new Web3(Web3.givenProvider);

const App = () => {
  const [tokenList, setTokenList] = useState([]);
  const [fromToken, setFromToken] = useState(null);
  const [toToken, setToToken] = useState(null);
  const [amount, setAmount] = useState('');
  const [result, setResult] = useState('');

  useEffect(() => {
    const fetchTokenList = async () => {
      const tokenListResponse = await fetch('https://api.1inch.exchange/v3.0/1/tokens');
      const tokenList = await tokenListResponse.json();
      console.log(tokenList.tokens);
      setTokenList(tokenList.tokens);
    };
    fetchTokenList();
  }, []);

  const handleTrade = async () => {
    // Get the token addresses
    const fromTokenAddress = tokenList.find(token => token.symbol === fromToken).address;
    const toTokenAddress = tokenList.find(token => token.symbol === toToken).address;

    // Set up the contract and the transaction data
    const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
    const txData = {
      from: web3.eth.defaultAccount,
      to: CONTRACT_ADDRESS,
      value: fromTokenAddress === '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' ? amount : '0x0',
      data: contract.methods.swap(
        fromTokenAddress,
        toTokenAddress,
        web3.utils.toHex(amount),
        1,
        '0x0000000000000000000000000000000000000000',
        0
      ).encodeABI()
    };

    // Send the transaction
    const txHash = await web3.eth.sendTransaction(txData);

    setResult(`Transaction sent: https://etherscan.io/tx/${txHash}`);
  };

  return (
    <div>
      <h1>Trade Form</h1>
      <label>
        From Token:
        <select value={fromToken} onChange={(e) => setFromToken(e.target.value)}>
          <option value={null}>Select a token</option>
          {Object.keys(tokenList).map(key => <option value={tokenList[key].symbol} key={tokenList[key].symbol}>{tokenList[key].symbol}</option>)}
        </select>
      </label>
      <br />
      <label>
        To Token:
        <select value={toToken} onChange={(e) => setToToken(e.target.value)}>
          <option value={null}>Select a token</option>
          {Object.keys(tokenList).map(key => <option value={tokenList[key].symbol} key={tokenList[key].symbol}>{tokenList[key].symbol}</option>)}
        </select>
      </label>
      <br />
      <label>
        Amount:
        <input type="number" value={amount} onChange={(e) => setAmount(e.target.value)} />
      </label>
      <br />
      <button onClick={handleTrade}>Trade</button>
      <p>{result}</p>
    </div>
  );
};

export default App;

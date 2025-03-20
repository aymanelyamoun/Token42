require("@nomicfoundation/hardhat-toolbox");
require('@nomicfoundation/hardhat-verify');
require('dotenv').config();


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  etherscan: {
    apiKey: {
      moonbaseAlpha: process.env.MOONBASE_API_KEY,
    }
      // "9V9RTQ3AVFUB7T14IHE1VQ7AFHSMZ3W7KW",
  },
  networks: {
    moonbase: {
      url: 'https://rpc.api.moonbase.moonbeam.network',
      chainId: 1287,
      accounts: process.env.PRIVATE_KEYS.split(','),
    },
  },
};

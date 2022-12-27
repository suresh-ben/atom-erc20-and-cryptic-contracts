/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-waffle");
require('dotenv').config()

module.exports = {
  solidity: "0.8.17",

  mocha: {
    timeout: 100000000
  },

  networks: {
    sepolia: {
      url : "https://sepolia.infura.io/v3/" + process.env.NETWORK_KEY,
      accounts : [ process.env.PRIVATE_KEY, ]
    }
  }
};

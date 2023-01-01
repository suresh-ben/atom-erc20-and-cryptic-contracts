/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-waffle");
require('dotenv').config()

module.exports = {
    solidity: "0.8.17",

    mocha: {
        timeout: 100000000
    },

    networks: {
        //without network metion, contract will deploy on hardhat runtime blockchain

        localhost: {
            url: "http://127.0.0.1:8545/",
            chainId: 31337,
            //No account -- hardhat will take care of it
        },
        sepolia: {
            url: "https://sepolia.infura.io/v3/" + process.env.NETWORK_KEY,
            accounts: [process.env.PRIVATE_KEY, ]
        }

    }
};
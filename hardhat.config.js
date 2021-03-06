require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

module.exports = {
  solidity: "0.8.0",
  networks: {
    rinkeby: {
      url: process.env.PROD_ALCHEMY_KEY,
      accounts: [proces.env.PRIVATE_KEY],
    },
  },
};
require("@nomicfoundation/hardhat-toolbox");
/** @type import('hardhat/config').HardhatUserConfig */
require("@truffle/dashboard-hardhat-plugin");
const ETHERSCAN_API_KEY=""

module.exports = {
  solidity: "0.8.17",

  defaultNetwork: "truffledashboard",

  networks: {
    truffledashboard: {
      url: "http://localhost:24012/rpc"
    }
  },
};

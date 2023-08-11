import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import './tasks/compileVyper';


const config: HardhatUserConfig = {
  vyper: "0.3.7",
};

const { task } = require('hardhat/config')

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

module.exports = {
  vyper: {
    version: "0.3.7",
  },
  networks: {
    hardhat: {
      chainId: 31337,
      forking: {
        url: `https://eth.llamarpc.com`
      }
    }
  }
}

export default config;

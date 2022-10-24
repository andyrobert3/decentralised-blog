import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
	solidity: "0.8.17",
	networks: {
		hardhat: {
			chainId: 1337,
		},
	},
};

export default config;

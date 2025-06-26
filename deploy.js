// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  // Deploy a mock ERC20 token first (for testing)
  const MockToken = await ethers.getContractFactory("MockERC20");
  const mockToken = await MockToken.deploy("Neural Token", "NEURAL", ethers.parseEther("1000000"));
  
  // Deploy the Neural Consensus Engine
  const NeuralConsensusEngine = await ethers.getContractFactory("NeuralConsensusEngine");
  const neuralEngine = await NeuralConsensusEngine.deploy(mockToken.address);
  
  console.log("Neural Consensus Engine deployed to:", neuralEngine.address);
  console.log("Mock Token deployed to:", mockToken.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
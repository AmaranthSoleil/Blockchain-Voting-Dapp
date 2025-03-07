const hre = require("hardhat");

async function main() {
  console.log("Deploying contract...");

  // Get the contract factory
  const Voting = await hre.ethers.getContractFactory("VotingDApp");

  // Deploy the contract
  const voting = await Voting.deploy();

  // Wait for the deployment transaction to be mined
  await voting.waitForDeployment();

  // Get the deployed contract address
  const address = await voting.getAddress();
  console.log("Voting contract deployed at:", address);
}

// Run the script and handle errors
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error deploying contract:", error);
    process.exit(1);
  });
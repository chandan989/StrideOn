const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Starting StrideonScores Hackathon Deployment...");

  // Get signers
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // Deploy a mock VERY token for testing
  console.log("\n🪙 Deploying Mock VERY Token...");
  const MockToken = await ethers.getContractFactory("MockERC20");
  const mockToken = await MockToken.deploy("VERY Token", "VERY");
  await mockToken.waitForDeployment();
  console.log("✅ Mock VERY Token deployed to:", await mockToken.getAddress());

  // Deploy a mock price oracle for testing
  console.log("\n📊 Deploying Mock Price Oracle...");
  const MockOracle = await ethers.getContractFactory("MockAggregatorV3");
  const mockOracle = await MockOracle.deploy();
  await mockOracle.waitForDeployment();
  console.log("✅ Mock Price Oracle deployed to:", await mockOracle.getAddress());

  // Use deployer address as timelock for now
  const timelockAddress = deployer.address;
  console.log("⏰ Using deployer as timelock:", timelockAddress);

  // Deploy StrideonScores
  console.log("\n🎮 Deploying StrideonScores Contract...");
  const StrideonScores = await ethers.getContractFactory("StrideonScores");
  const contract = await StrideonScores.deploy(await mockToken.getAddress(), timelockAddress, await mockOracle.getAddress());
  await contract.waitForDeployment();
  console.log("✅ StrideonScores deployed to:", await contract.getAddress());

  console.log("\n🎉 HACKATHON DEPLOYMENT COMPLETED!");
  console.log("=".repeat(50));
  console.log("📋 CONTRACT ADDRESSES:");
  console.log("- Mock VERY Token:", await mockToken.getAddress());
  console.log("- Mock Price Oracle:", await mockOracle.getAddress());
  console.log("- Timelock (deployer):", timelockAddress);
  console.log("- StrideonScores:", await contract.getAddress());
  console.log("=".repeat(50));
  
  console.log("\n🔗 VERY NETWORK READY:");
  console.log("Your contracts are ready to deploy to Very Network when testnet is available!");
  console.log("Simply update the network configuration and deploy with the same addresses.");
  
  console.log("\n📚 NEXT STEPS:");
  console.log("1. Test all contract functions locally");
  console.log("2. Create frontend integration");
  console.log("3. Prepare demo presentation");
  console.log("4. Deploy to Very Network when testnet launches");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});

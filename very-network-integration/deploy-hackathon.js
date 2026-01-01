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
  const mockOracle = await MockOracle.deploy(100000000, 8);
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

  // --- SIMULATE TRANSACTIONS ---
  console.log("\n🔄 SIMULATING GAMEPLAY TRANSACTIONS...");

  // 1. Approve Tokens
  const approveAmount = ethers.parseEther("100");
  const txApprove = await mockToken.approve(await contract.getAddress(), approveAmount);
  await txApprove.wait();
  console.log(`✅ Approved 100 VERY tokens for game contract`);

  // 2. Purchase PowerUp (Type 1: Shield)
  console.log("🛡 Purchasing Shield PowerUp...");
  const txPurchase = await contract.purchasePowerUp(1);
  const rcPurchase = await txPurchase.wait();
  console.log(`✅ PowerUp Purchased! Tx Hash: ${rcPurchase.hash}`);

  // 3. Commit Score
  console.log("🏃 Committing Run Score (500 pts)...");
  // Arbitrary signature values for hackathon mock
  const v = 27;
  const r = ethers.ZeroHash;
  const s = ethers.ZeroHash;
  const txScore = await contract.commitScoreUpdate(deployer.address, 500, v, r, s);
  await txScore.wait();
  console.log(`✅ Score Committed!`);

  // 4. Verify Score
  const newScore = await contract.getPlayerScore(deployer.address);
  console.log(`📈 Current Player Score: ${newScore.toString()}`);

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

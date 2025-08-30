# 🏃‍♂️ StrideonScores - Move-to-Earn Game

<div align="center">

![StrideonScores](https://img.shields.io/badge/StrideonScores-Move--to--Earn-brightgreen)
![Blockchain](https://img.shields.io/badge/Blockchain-Ethereum-blue)
![Very Network](https://img.shields.io/badge/Network-Very%20Network-purple)
![Hackathon](https://img.shields.io/badge/Built%20For-Hackathon-orange)

**A revolutionary blockchain-based Move-to-Earn game built for the Very Network hackathon**


</div>

---

## 🌟 What is StrideonScores?

StrideonScores is a **Move-to-Earn (M2E)** blockchain game where players earn **VERY tokens** by staying active and moving. Built on **Very Network**, it combines fitness motivation with blockchain rewards.

### 🎯 Key Features
- 🏃‍♂️ **Move-to-Earn Mechanics** - Earn tokens by moving
- ⚡ **Power-ups System** - Shield, Ghost Mode, Speed Boost
- 🏆 **Competitive Leaderboard** - Compete with other players
- 🪙 **VERY Token Rewards** - Real token distribution
- ⏱️ **Time-weighted Scoring** - Fair and balanced scoring system

---

## 🚀 Quick Start

### Prerequisites
- Node.js (v14.0.0 or higher)
- Python 3.8+
- Git
- MetaMask (Latest version)
- Solidity 0.8.19 or lower

### 1️⃣ Clone the Repository
```bash
git clone <your-repo-url>
cd strideon-scores
npm install
npm install dotenv
```

### 2️⃣ Start the Local Blockchain Network
```bash
# Start Hardhat node (keep this running)
npx hardhat node --hostname 0.0.0.0 --port 8545
```

**Expected Output:**
```
Started HTTP and WebSocket JSON-RPC server at http://0.0.0.0:8545/
Accounts
========
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
Account #1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH)
...
```

### 3️⃣ Deploy Smart Contracts
```bash
# Deploy to local network (development)
npx hardhat run deploy-hackathon.js --network hardhat

# Deploy to Verychain mainnet (production)
npx hardhat run deploy-hackathon.js --network verychain
```

**Expected Output (Local):**
```
✅ VERY Token deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
✅ StrideonScores deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

**Expected Output (Mainnet):**
```
✅ VERY Token deployed to: 0x[MAINNET_ADDRESS]
✅ StrideonScores deployed to: 0x[MAINNET_ADDRESS]
```

### 4️⃣ Start Python Backend
```bash
# Install Python dependencies
pip install web3 flask requests

# Start the backend server
python python-backend-integration.py
```

---

## 📱 Mobile Integration

### React Native / Flutter Setup

Your mobile app can connect to the blockchain in two ways:

#### Option 1: Backend API (Recommended)
```javascript
// Mobile app calls your Python backend
const response = await fetch('http://your-backend:5000/api/player/score/0x123...');
const data = await response.json();
```

#### Option 2: Direct Blockchain Connection
```javascript
// Mobile app connects directly to Hardhat network
const web3 = new Web3('http://192.168.31.172:8545');
const contract = new web3.eth.Contract(ABI, '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0');
```

### 📋 Mobile Configuration
```javascript
const networkConfig = {
    rpcUrl: 'http://192.168.31.172:8545',
    chainId: 1337,
    networkName: 'Local Hardhat'
};

const contractAddresses = {
    strideonScores: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
    veryToken: '0x5FbDB2315678afecb367f032d93F642f64180aa3'
};
```

---

## 🐍 Python Backend

### Features
- ✅ **Web3 Integration** - Direct blockchain interaction
- ✅ **Flask API** - REST endpoints for mobile apps
- ✅ **Transaction Handling** - Sign and send transactions
- ✅ **Error Management** - Robust error handling

### API Endpoints
```bash
GET  /api/player/score/{address}     # Get player score
GET  /api/leaderboard?count=10       # Get leaderboard
GET  /api/token/balance/{address}    # Get token balance
POST /api/powerup/purchase           # Buy power-up
POST /api/player/claim               # Claim score
```

### Example Usage
```python
from python_backend_integration import StrideonScoresBackend

# Initialize backend
backend = StrideonScoresBackend()

# Get player score
score = backend.get_player_score("0x123...")

# Get leaderboard
leaderboard = backend.get_leaderboard(10)

# Purchase power-up
tx_hash = backend.purchase_power_up(1, 0.01)  # Shield, 0.01 ETH
```

---

## 🎮 Game Features

### 🏃‍♂️ Move-to-Earn Mechanics
- **Step Tracking** - Count your daily steps
- **Activity Rewards** - Earn tokens for being active
- **Distance Tracking** - Track running/walking distance
- **Time-based Scoring** - Rewards based on activity duration

### ⚡ Power-ups System
| Power-up | Effect | Cost |
|----------|--------|------|
| 🛡️ **Shield** | Protects from score loss | 0.01 ETH |
| 👻 **Ghost Mode** | Invisible to other players | 0.02 ETH |
| 🚀 **Speed Boost** | 2x score multiplier | 0.03 ETH |

### 🏆 Leaderboard System
- **Global Rankings** - Compete worldwide
- **Weekly Resets** - Fresh competition every week
- **Reward Distribution** - Top players get bonus tokens
- **Achievement System** - Unlock special badges

### 🪙 Token Economics
- **VERY Token** - Native game currency
- **Earning Rate** - Based on activity level
- **Staking Rewards** - Earn by holding tokens
- **Governance** - Token holders can vote on game updates

---

## 🌐 Verychain Mainnet Deployment

### 📋 Network Specifications

| Parameter | Value |
|-----------|-------|
| **Network Name** | Verychain |
| **Chain ID** | 4613 |
| **Currency Symbol** | VERY |
| **Block Time** | 12 seconds |
| **Consensus** | Proof of Authority (PoA) |
| **Block Size** | 8,000,000 gas per block |
| **Gas Limit** | 8,000,000 (Genesis) |
| **Min Gas Price** | 1 Gwei |
| **Max Gas Price** | 500 Gwei |
| **RPC Endpoint** | https://rpc.verylabs.io |
| **Explorer** | https://veryscan.io |

### 🚀 Mainnet Deployment Setup

#### 1️⃣ Environment Variables
Copy the example environment file and configure it:
```bash
# Copy example environment file
cp env.example .env

# Edit .env file with your values
# .env
PRIVATE_KEY=your_private_key_here
VERYCHAIN_RPC_URL=https://rpc.verylabs.io
VERYCHAIN_CHAIN_ID=4613
```

#### 2️⃣ Update Hardhat Configuration
```typescript
// hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    hardhat: {
      // Local development network
    },
    verychain: {
      url: process.env.VERYCHAIN_RPC_URL || "https://rpc.verylabs.io",
      chainId: parseInt(process.env.VERYCHAIN_CHAIN_ID || "4613"),
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 1000000000, // 1 Gwei
    }
  }
};

export default config;
```

#### 3️⃣ Install Dependencies
```bash
# Install dotenv for environment variables
npm install dotenv
```

#### 4️⃣ Deploy to Mainnet
```bash
# Deploy to Verychain mainnet
npx hardhat run deploy-hackathon.js --network verychain
```

### ⚠️ Important Notes
- **Gas Fees**: Real VERY tokens will be spent on gas fees
- **Private Key Security**: Never commit your private key to version control
- **Testing**: Always test on local network first
- **Explorer**: View your deployed contracts at https://veryscan.io

### 🔍 Viewing Deployed Contracts
After deployment, you can view your contracts on the Verychain explorer:
- **Mainnet Explorer**: https://veryscan.io
- **Search by Contract Address**: Paste your deployed contract address
- **Transaction History**: View all interactions with your contracts
- **Source Code Verification**: Verify your contract source code on the explorer

---

## 🔗 Network Configuration

### Development Environment
```yaml
Network: Local Hardhat
RPC URL: http://192.168.31.172:8545
Chain ID: 1337
Currency: ETH (Test)
Gas: Free
```

### Production Environment (Verychain Mainnet)
```yaml
Network: Verychain
RPC URL: https://rpc.verylabs.io
Chain ID: 4613
Currency: VERY Token
Gas: 1-500 Gwei
Block Time: 12 seconds
Explorer: https://veryscan.io
```

---

## 📋 Contract Addresses

### Smart Contracts
| Contract | Address | Description |
|----------|---------|-------------|
| **StrideonScores** | `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` | Main game contract |
| **VERY Token** | `0x5FbDB2315678afecb367f032d93F642f64180aa3` | Game currency |
| **Price Oracle** | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | Price feed |

### Test Accounts
20 pre-funded accounts with 10,000 ETH each for testing:

```javascript
// Example test account
const testAccount = {
    address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    privateKey: '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
    balance: '10000 ETH'
};
```

---

## 📁 Project Structure

```
strideon-scores/
├── 📱 mobile-app-integration.js      # Mobile app integration
├── 🐍 python-backend-integration.py  # Python backend
├── 📋 contract-abis.js              # Contract ABIs
├── 📖 FULL_INTEGRATION_GUIDE.md     # Complete setup guide
├── 🌐 env.example                   # Environment variables template
├── 🎮 contracts/
│   ├── StrideonScores.sol           # Main game contract
│   ├── MockERC20.sol                # Mock VERY token
│   └── MockAggregatorV3.sol         # Mock price oracle
├── ⚙️ hardhat.config.ts             # Hardhat configuration
├── 🚀 deploy-hackathon.js           # Deployment script
└── 📄 *.json                        # Contract ABIs
```

---

## 🛠️ Development

### Smart Contract Development
```bash
# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to local network (development)
npx hardhat run deploy-hackathon.js --network hardhat

# Deploy to Verychain mainnet (production)
npx hardhat run deploy-hackathon.js --network verychain
```

### Backend Development
```bash
# Install dependencies
pip install web3 flask requests

# Run backend
python python-backend-integration.py

# Test API endpoints
curl http://localhost:5000/api/leaderboard
```

### Mobile App Development
```javascript
// Import mobile integration
import { StrideonScoresMobile } from './mobile-app-integration.js';

// Initialize app
const mobileApp = new StrideonScoresMobile();

// Connect wallet
await mobileApp.connectWallet(privateKey);

// Get player score
const score = await mobileApp.getPlayerScore();
```

---

## 🔧 Troubleshooting

### Common Issues

#### ❌ "Cannot connect to network"
```bash
# Check if Hardhat node is running
npx hardhat node --hostname 0.0.0.0 --port 8545
```

#### ❌ "Contract not found"
```bash
# Redeploy contracts
npx hardhat run deploy-hackathon.js --network hardhat
```

#### ❌ "Mobile app can't connect"
```bash
# Check your IP address
ipconfig

# Update mobile app with correct IP
const rpcUrl = 'http://YOUR_IP:8545';
```

#### ❌ "Python backend errors"
```bash
# Install dependencies
pip install web3 flask requests

# Check network connection
python -c "from web3 import Web3; w3 = Web3(Web3.HTTPProvider('http://192.168.31.172:8545')); print(w3.is_connected())"
```

---

## 📖 Documentation

- 📋 **[Full Integration Guide](FULL_INTEGRATION_GUIDE.md)** - Complete setup instructions
- 📱 **[Mobile Integration](mobile-app-integration.js)** - Mobile app code examples
- 🐍 **[Python Backend](python-backend-integration.py)** - Backend implementation
- 📄 **[Contract ABIs](contract-abis.js)** - Smart contract interfaces

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Very Network** - For providing the blockchain infrastructure
- **Hardhat** - For the excellent development framework
- **OpenZeppelin** - For secure smart contract libraries
- **Chainlink** - For oracle integration

---

<div align="center">

**🏃‍♂️ Ready to start earning while moving? Let's build the future of fitness! 🚀**

[Get Started](#-quick-start) • [View Documentation](FULL_INTEGRATION_GUIDE.md) • [Report Issues](https://github.com/your-repo/issues)

</div>

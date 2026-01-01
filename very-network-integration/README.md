# Very Network Integration

## 🌐 Overview

The Very Network Integration module provides seamless cross-chain functionality for the StrideOn platform, enabling VERY token movement between Signify Mainnet and Very Network, liquidity pool management, and DeFi ecosystem integration.

## 🏗 Architecture

### Tech Stack
- **Runtime**: Node.js 18+
- **Framework**: Express.js + TypeScript
- **Blockchain**: Web3.js + Ethers.js
- **Database**: MongoDB (for bridge state)
- **Queue System**: Redis + Bull
- **Testing**: Jest + Supertest
- **Deployment**: Docker + Kubernetes

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Signify       │    │   Bridge        │    │   Very Network  │
│   Mainnet       │◄──►│   Service       │◄──►│   (Ethereum)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Liquidity     │    │   DeFi          │    │   NFT           │
│   Pools         │◄──►│   Services      │◄──►│   Marketplace   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Project Structure
```
very-network-integration/
├── src/
│   ├── index.ts                 # Application entry point
│   ├── config/
│   │   ├── index.ts             # Configuration management
│   │   ├── networks.ts          # Network configurations
│   │   └── contracts.ts         # Contract addresses and ABIs
│   ├── services/
│   │   ├── bridge/
│   │   │   ├── index.ts         # Bridge service main
│   │   │   ├── signify.ts       # Signify network operations
│   │   │   ├── very.ts          # Very network operations
│   │   │   └── validator.ts     # Bridge validation logic
│   │   ├── liquidity/
│   │   │   ├── index.ts         # Liquidity pool management
│   │   │   ├── pools.ts         # Pool operations
│   │   │   └── rewards.ts       # Yield farming rewards
│   │   ├── defi/
│   │   │   ├── index.ts         # DeFi services
│   │   │   ├── staking.ts       # Staking operations
│   │   │   └── lending.ts       # Lending protocols
│   │   └── nft/
│   │       ├── index.ts         # NFT marketplace
│   │       ├── minting.ts       # NFT minting
│   │       └── trading.ts       # NFT trading
│   ├── models/
│   │   ├── BridgeTransaction.ts # Bridge transaction model
│   │   ├── LiquidityPool.ts     # Liquidity pool model
│   │   └── NFT.ts               # NFT model
│   ├── utils/
│   │   ├── web3.ts              # Web3 utility functions
│   │   ├── crypto.ts            # Cryptographic utilities
│   │   └── validators.ts        # Data validation
│   └── api/
│       ├── routes/
│       │   ├── bridge.ts        # Bridge API routes
│       │   ├── liquidity.ts     # Liquidity API routes
│       │   └── nft.ts           # NFT API routes
│       └── middleware/
│           ├── auth.ts          # Authentication middleware
│           └── validation.ts    # Request validation
├── contracts/
│   ├── VeryToken.sol            # VERY token contract
│   ├── Bridge.sol               # Cross-chain bridge
│   ├── LiquidityPool.sol        # Liquidity pool contract
│   └── NFTMarketplace.sol       # NFT marketplace contract
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── scripts/
│   ├── deploy.ts                # Contract deployment
│   ├── setup.ts                 # Initial setup
│   └── migrate.ts               # Data migration
├── package.json
├── tsconfig.json
├── .env.example
├── docker-compose.yml
└── Dockerfile
```

## 🚀 Installation & Setup

### Prerequisites
- Node.js 18+
- MongoDB 5.0+
- Redis 7.0+
- Docker (optional)

### Quick Start

1. **Clone and Install Dependencies**
```bash
cd very-network-integration
npm install
```

2. **Configure Environment**
```bash
cp .env.example .env
# Edit .env with your configuration
nano .env
```

3. **Setup Database**
```bash
npm run setup:db
```

4. **Start Services**
```bash
npm run dev
```

### Environment Configuration

#### Required Environment Variables
```env
# Network Configuration
SIGNIFY_RPC_URL=https://rpc.signify.network
SIGNIFY_CHAIN_ID=1337
SIGNIFY_PRIVATE_KEY=your-signify-private-key

VERY_NETWORK_RPC_URL=https://rpc.very.network
VERY_NETWORK_CHAIN_ID=1234
VERY_NETWORK_PRIVATE_KEY=your-very-private-key

# Contract Addresses
VERY_TOKEN_CONTRACT=0x1234567890123456789012345678901234567890
BRIDGE_CONTRACT=0x1234567890123456789012345678901234567890
LIQUIDITY_POOL_CONTRACT=0x1234567890123456789012345678901234567890
NFT_MARKETPLACE_CONTRACT=0x1234567890123456789012345678901234567890

# Bridge Configuration
BRIDGE_GAS_LIMIT=500000
BRIDGE_CONFIRMATION_BLOCKS=12
BRIDGE_TIMEOUT=3600

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/very_network
REDIS_URL=redis://localhost:6379

# Security
JWT_SECRET=your-jwt-secret
ENCRYPTION_KEY=your-encryption-key

# API Configuration
API_PORT=3000
API_HOST=0.0.0.0
CORS_ORIGIN=http://localhost:3000
```

## 🌉 Cross-Chain Bridge

### Bridge Service
```typescript
import { BridgeService } from './services/bridge';

class BridgeService {
  private signifyProvider: ethers.providers.JsonRpcProvider;
  private veryProvider: ethers.providers.JsonRpcProvider;
  private bridgeContract: ethers.Contract;

  constructor() {
    this.signifyProvider = new ethers.providers.JsonRpcProvider(
      process.env.SIGNIFY_RPC_URL
    );
    this.veryProvider = new ethers.providers.JsonRpcProvider(
      process.env.VERY_NETWORK_RPC_URL
    );
    this.bridgeContract = new ethers.Contract(
      process.env.BRIDGE_CONTRACT!,
      BRIDGE_ABI,
      this.signifyProvider
    );
  }

  async bridgeTokens(
    fromNetwork: 'signify' | 'very',
    toNetwork: 'signify' | 'very',
    amount: string,
    recipient: string
  ): Promise<BridgeTransaction> {
    // Validate networks
    if (fromNetwork === toNetwork) {
      throw new Error('Cannot bridge to same network');
    }

    // Create bridge transaction
    const transaction = new BridgeTransaction({
      fromNetwork,
      toNetwork,
      amount,
      recipient,
      status: 'pending',
      timestamp: new Date()
    });

    // Lock tokens on source network
    if (fromNetwork === 'signify') {
      await this.lockTokensOnSignify(amount, recipient);
    } else {
      await this.lockTokensOnVery(amount, recipient);
    }

    // Save transaction
    await transaction.save();

    // Queue for processing on destination network
    await this.queueBridgeTransaction(transaction);

    return transaction;
  }

  private async lockTokensOnSignify(amount: string, recipient: string) {
    const wallet = new ethers.Wallet(
      process.env.SIGNIFY_PRIVATE_KEY!,
      this.signifyProvider
    );

    const tx = await this.bridgeContract
      .connect(wallet)
      .lockTokens(amount, recipient, {
        gasLimit: process.env.BRIDGE_GAS_LIMIT
      });

    await tx.wait();
  }

  private async lockTokensOnVery(amount: string, recipient: string) {
    // Similar implementation for Very Network
  }

  async processBridgeTransaction(transactionId: string) {
    const transaction = await BridgeTransaction.findById(transactionId);
    if (!transaction) {
      throw new Error('Transaction not found');
    }

    // Verify lock on source network
    const isLocked = await this.verifyLock(
      transaction.fromNetwork,
      transaction.amount,
      transaction.recipient
    );

    if (!isLocked) {
      throw new Error('Tokens not locked on source network');
    }

    // Release tokens on destination network
    await this.releaseTokens(
      transaction.toNetwork,
      transaction.amount,
      transaction.recipient
    );

    // Update transaction status
    transaction.status = 'completed';
    transaction.completedAt = new Date();
    await transaction.save();
  }
}
```

### Bridge API Endpoints
```typescript
import express from 'express';
import { BridgeService } from '../services/bridge';

const router = express.Router();
const bridgeService = new BridgeService();

// Initiate bridge transaction
router.post('/bridge', async (req, res) => {
  try {
    const { fromNetwork, toNetwork, amount, recipient } = req.body;
    
    const transaction = await bridgeService.bridgeTokens(
      fromNetwork,
      toNetwork,
      amount,
      recipient
    );

    res.json({
      success: true,
      transactionId: transaction._id,
      status: transaction.status
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

// Get bridge transaction status
router.get('/bridge/:transactionId', async (req, res) => {
  try {
    const transaction = await BridgeTransaction.findById(req.params.transactionId);
    
    if (!transaction) {
      return res.status(404).json({
        success: false,
        error: 'Transaction not found'
      });
    }

    res.json({
      success: true,
      transaction
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;
```

## 💧 Liquidity Pools

### Liquidity Pool Management
```typescript
import { LiquidityPoolService } from './services/liquidity';

class LiquidityPoolService {
  private poolContract: ethers.Contract;

  constructor() {
    this.poolContract = new ethers.Contract(
      process.env.LIQUIDITY_POOL_CONTRACT!,
      LIQUIDITY_POOL_ABI,
      this.veryProvider
    );
  }

  async addLiquidity(
    veryAmount: string,
    ethAmount: string,
    provider: string
  ): Promise<LiquidityPool> {
    const wallet = new ethers.Wallet(
      process.env.VERY_NETWORK_PRIVATE_KEY!,
      this.veryProvider
    );

    // Approve tokens
    await this.approveTokens(veryAmount, provider);

    // Add liquidity
    const tx = await this.poolContract
      .connect(wallet)
      .addLiquidity(veryAmount, ethAmount, {
        gasLimit: 500000
      });

    await tx.wait();

    // Create pool record
    const pool = new LiquidityPool({
      provider,
      veryAmount,
      ethAmount,
      lpTokens: this.calculateLPTokens(veryAmount, ethAmount),
      timestamp: new Date()
    });

    await pool.save();
    return pool;
  }

  async removeLiquidity(
    lpTokens: string,
    provider: string
  ): Promise<LiquidityPool> {
    const wallet = new ethers.Wallet(
      process.env.VERY_NETWORK_PRIVATE_KEY!,
      this.veryProvider
    );

    // Remove liquidity
    const tx = await this.poolContract
      .connect(wallet)
      .removeLiquidity(lpTokens, {
        gasLimit: 500000
      });

    await tx.wait();

    // Update pool record
    const pool = await LiquidityPool.findOne({ provider });
    if (pool) {
      pool.lpTokens = '0';
      pool.removedAt = new Date();
      await pool.save();
    }

    return pool;
  }

  async getPoolStats(): Promise<PoolStats> {
    const totalSupply = await this.poolContract.totalSupply();
    const veryReserve = await this.poolContract.getVeryReserve();
    const ethReserve = await this.poolContract.getEthReserve();

    return {
      totalSupply: totalSupply.toString(),
      veryReserve: veryReserve.toString(),
      ethReserve: ethReserve.toString(),
      veryPrice: this.calculatePrice(veryReserve, ethReserve)
    };
  }
}
```

## 🏦 DeFi Services

### Staking Service
```typescript
import { StakingService } from './services/defi/staking';

class StakingService {
  private stakingContract: ethers.Contract;

  constructor() {
    this.stakingContract = new ethers.Contract(
      process.env.STAKING_CONTRACT!,
      STAKING_ABI,
      this.veryProvider
    );
  }

  async stakeTokens(amount: string, user: string): Promise<StakingPosition> {
    const wallet = new ethers.Wallet(
      process.env.VERY_NETWORK_PRIVATE_KEY!,
      this.veryProvider
    );

    // Approve tokens for staking
    await this.approveTokens(amount, user);

    // Stake tokens
    const tx = await this.stakingContract
      .connect(wallet)
      .stake(amount, {
        gasLimit: 300000
      });

    await tx.wait();

    // Create staking position
    const position = new StakingPosition({
      user,
      amount,
      startTime: new Date(),
      rewards: '0'
    });

    await position.save();
    return position;
  }

  async claimRewards(user: string): Promise<string> {
    const wallet = new ethers.Wallet(
      process.env.VERY_NETWORK_PRIVATE_KEY!,
      this.veryProvider
    );

    // Calculate rewards
    const rewards = await this.stakingContract.calculateRewards(user);

    // Claim rewards
    const tx = await this.stakingContract
      .connect(wallet)
      .claimRewards({
        gasLimit: 200000
      });

    await tx.wait();

    return rewards.toString();
  }

  async getStakingStats(user: string): Promise<StakingStats> {
    const stakedAmount = await this.stakingContract.stakedBalance(user);
    const rewards = await this.stakingContract.calculateRewards(user);
    const apy = await this.stakingContract.getAPY();

    return {
      stakedAmount: stakedAmount.toString(),
      rewards: rewards.toString(),
      apy: apy.toString()
    };
  }
}
```

## 🎨 NFT Marketplace

### NFT Service
```typescript
import { NFTService } from './services/nft';

class NFTService {
  private nftContract: ethers.Contract;

  constructor() {
    this.nftContract = new ethers.Contract(
      process.env.NFT_MARKETPLACE_CONTRACT!,
      NFT_MARKETPLACE_ABI,
      this.veryProvider
    );
  }

  async mintNFT(
    tokenURI: string,
    creator: string,
    metadata: NFTMetadata
  ): Promise<NFT> {
    const wallet = new ethers.Wallet(
      process.env.VERY_NETWORK_PRIVATE_KEY!,
      this.veryProvider
    );

    // Mint NFT
    const tx = await this.nftContract
      .connect(wallet)
      .mint(tokenURI, creator, {
        gasLimit: 400000
      });

    const receipt = await tx.wait();
    const tokenId = this.extractTokenId(receipt);

    // Create NFT record
    const nft = new NFT({
      tokenId,
      tokenURI,
      creator,
      metadata,
      mintedAt: new Date()
    });

    await nft.save();
    return nft;
  }

  async listNFT(
    tokenId: string,
    price: string,
    seller: string
  ): Promise<NFTListing> {
    const wallet = new ethers.Wallet(
      process.env.VERY_NETWORK_PRIVATE_KEY!,
      this.veryProvider
    );

    // Approve NFT for marketplace
    await this.approveNFT(tokenId, seller);

    // List NFT
    const tx = await this.nftContract
      .connect(wallet)
      .listNFT(tokenId, price, {
        gasLimit: 300000
      });

    await tx.wait();

    // Create listing record
    const listing = new NFTListing({
      tokenId,
      price,
      seller,
      listedAt: new Date(),
      status: 'active'
    });

    await listing.save();
    return listing;
  }

  async buyNFT(tokenId: string, buyer: string, price: string): Promise<NFTTransaction> {
    const wallet = new ethers.Wallet(
      process.env.VERY_NETWORK_PRIVATE_KEY!,
      this.veryProvider
    );

    // Buy NFT
    const tx = await this.nftContract
      .connect(wallet)
      .buyNFT(tokenId, {
        value: price,
        gasLimit: 300000
      });

    await tx.wait();

    // Create transaction record
    const transaction = new NFTTransaction({
      tokenId,
      buyer,
      seller: await this.nftContract.ownerOf(tokenId),
      price,
      transactionHash: tx.hash,
      timestamp: new Date()
    });

    await transaction.save();
    return transaction;
  }
}
```

## 🧪 Testing

### Unit Tests
```typescript
import { BridgeService } from '../services/bridge';
import { LiquidityPoolService } from '../services/liquidity';

describe('BridgeService', () => {
  let bridgeService: BridgeService;

  beforeEach(() => {
    bridgeService = new BridgeService();
  });

  test('should bridge tokens from Signify to Very Network', async () => {
    const transaction = await bridgeService.bridgeTokens(
      'signify',
      'very',
      '1000000000000000000', // 1 VERY
      '0x1234567890123456789012345678901234567890'
    );

    expect(transaction.fromNetwork).toBe('signify');
    expect(transaction.toNetwork).toBe('very');
    expect(transaction.status).toBe('pending');
  });
});

describe('LiquidityPoolService', () => {
  let liquidityService: LiquidityPoolService;

  beforeEach(() => {
    liquidityService = new LiquidityPoolService();
  });

  test('should add liquidity to pool', async () => {
    const pool = await liquidityService.addLiquidity(
      '1000000000000000000', // 1 VERY
      '1000000000000000000', // 1 ETH
      '0x1234567890123456789012345678901234567890'
    );

    expect(pool.veryAmount).toBe('1000000000000000000');
    expect(pool.ethAmount).toBe('1000000000000000000');
  });
});
```

### Integration Tests
```typescript
import request from 'supertest';
import app from '../src/app';

describe('Bridge API', () => {
  test('POST /api/bridge should create bridge transaction', async () => {
    const response = await request(app)
      .post('/api/bridge')
      .send({
        fromNetwork: 'signify',
        toNetwork: 'very',
        amount: '1000000000000000000',
        recipient: '0x1234567890123456789012345678901234567890'
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.transactionId).toBeDefined();
  });
});
```

## 🚀 Deployment

### Docker Deployment
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

### Docker Compose
```yaml
version: '3.8'
services:
  very-network:
    build: .
    ports:
      - "3000:3000"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/very_network
      - REDIS_URL=redis://redis:6379
    depends_on:
      - mongo
      - redis
  
  mongo:
    image: mongo:5.0
    environment:
      - MONGO_INITDB_DATABASE=very_network
    volumes:
      - mongo_data:/data/db
  
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  mongo_data:
  redis_data:
```

### Production Deployment
```bash
# Install PM2
npm install -g pm2

# Start application
pm2 start ecosystem.config.js

# Monitor application
pm2 monit

# View logs
pm2 logs very-network
```

## 🔮 Future Scope

### Planned Features
- **Multi-chain Support**: Integration with additional blockchains
- **Advanced DeFi**: Lending protocols and derivatives
- **DAO Governance**: Community governance for protocol parameters
- **Cross-chain NFTs**: NFTs that can move between chains
- **Layer 2 Scaling**: Integration with rollups and sidechains

### Technical Improvements
- **Performance**: Optimize for high-frequency transactions
- **Security**: Enhanced security audits and monitoring
- **Scalability**: Horizontal scaling for increased throughput
- **Monitoring**: Advanced analytics and alerting
- **Testing**: Comprehensive test coverage and automation

## 🤝 Contributing

### Development Workflow
1. **Fork** the repository
2. **Create** feature branch: `git checkout -b feature/amazing-feature`
3. **Install** dependencies: `npm install`
4. **Write** tests for new features
5. **Run** tests: `npm test`
6. **Commit** changes: `git commit -m 'Add amazing feature'`
7. **Push** to branch: `git push origin feature/amazing-feature`
8. **Open** Pull Request

### Code Standards
- **TypeScript**: Strict type checking enabled
- **ESLint**: Code linting and formatting
- **Testing**: Minimum 80% test coverage
- **Documentation**: Comprehensive JSDoc comments
- **Security**: Security best practices and audits

## 📚 Resources

### Documentation
- [Very Network Documentation](https://docs.very.network)
- [Ethers.js Documentation](https://docs.ethers.io/)
- [Web3.js Documentation](https://web3js.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)

### Community
- [Very Network Discord](https://discord.gg/verynetwork)
- [Ethereum Community](https://ethereum.org/en/community/)
- [DeFi Community](https://defipulse.com/)

---

**Built with ❤ by the Very Network Integration Team**

## 🏆 StrideonScores Hackathon Integration

### Deployed Contract Addresses (Local Hardhat Network)
- **StrideonScores**: `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`
- **Mock VERY Token**: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- **Mock Price Oracle**: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`
- **Timelock**: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`

### How to Run Simulation
To deploy contracts and simulate gameplay transactions (Approve, Purchase PowerUp, Commit Score):

```bash
npx hardhat run deploy-hackathon.js --network hardhat
```

### Steps Performed
1. **Deploy Mock Token**: Deployed standard ERC20 mock.
2. **Deploy Mock Oracle**: Deployed mock Chainlink AggregatorV3.
3. **Deploy StrideonScores**: Initialized with Token, Timelock, and Oracle.
4. **Simulate Gameplay**:
   - Approved `100 VERY` for game contract.
   - Purchased `Shield` PowerUp (Type 1).
   - Committed a score of `500` points.
   - Verified player score update on-chain.

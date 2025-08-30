// Contract ABIs for StrideonScores Mobile App
// These are the REAL ABIs from deployed contracts

export const STRIDEON_SCORES_ABI = [
  {
    "inputs": [
      {"internalType": "address", "name": "veryTokenAddress", "type": "address"},
      {"internalType": "address", "name": "timelockAddress", "type": "address"},
      {"internalType": "address", "name": "priceOracleAddress", "type": "address"}
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [{"internalType": "address", "name": "owner", "type": "address"}],
    "name": "OwnableInvalidOwner",
    "type": "error"
  },
  {
    "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
    "name": "OwnableUnauthorizedAccount",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "ReentrancyGuardReentrantCall",
    "type": "error"
  },
  {
    "inputs": [{"internalType": "address", "name": "token", "type": "address"}],
    "name": "SafeERC20FailedOperation",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [{"indexed": true, "internalType": "address", "name": "admin", "type": "address"}],
    "name": "AdminAdded",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [{"indexed": true, "internalType": "address", "name": "admin", "type": "address"}],
    "name": "AdminRemoved",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [{"indexed": true, "internalType": "address", "name": "caller", "type": "address"}],
    "name": "AdminRoleGranted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [{"indexed": true, "internalType": "address", "name": "caller", "type": "address"}],
    "name": "AdminRoleRevoked",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "player", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "points", "type": "uint256"}
    ],
    "name": "ScoreClaimed",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "player", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "points", "type": "uint256"},
      {"indexed": false, "internalType": "bytes32", "name": "commitment", "type": "bytes32"}
    ],
    "name": "ScoreCommitted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "player", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "points", "type": "uint256"}
    ],
    "name": "ScoreRevealed",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "player", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "powerUpType", "type": "uint256"},
      {"indexed": false, "internalType": "uint256", "name": "price", "type": "uint256"}
    ],
    "name": "PowerUpPurchased",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "player", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256"}
    ],
    "name": "TokensWithdrawn",
    "type": "event"
  },
  {
    "inputs": [{"internalType": "address", "name": "admin", "type": "address"}],
    "name": "addAdmin",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "amount", "type": "uint256"}],
    "name": "emergencyWithdraw",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "player", "type": "address"}],
    "name": "getActivePowerUps",
    "outputs": [
      {"internalType": "uint256[]", "name": "powerUpTypes", "type": "uint256[]"},
      {"internalType": "uint256[]", "name": "counts", "type": "uint256[]"},
      {"internalType": "uint256[]", "name": "expirationTimes", "type": "uint256[]"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "count", "type": "uint256"}],
    "name": "getLeaderboard",
    "outputs": [
      {"internalType": "address[]", "name": "addresses", "type": "address[]"},
      {"internalType": "uint256[]", "name": "scores", "type": "uint256[]"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "player", "type": "address"}],
    "name": "getPlayerScore",
    "outputs": [{"internalType": "uint256", "name": "score", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "player", "type": "address"}],
    "name": "calculateTimeWeightedScore",
    "outputs": [{"internalType": "uint256", "name": "twas", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "player", "type": "address"}, {"internalType": "uint256", "name": "powerUpType", "type": "uint256"}],
    "name": "isPowerUpActive",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "powerUpType", "type": "uint256"}, {"internalType": "uint256", "name": "maxPrice", "type": "uint256"}],
    "name": "purchasePowerUp",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "admin", "type": "address"}],
    "name": "removeAdmin",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "points", "type": "uint256"}, {"internalType": "bytes32", "name": "secret", "type": "bytes32"}],
    "name": "revealScoreUpdate",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "powerUpType", "type": "uint256"}, {"internalType": "uint256", "name": "newPrice", "type": "uint256"}],
    "name": "setPowerUpPrice",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "newOracle", "type": "address"}],
    "name": "setPriceOracle",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "newTopN", "type": "uint256"}],
    "name": "setTopNWinners",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "claimPlayerScore",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "requestWithdrawTokens",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "player", "type": "address"}, {"internalType": "uint256", "name": "points", "type": "uint256"}, {"internalType": "uint8", "name": "v", "type": "uint8"}, {"internalType": "bytes32", "name": "r", "type": "bytes32"}, {"internalType": "bytes32", "name": "s", "type": "bytes32"}],
    "name": "commitScoreUpdate",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address[]", "name": "players", "type": "address[]"}, {"internalType": "uint256[]", "name": "points", "type": "uint256[]"}, {"internalType": "bytes32[]", "name": "secrets", "type": "bytes32[]"}],
    "name": "revealBatchScoreUpdates",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "referrer", "type": "address"}, {"internalType": "address", "name": "referee", "type": "address"}, {"internalType": "uint256", "name": "points", "type": "uint256"}],
    "name": "recordReferral",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

export const VERY_TOKEN_ABI = [
  {
    "inputs": [
      {"internalType": "string", "name": "name", "type": "string"},
      {"internalType": "string", "name": "symbol", "type": "string"}
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "spender", "type": "address"},
      {"internalType": "uint256", "name": "allowance", "type": "uint256"},
      {"internalType": "uint256", "name": "needed", "type": "uint256"}
    ],
    "name": "ERC20InsufficientAllowance",
    "type": "error"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "sender", "type": "address"},
      {"internalType": "uint256", "name": "balance", "type": "uint256"},
      {"internalType": "uint256", "name": "needed", "type": "uint256"}
    ],
    "name": "ERC20InsufficientBalance",
    "type": "error"
  },
  {
    "inputs": [{"internalType": "address", "name": "approver", "type": "address"}],
    "name": "ERC20InvalidApprover",
    "type": "error"
  },
  {
    "inputs": [{"internalType": "address", "name": "receiver", "type": "address"}],
    "name": "ERC20InvalidReceiver",
    "type": "error"
  },
  {
    "inputs": [{"internalType": "address", "name": "sender", "type": "address"}],
    "name": "ERC20InvalidSender",
    "type": "error"
  },
  {
    "inputs": [{"internalType": "address", "name": "spender", "type": "address"}],
    "name": "ERC20InvalidSpender",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "owner", "type": "address"},
      {"indexed": true, "internalType": "address", "name": "spender", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "value", "type": "uint256"}
    ],
    "name": "Approval",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "internalType": "address", "name": "from", "type": "address"},
      {"indexed": true, "internalType": "address", "name": "to", "type": "address"},
      {"indexed": false, "internalType": "uint256", "name": "value", "type": "uint256"}
    ],
    "name": "Transfer",
    "type": "event"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "owner", "type": "address"},
      {"internalType": "address", "name": "spender", "type": "address"}
    ],
    "name": "allowance",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "spender", "type": "address"},
      {"internalType": "uint256", "name": "value", "type": "uint256"}
    ],
    "name": "approve",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "decimals",
    "outputs": [{"internalType": "uint8", "name": "", "type": "uint8"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "name",
    "outputs": [{"internalType": "string", "name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "symbol",
    "outputs": [{"internalType": "string", "name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "totalSupply",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "value", "type": "uint256"}
    ],
    "name": "transfer",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "from", "type": "address"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "value", "type": "uint256"}
    ],
    "name": "transferFrom",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

// Contract Addresses
export const CONTRACT_ADDRESSES = {
  VERY_TOKEN: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
  STRIDEON_SCORES: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
  PRICE_ORACLE: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512'
};

// Network Configuration
export const NETWORK_CONFIG = {
  name: 'Local Hardhat',
  rpcUrl: 'http://192.168.31.172:8545', // or 'http://localhost:8545'
  chainId: 1337,
  currencySymbol: 'ETH'
};

// Test Accounts
export const TEST_ACCOUNTS = {
  ACCOUNT_1: {
    address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    privateKey: '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
    balance: '10000 ETH'
  },
  ACCOUNT_2: {
    address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    privateKey: '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
    balance: '10000 ETH'
  }
};

// Power-up Types
export const POWER_UP_TYPES = {
  SHIELD: 1,
  GHOST_MODE: 2,
  SPEED_BOOST: 3
};

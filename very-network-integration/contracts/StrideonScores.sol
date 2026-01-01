// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "./ABDKMath64x64.sol";
import "./MockAggregatorV3.sol"; // Using Mock for Hackathon

/**
 * @title StrideonScores
 * @notice The core logic for StrideOn Economy.
 */
contract StrideonScores is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ABDKMath64x64 for int128;

    // --- State Variables ---
    IERC20 public immutable _veryToken;
    address public immutable timelock;
    AggregatorV3Interface public priceOracle;
    
    bool public paused;
    bool public emergencyPaused;
    
    // Game Constants
    uint256 public constant POWER_UP_DURATION = 5 minutes;
    uint256 public constant COOLDOWN_PERIOD = 1 minutes;
    uint256 public constant SCORE_DECAY_INTERVAL = 1 days;
    uint256 public constant SCORE_DECAY_PERCENT = 10;
    uint256 public constant MAX_LEADERBOARD_SIZE = 100;
    
    // Structs
    struct PlayerData {
        uint256 score;
        uint256 lastActiveTimestamp;
        uint256 timeWeightedScore;
    }
    
    struct PowerUp {
        uint256 count;
        uint256 lastPurchaseTimestamp;
        uint256 expirationTimestamp;
    }

    struct LeaderboardEntry {
        address player;
        uint256 score;
    }

    // Mappings
    mapping(address => PlayerData) public playerData;
    mapping(address => mapping(uint256 => PowerUp)) public activePowerUps;
    mapping(uint256 => uint256) public powerUpPrices;
    LeaderboardEntry[] public leaderboard;
    mapping(address => bool) public gameAdmins;
    
    // Signature Handling
    struct ScoreCommitment {
        bytes32 commitment;
        uint256 timestamp;
        address player;
    }
    mapping(address => ScoreCommitment) public scoreCommitments;
    mapping(address => uint256) public pendingScores;

    // Power-up Types
    uint256 public constant SHIELD = 1;
    uint256 public constant GHOST_MODE = 2;
    uint256 public constant SPEED_BOOST = 3;

    // Events
    event ScoreUpdated(address indexed player, uint256 newTotalScore);
    event PowerUpPurchased(address indexed player, uint256 powerUpType, uint256 count);
    event PowerUpPriceUpdated(uint256 indexed powerUpType, uint256 newPrice);

    // Modifiers
    modifier whenNotPaused() {
        require(!paused && !emergencyPaused, "Strideon: Paused");
        _;
    }

    /**
     * @dev Initialize with Token, Timelock, and Oracle.
     */
    constructor(
        address veryTokenAddress, 
        address timelockAddress, 
        address priceOracleAddress
    ) Ownable(msg.sender) {
        _veryToken = IERC20(veryTokenAddress);
        timelock = timelockAddress;
        priceOracle = AggregatorV3Interface(priceOracleAddress);
        
        gameAdmins[msg.sender] = true;
        
        // Default Prices (in Wei)
        powerUpPrices[SHIELD] = 10 * 10**18;      // 10 VERY
        powerUpPrices[GHOST_MODE] = 25 * 10**18;  // 25 VERY
        powerUpPrices[SPEED_BOOST] = 15 * 10**18; // 15 VERY
    }

    // --- Core Game Functions ---

    /**
     * @notice Purchase a power-up using VERY tokens.
     */
    function purchasePowerUp(uint256 powerUpType) public whenNotPaused nonReentrant {
        require(powerUpType >= 1 && powerUpType <= 3, "Invalid Type");
        uint256 price = powerUpPrices[powerUpType];
        require(price > 0, "Not available");

        // Transfer VERY from user to contract (Revenue Sink)
        _veryToken.safeTransferFrom(msg.sender, address(this), price);

        activePowerUps[msg.sender][powerUpType].count += 1;
        activePowerUps[msg.sender][powerUpType].lastPurchaseTimestamp = block.timestamp;
        activePowerUps[msg.sender][powerUpType].expirationTimestamp = block.timestamp + POWER_UP_DURATION;

        emit PowerUpPurchased(msg.sender, powerUpType, activePowerUps[msg.sender][powerUpType].count);
    }

    /**
     * @notice Admin function to distribute rewards to winners.
     */
    function distributePrize(address winner, uint256 amount) public whenNotPaused nonReentrant {
        require(gameAdmins[msg.sender], "Only Admin");
        require(amount <= _veryToken.balanceOf(address(this)), "Insufficient Vault Balance");
        
        _veryToken.safeTransfer(winner, amount);
    }

    /**
     * @notice Commit a score (Step 1 of Anti-Cheat).
     */
    function commitScoreUpdate(address player, uint256 points, uint8 v, bytes32 r, bytes32 s) public whenNotPaused {
        // Recover signer from signature (Simulated for Hackathon: Assume signer is Admin)
        // In prod: verify ecrecover(hash, v, r, s) == adminSigner
        
        bytes32 commitment = keccak256(abi.encode(player, points, block.timestamp));
        scoreCommitments[player] = ScoreCommitment(commitment, block.timestamp, player);
        pendingScores[player] += points; // Simplified for Hackathon speed
        
        emit ScoreUpdated(player, points);
    }

    // --- View Functions ---

    function getPlayerScore(address player) public view returns (uint256) {
        return playerData[player].score + pendingScores[player];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "./ABDKMath64x64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// For DAO integration (future):
// import "@openzeppelin/contracts/governance/Governor.sol";

/**
 * @title StrideonScores
 * @author [Your Name / Team Name]
 * @notice On-chain trust layer for the Strideon move-to-earn game.
 * Manages player-signed scores, distributes VERY token prizes using automated snapshots,
 * handles power-up purchases with secure oracle, and uses multi-sig timelock.
 */
contract StrideonScores is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ABDKMath64x64 for int128;

    // =================================================================
    //                           STATE VARIABLES
    // =================================================================

    IERC20 private immutable _veryToken;
    address public immutable timelock; // TimelockController (multi-sig)
    AggregatorV3Interface public priceOracle; // Chainlink price feed
    bool public paused;
    bool public emergencyPaused;
    uint256 public constant POWER_UP_DURATION = 5 minutes;
    uint256 public constant COOLDOWN_PERIOD = 1 minutes;
    uint256 public constant SCORE_DECAY_INTERVAL = 1 days;
    uint256 public constant SCORE_DECAY_PERCENT = 10; // 10% decay
    uint256 public constant MAX_LEADERBOARD_SIZE = 100;
    uint256 public constant MAX_BATCH_SIZE = 25;
    uint256 public constant MAX_DECAY_INTERVALS = 30; // Max 30 days
    uint256 public constant REFERRAL_COOLDOWN = 1 days;
    uint256 public constant MIN_REFERRAL_SCORE = 100;
    uint256 public constant SNAPSHOT_INTERVAL = 1 days;
    uint256 public constant HEARTBEAT_TIMEOUT = 24 hours;
    uint256 public constant ORACLE_SLIPPAGE_PERCENT = 5; // 5% slippage tolerance
    uint256 public topNWinners = 5;
    uint256 public currentPoolId;

    // Role-based access control
    mapping(address => bool) public gameAdmins;

    // Player data
    struct PlayerData {
        uint256 score;
        uint256 lastActiveTimestamp;
        uint256 timeWeightedScore; // For TWAS
    }
    mapping(address => PlayerData) public playerData;

    // Active power-ups
    struct PowerUp {
        uint256 count;
        uint256 lastPurchaseTimestamp;
        uint256 expirationTimestamp;
    }
    mapping(address => mapping(uint256 => PowerUp)) public activePowerUps;
    mapping(address => uint256) public lastPurchaseAnyTimestamp;

    // Power-up prices
    mapping(uint256 => uint256) public powerUpPrices;

    // Leaderboard
    struct LeaderboardEntry {
        address player;
        uint256 score;
    }
    LeaderboardEntry[] public leaderboard;
    mapping(uint256 => LeaderboardEntry[]) public leaderboardSnapshot;

    // Prize pool
    struct PrizePool {
        uint256 balance;
        uint256 endTimestamp;
        uint256 lastSnapshotTimestamp;
    }
    mapping(uint256 => PrizePool) public prizePools;
    mapping(uint256 => bool) public usedPoolIds;

    // Withdrawal balances
    mapping(address => uint256) public emergencyWithdrawable;
    uint256 public withdrawableBalance;

    // Referral rewards
    mapping(address => uint256) public referralPoints;
    mapping(address => uint256) public lastReferralTimestamp;

    // Score commitments
    struct ScoreCommitment {
        bytes32 commitment;
        uint256 timestamp;
        address player;
    }
    mapping(address => ScoreCommitment) public scoreCommitments;
    mapping(address => uint256) public pendingScores;

    // Power-up types
    uint256 public constant SHIELD = 1;
    uint256 public constant GHOST_MODE = 2;
    uint256 public constant SPEED_BOOST = 3;

    // =================================================================
    //                                EVENTS
    // =================================================================

    event ScoreUpdated(address indexed player, uint256 newTotalScore);
    event ScoreCommitted(address indexed player, bytes32 commitment);
    event ScoreSignatureVerified(address indexed player, uint256 points);
    event PrizeDistributed(address indexed winner, uint256 amount, uint256 indexed poolId);
    event PowerUpPurchased(address indexed player, uint256 powerUpType, uint256 count, uint256 expiresAt);
    event PowerUpPriceUpdated(uint256 indexed powerUpType, uint256 newPrice);
    event PrizePoolCreated(uint256 indexed poolId, uint256 endTimestamp);
    event PrizePoolFunded(uint256 indexed poolId, uint256 amount);
    event ScoreDecayed(address indexed player, uint256 newScore);
    event ReferralReward(address indexed referrer, address indexed referee, uint256 points);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event EmergencyWithdrawableUpdated(address indexed user, uint256 amount);
    event WithdrawableBalanceUpdated(address indexed owner, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event OwnerWithdraw(address indexed owner, uint256 amount);
    event TopNWinnersUpdated(uint256 newTopN);
    event LeaderboardSnapshotTaken(uint256 indexed poolId, uint256 entries);
    event PriceOracleUpdated(address indexed newOracle);
    event EmergencyPaused(address indexed caller);
    event EmergencyUnpaused(address indexed caller);
    event OraclePriceChecked(uint256 indexed powerUpType, uint256 contractPrice, uint256 oraclePrice);
    event Paused(address indexed caller);
    event Unpaused(address indexed caller);
    event LeaderboardUpdated(address indexed player, uint256 score);

    // =================================================================
    //                               MODIFIERS
    // =================================================================

    modifier onlyAdmin() {
        require(gameAdmins[msg.sender] || msg.sender == owner() || msg.sender == timelock, "Strideon: Not admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused && !emergencyPaused, "Strideon: Contract paused");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "Strideon: Only timelock");
        _;
    }

    // =================================================================
    //                              CONSTRUCTOR
    // =================================================================

    /**
     * @dev Initializes the contract with trusted VERY token, timelock, and price oracle.
     * @param veryTokenAddress Address of the trusted VERY token contract.
     * @param timelockAddress Address of the TimelockController (multi-sig).
     * @param priceOracleAddress Address of the Chainlink price feed.
     */
    constructor(address veryTokenAddress, address timelockAddress, address priceOracleAddress) Ownable(msg.sender) {
        require(veryTokenAddress != address(0), "Strideon: Invalid token address");
        require(timelockAddress != address(0), "Strideon: Invalid timelock address");
        require(priceOracleAddress != address(0), "Strideon: Invalid oracle address");
        IERC20 token = IERC20(veryTokenAddress);
        require(token.balanceOf(address(this)) >= 0, "Strideon: Invalid token contract");
        _veryToken = token;
        timelock = timelockAddress;
        priceOracle = AggregatorV3Interface(priceOracleAddress);
        gameAdmins[msg.sender] = true;
        paused = false;
        emergencyPaused = false;
        currentPoolId = 0;

        // Initialize power-up prices (18 decimals)
        powerUpPrices[SHIELD] = 10 * 10**18;
        powerUpPrices[GHOST_MODE] = 25 * 10**18;
        powerUpPrices[SPEED_BOOST] = 15 * 10**18;

        // Initialize first prize pool
        currentPoolId = 1;
        prizePools[currentPoolId] = PrizePool(0, block.timestamp + 1 days, block.timestamp);
        usedPoolIds[currentPoolId] = true;
        _takeLeaderboardSnapshot(currentPoolId);
        emit PrizePoolCreated(currentPoolId, block.timestamp + 1 days);
    }

    // =================================================================
    //                        CORE GAME FUNCTIONS
    // =================================================================

    /**
     * @notice Commits a player-signed score update.
     * @param player Player's address.
     * @param points Points to commit.
     * @param v Signature recovery byte.
     * @param r Signature component r.
     * @param s Signature component s.
     */
    function commitScoreUpdate(address player, uint256 points, uint8 v, bytes32 r, bytes32 s) 
        public 
        whenNotPaused 
    {
        require(player != address(0), "Strideon: Invalid player address");
        bytes32 messageHash = keccak256(abi.encode(player, points, block.chainid, address(this)));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        require(ecrecover(ethSignedMessageHash, v, r, s) == player, "Strideon: Invalid signature");
        
        bytes32 commitment = keccak256(abi.encode(player, points, player));
        scoreCommitments[player] = ScoreCommitment(commitment, block.timestamp, player);
        emit ScoreCommitted(player, commitment);
    }

    /**
     * @notice Reveals and applies a committed score update (player-called).
     * @param points Points to add.
     * @param secret Secret used in commitment.
     */
    function revealScoreUpdate(uint256 points, bytes32 secret) 
        public 
        whenNotPaused 
    {
        ScoreCommitment memory commitment = scoreCommitments[msg.sender];
        require(commitment.commitment != bytes32(0), "Strideon: No commitment");
        require(commitment.player == msg.sender, "Strideon: Player mismatch");
        require(commitment.commitment == keccak256(abi.encode(msg.sender, points, msg.sender)), "Strideon: Invalid reveal");
        require(block.timestamp >= commitment.timestamp + 1 hours, "Strideon: Reveal too early");

        pendingScores[msg.sender] += points;
        delete scoreCommitments[msg.sender];
        emit ScoreSignatureVerified(msg.sender, points);
    }

    /**
     * @notice Commits batch score updates (player-signed).
     * @param players Array of player addresses.
     * @param points Array of points.
     * @param secrets Array of secrets.
     */
    function revealBatchScoreUpdates(address[] calldata players, uint256[] calldata points, bytes32[] calldata secrets) 
        external 
        whenNotPaused 
    {
        require(players.length == points.length && players.length == secrets.length, "Strideon: Mismatched arrays");
        require(players.length <= MAX_BATCH_SIZE, "Strideon: Batch size too large");
        require(gasleft() >= 100000 * players.length, "Strideon: Insufficient gas");

        uint256[] memory tempPoints = new uint256[](players.length);
        for (uint256 i = 0; i < players.length; i++) {
            require(players[i] != address(0), "Strideon: Invalid player address");
            ScoreCommitment memory commitment = scoreCommitments[players[i]];
            require(commitment.commitment != bytes32(0), "Strideon: No commitment");
            require(commitment.player == players[i], "Strideon: Player mismatch");
            require(commitment.commitment == keccak256(abi.encode(players[i], points[i], players[i])), "Strideon: Invalid reveal");
            require(block.timestamp >= commitment.timestamp + 1 hours, "Strideon: Reveal too early");
            tempPoints[i] += points[i];
        }

        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            if (tempPoints[i] > 0) {
                pendingScores[player] += tempPoints[i];
                delete scoreCommitments[player];
                emit ScoreSignatureVerified(player, tempPoints[i]);
            }
        }
    }

    /**
     * @notice Allows players to claim their pending scores.
     */
    function claimPlayerScore() 
        public 
        whenNotPaused 
        nonReentrant 
    {
        uint256 points = pendingScores[msg.sender];
        require(points > 0, "Strideon: No pending score");
        _applyScoreDecay(msg.sender);
        playerData[msg.sender].score += points;
        playerData[msg.sender].lastActiveTimestamp = block.timestamp;
        playerData[msg.sender].timeWeightedScore = calculateTimeWeightedScore(msg.sender);
        pendingScores[msg.sender] = 0;
        emit ScoreUpdated(msg.sender, playerData[msg.sender].score);
        _updateLeaderboard(msg.sender, playerData[msg.sender].timeWeightedScore);

        // Check for automatic snapshot
        _checkAndTakeSnapshot(currentPoolId);
    }

    /**
     * @notice Distributes prizes from a pool to top N players in snapshot.
     * @param winner Winner's address.
     * @param amount Amount of VERY tokens.
     * @param poolId Prize pool ID.
     */
    function distributePrize(address winner, uint256 amount, uint256 poolId) 
        public 
        onlyAdmin 
        whenNotPaused 
        nonReentrant 
    {
        require(winner != address(0), "Strideon: Invalid winner address");
        require(amount > 0, "Strideon: Invalid amount");
        require(usedPoolIds[poolId], "Strideon: Invalid pool ID");
        require(prizePools[poolId].endTimestamp > block.timestamp, "Strideon: Pool expired");
        require(prizePools[poolId].balance >= amount, "Strideon: Insufficient pool balance");
        require(leaderboardSnapshot[poolId].length > 0, "Strideon: No snapshot");

        bool isTopN = false;
        uint256 limit = topNWinners > leaderboardSnapshot[poolId].length ? leaderboardSnapshot[poolId].length : topNWinners;
        for (uint256 i = 0; i < limit; i++) {
            if (leaderboardSnapshot[poolId][i].player == winner) {
                isTopN = true;
                break;
            }
        }
        require(isTopN, "Strideon: Winner not in snapshot top N");

        prizePools[poolId].balance -= amount;
        _veryToken.safeTransfer(winner, amount);
        emit PrizeDistributed(winner, amount, poolId);
    }

    /**
     * @notice Purchases a power-up with VERY tokens and oracle check.
     * @param powerUpType Type of power-up (1=Shield, 2=Ghost, 3=Speed).
     * @param maxPrice Maximum price the user is willing to pay.
     */
    function purchasePowerUp(uint256 powerUpType, uint256 maxPrice) 
        public 
        whenNotPaused 
        nonReentrant 
    {
        require(powerUpType == SHIELD || powerUpType == GHOST_MODE || powerUpType == SPEED_BOOST, "Strideon: Invalid power-up type");
        require(block.timestamp >= lastPurchaseAnyTimestamp[msg.sender] + COOLDOWN_PERIOD, "Strideon: Global cooldown active");
        require(block.timestamp >= activePowerUps[msg.sender][powerUpType].lastPurchaseTimestamp + COOLDOWN_PERIOD, "Strideon: Type cooldown active");
        uint256 price = powerUpPrices[powerUpType];
        require(price > 0, "Strideon: Power-up not available");
        require(price <= maxPrice, "Strideon: Price exceeds maxPrice");

        // Chainlink price check
        (, int256 oraclePrice,, uint256 updatedAt,) = priceOracle.latestRoundData();
        require(block.timestamp - updatedAt < HEARTBEAT_TIMEOUT, "Strideon: Stale oracle price");
        uint256 oraclePriceAdjusted = uint256(oraclePrice) * 1e10; // Adjust decimals
        uint256 maxAllowedPrice = oraclePriceAdjusted * (100 + ORACLE_SLIPPAGE_PERCENT) / 100;
        require(price <= maxAllowedPrice, "Strideon: Price exceeds oracle limit");

        _veryToken.safeTransferFrom(msg.sender, address(this), price);

        activePowerUps[msg.sender][powerUpType].count += 1;
        activePowerUps[msg.sender][powerUpType].lastPurchaseTimestamp = block.timestamp;
        lastPurchaseAnyTimestamp[msg.sender] = block.timestamp;
        uint256 expiration = block.timestamp + POWER_UP_DURATION;
        activePowerUps[msg.sender][powerUpType].expirationTimestamp = expiration;
        emit PowerUpPurchased(msg.sender, powerUpType, activePowerUps[msg.sender][powerUpType].count, expiration);
        emit OraclePriceChecked(powerUpType, price, oraclePriceAdjusted);
    }

    /**
     * @notice Records a referral reward with cooldown and minimum score.
     * @param referrer Referrer's address.
     * @param referee New player's address.
     * @param points Points to award.
     */
    function recordReferral(address referrer, address referee, uint256 points) 
        external 
        onlyAdmin 
        whenNotPaused 
    {
        require(referrer != address(0) && referee != address(0), "Strideon: Invalid address");
        require(referrer != referee, "Strideon: Cannot refer self");
        require(block.timestamp >= lastReferralTimestamp[referrer] + REFERRAL_COOLDOWN, "Strideon: Referral cooldown active");
        require(playerData[referee].score >= MIN_REFERRAL_SCORE, "Strideon: Referee score too low");

        referralPoints[referrer] += points;
        emergencyWithdrawable[referrer] += points;
        lastReferralTimestamp[referrer] = block.timestamp;
        emit ReferralReward(referrer, referee, points);
        emit EmergencyWithdrawableUpdated(referrer, emergencyWithdrawable[referrer]);
    }

    /**
     * @notice Allows users to withdraw referral points as VERY tokens.
     * @param amount Amount to withdraw.
     */
    function emergencyWithdraw(uint256 amount) 
        public 
        nonReentrant 
    {
        require(amount > 0 && amount <= emergencyWithdrawable[msg.sender], "Strideon: Invalid amount");
        require(_veryToken.balanceOf(address(this)) >= amount, "Strideon: Insufficient contract balance");
        emergencyWithdrawable[msg.sender] -= amount;
        _veryToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @notice Allows owner to claim withdrawable tokens (timelocked).
     */
    function claimWithdrawableTokens() 
        public 
        onlyTimelock 
        nonReentrant 
    {
        require(withdrawableBalance > 0, "Strideon: No withdrawable tokens");
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        _veryToken.safeTransfer(owner(), amount);
        emit OwnerWithdraw(owner(), amount);
    }

    // =================================================================
    //                          VIEW FUNCTIONS
    // =================================================================

    /**
     * @notice Checks if a power-up is active.
     * @param player Player's address.
     * @param powerUpType Type of power-up.
     * @return bool True if active.
     */
    function isPowerUpActive(address player, uint256 powerUpType) 
        public 
        view 
        returns (bool) 
    {
        return activePowerUps[player][powerUpType].count > 0 && 
               activePowerUps[player][powerUpType].expirationTimestamp > block.timestamp;
    }

    /**
     * @notice Gets all active power-ups for a player.
     * @param player Player's address.
     * @return powerUpTypes Array of active power-up types.
     * @return counts Array of power-up counts.
     * @return expirationTimes Array of expiration timestamps.
     */
    function getActivePowerUps(address player) 
        public 
        view 
        returns (uint256[] memory powerUpTypes, uint256[] memory counts, uint256[] memory expirationTimes) 
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= 3; i++) {
            if (isPowerUpActive(player, i)) {
                count++;
            }
        }

        powerUpTypes = new uint256[](count);
        counts = new uint256[](count);
        expirationTimes = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= 3; i++) {
            if (isPowerUpActive(player, i)) {
                powerUpTypes[index] = i;
                counts[index] = activePowerUps[player][i].count;
                expirationTimes[index] = activePowerUps[player][i].expirationTimestamp;
                index++;
            }
        }
        return (powerUpTypes, counts, expirationTimes);
    }

    /**
     * @notice Gets the current leaderboard.
     * @param count Number of entries (max 50).
     * @return addresses Player addresses.
     * @return scores Player scores.
     */
    function getLeaderboard(uint256 count) 
        public 
        view 
        returns (address[] memory addresses, uint256[] memory scores) 
    {
        uint256 len = count > leaderboard.length ? leaderboard.length : count;
        len = len > 50 ? 50 : len;
        addresses = new address[](len);
        scores = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            addresses[i] = leaderboard[i].player;
            scores[i] = leaderboard[i].score;
        }
        return (addresses, scores);
    }

    /**
     * @notice Gets the snapshot leaderboard for a pool.
     * @param poolId Prize pool ID.
     * @param count Number of entries (max 50).
     * @return addresses Player addresses.
     * @return scores Player scores.
     */
    function getLeaderboardSnapshot(uint256 poolId, uint256 count) 
        public 
        view 
        returns (address[] memory addresses, uint256[] memory scores) 
    {
        uint256 len = count > leaderboardSnapshot[poolId].length ? leaderboardSnapshot[poolId].length : count;
        len = len > 50 ? 50 : len;
        addresses = new address[](len);
        scores = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            addresses[i] = leaderboardSnapshot[poolId][i].player;
            scores[i] = leaderboardSnapshot[poolId][i].score;
        }
        return (addresses, scores);
    }

    /**
     * @notice Gets a player's current score after decay.
     * @param player Player's address.
     * @return score Current score.
     */
    function getPlayerScore(address player) 
        public 
        view 
        returns (uint256 score) 
    {
        uint256 decayedScore = playerData[player].score;
        uint256 intervals = (block.timestamp - playerData[player].lastActiveTimestamp) / SCORE_DECAY_INTERVAL;
        intervals = intervals > MAX_DECAY_INTERVALS ? MAX_DECAY_INTERVALS : intervals;
        if (intervals > 0) {
            int128 decayFactor = ABDKMath64x64.divu(100 - SCORE_DECAY_PERCENT, 100);
            int128 score64x64 = ABDKMath64x64.fromUInt(decayedScore);
            for (uint256 i = 0; i < intervals; i++) {
                score64x64 = ABDKMath64x64.mul(score64x64, decayFactor);
            }
            decayedScore = ABDKMath64x64.toUInt(score64x64);
        }
        return decayedScore + pendingScores[player];
    }

    /**
     * @notice Calculates time-weighted average score.
     * @param player Player's address.
     * @return twas Time-weighted score.
     */
    function calculateTimeWeightedScore(address player) 
        public 
        view 
        returns (uint256 twas) 
    {
        uint256 currentScore = getPlayerScore(player);
        uint256 timeSinceLastUpdate = block.timestamp - playerData[player].lastActiveTimestamp;
        if (timeSinceLastUpdate == 0) return currentScore;
        int128 timeFactor = ABDKMath64x64.divu(timeSinceLastUpdate, SCORE_DECAY_INTERVAL);
        int128 weight = ABDKMath64x64.sub(ABDKMath64x64.fromUInt(1), ABDKMath64x64.mul(timeFactor, ABDKMath64x64.divu(SCORE_DECAY_PERCENT, 100)));
        return ABDKMath64x64.toUInt(ABDKMath64x64.mul(ABDKMath64x64.fromUInt(currentScore), weight));
    }

    // =================================================================
    //                          ADMIN FUNCTIONS
    // =================================================================

    /**
     * @notice Funds a prize pool with VERY tokens.
     * @param poolId Prize pool ID.
     * @param amount Amount of VERY tokens.
     */
    function fundPrizePool(uint256 poolId, uint256 amount) 
        public 
        onlyAdmin 
        whenNotPaused 
        nonReentrant 
    {
        require(amount > 0, "Strideon: Invalid amount");
        require(usedPoolIds[poolId], "Strideon: Invalid pool ID");
        require(prizePools[poolId].endTimestamp > block.timestamp, "Strideon: Pool expired");
        _veryToken.safeTransferFrom(msg.sender, address(this), amount);
        prizePools[poolId].balance += amount;
        emit PrizePoolFunded(poolId, amount);
    }

    /**
     * @notice Creates a new prize pool with sequential ID (timelocked).
     * @param duration Duration of the pool in seconds.
     */
    function createPrizePool(uint256 duration) 
        public 
        onlyTimelock 
    {
        require(duration > 0, "Strideon: Invalid duration");
        require(prizePools[currentPoolId].endTimestamp <= block.timestamp, "Strideon: Previous pool active");

        currentPoolId++;
        require(!usedPoolIds[currentPoolId], "Strideon: Pool ID collision");
        prizePools[currentPoolId] = PrizePool(0, block.timestamp + duration, block.timestamp);
        usedPoolIds[currentPoolId] = true;
        _takeLeaderboardSnapshot(currentPoolId);
        emit PrizePoolCreated(currentPoolId, block.timestamp + duration);
    }

    /**
     * @notice Requests withdrawal of non-prize pool tokens (timelocked).
     */
    function requestWithdrawTokens() 
        public 
        onlyOwner 
    {
        uint256 prizeBalance = 0;
        for (uint256 i = 1; i <= currentPoolId; i++) {
            if (usedPoolIds[i] && prizePools[i].endTimestamp > block.timestamp) {
                prizeBalance += prizePools[i].balance;
            }
        }
        uint256 balance = _veryToken.balanceOf(address(this));
        require(balance > prizeBalance, "Strideon: No withdrawable tokens");
        uint256 withdrawable = balance - prizeBalance;
        withdrawableBalance = withdrawable;
        emit WithdrawableBalanceUpdated(owner(), withdrawable);
    }

    /**
     * @notice Updates power-up price (timelocked).
     * @param powerUpType Power-up type.
     * @param newPrice New price in VERY tokens.
     */
    function setPowerUpPrice(uint256 powerUpType, uint256 newPrice) 
        public 
        onlyTimelock 
    {
        require(powerUpType == SHIELD || powerUpType == GHOST_MODE || powerUpType == SPEED_BOOST, "Strideon: Invalid power-up type");
        powerUpPrices[powerUpType] = newPrice;
        emit PowerUpPriceUpdated(powerUpType, newPrice);
    }

    /**
     * @notice Sets the number of top winners (timelocked).
     * @param newTopN Number of top winners.
     */
    function setTopNWinners(uint256 newTopN) 
        public 
        onlyTimelock 
    {
        require(newTopN > 0 && newTopN <= MAX_LEADERBOARD_SIZE, "Strideon: Invalid top N");
        topNWinners = newTopN;
        emit TopNWinnersUpdated(newTopN);
    }

    /**
     * @notice Adds a game admin (timelocked).
     * @param admin Admin's address.
     */
    function addAdmin(address admin) 
        public 
        onlyTimelock 
    {
        require(admin != address(0), "Strideon: Invalid admin address");
        require(!gameAdmins[admin], "Strideon: Admin exists");
        gameAdmins[admin] = true;
        emit AdminAdded(admin);
    }

    /**
     * @notice Removes a game admin (timelocked).
     * @param admin Admin's address.
     */
    function removeAdmin(address admin) 
        public 
        onlyTimelock 
    {
        require(admin != owner(), "Strideon: Cannot remove owner");
        require(gameAdmins[admin], "Strideon: Not an admin");
        gameAdmins[admin] = false;
        emit AdminRemoved(admin);
    }

    /**
     * @notice Pauses the contract (timelocked).
     */
    function pause() 
        public 
        onlyTimelock 
    {
        require(!paused, "Strideon: Already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract (timelocked).
     */
    function unpause() 
        public 
        onlyTimelock 
    {
        require(paused, "Strideon: Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Emergency pauses all functions except withdrawals (timelocked).
     */
    function emergencyPause() 
        public 
        onlyTimelock 
    {
        require(!emergencyPaused, "Strideon: Already emergency paused");
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender);
    }

    /**
     * @notice Unpauses emergency state (timelocked).
     */
    function emergencyUnpause() 
        public 
        onlyTimelock 
    {
        require(emergencyPaused, "Strideon: Not emergency paused");
        emergencyPaused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    /**
     * @notice Updates price oracle (timelocked).
     * @param newOracle New oracle address.
     */
    function setPriceOracle(address newOracle) 
        public 
        onlyTimelock 
    {
        require(newOracle != address(0), "Strideon: Invalid oracle address");
        priceOracle = AggregatorV3Interface(newOracle);
        emit PriceOracleUpdated(newOracle);
    }

    // =================================================================
    //                          INTERNAL FUNCTIONS
    // =================================================================

    /**
     * @dev Takes a leaderboard snapshot for a pool.
     * @param poolId Prize pool ID.
     */
    function _takeLeaderboardSnapshot(uint256 poolId) 
        internal 
    {
        delete leaderboardSnapshot[poolId];
        uint256 len = leaderboard.length > MAX_LEADERBOARD_SIZE ? MAX_LEADERBOARD_SIZE : leaderboard.length;
        for (uint256 i = 0; i < len; i++) {
            leaderboardSnapshot[poolId].push(leaderboard[i]);
        }
        prizePools[poolId].lastSnapshotTimestamp = block.timestamp;
        emit LeaderboardSnapshotTaken(poolId, len);
    }

    /**
     * @dev Checks and takes a snapshot if interval elapsed.
     * @param poolId Prize pool ID.
     */
    function _checkAndTakeSnapshot(uint256 poolId) 
        internal 
    {
        if (block.timestamp >= prizePools[poolId].lastSnapshotTimestamp + SNAPSHOT_INTERVAL && 
            prizePools[poolId].endTimestamp > block.timestamp) {
            _takeLeaderboardSnapshot(poolId);
        }
    }

    /**
     * @dev Applies score decay using precise math.
     * @param player Player's address.
     */
    function _applyScoreDecay(address player) 
        internal 
    {
        uint256 intervals = (block.timestamp - playerData[player].lastActiveTimestamp) / SCORE_DECAY_INTERVAL;
        intervals = intervals > MAX_DECAY_INTERVALS ? MAX_DECAY_INTERVALS : intervals;
        if (intervals > 0) {
            int128 decayFactor = ABDKMath64x64.divu(100 - SCORE_DECAY_PERCENT, 100);
            int128 score64x64 = ABDKMath64x64.fromUInt(playerData[player].score);
            for (uint256 i = 0; i < intervals; i++) {
                score64x64 = ABDKMath64x64.mul(score64x64, decayFactor);
            }
            uint256 newScore = ABDKMath64x64.toUInt(score64x64);
            if (newScore != playerData[player].score) {
                playerData[player].score = newScore;
                playerData[player].timeWeightedScore = calculateTimeWeightedScore(player);
                emit ScoreDecayed(player, newScore);
            }
        }
    }

    /**
     * @dev Updates the leaderboard with a player's time-weighted score.
     * @param player Player's address.
     * @param score Time-weighted score.
     */
    function _updateLeaderboard(address player, uint256 score) 
        internal 
    {
        require(leaderboard.length <= MAX_LEADERBOARD_SIZE, "Strideon: Leaderboard full");

        for (uint256 i = 0; i < leaderboard.length; i++) {
            if (leaderboard[i].player == player) {
                leaderboard[i] = leaderboard[leaderboard.length - 1];
                leaderboard.pop();
                break;
            }
        }

        if (score > 0) {
            uint256 insertIndex = leaderboard.length;
            for (uint256 i = 0; i < leaderboard.length; i++) {
                if (score > leaderboard[i].score) {
                    insertIndex = i;
                    break;
                }
            }
            leaderboard.push(LeaderboardEntry(address(0), 0));
            for (uint256 i = leaderboard.length - 1; i > insertIndex; i--) {
                leaderboard[i] = leaderboard[i - 1];
            }
            leaderboard[insertIndex] = LeaderboardEntry(player, score);
            emit LeaderboardUpdated(player, score);
        }

        if (leaderboard.length > MAX_LEADERBOARD_SIZE) {
            leaderboard.pop();
        }
    }
}
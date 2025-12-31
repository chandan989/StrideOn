package com.strideon.domain.usecase

import com.strideon.data.repository.GameRepository
import com.strideon.domain.models.*

class GameUseCases(private val repository: GameRepository) {

    // User Management Use Cases
    class GetUserProfileUseCase(private val repository: GameRepository) {
        suspend fun execute(userId: String): Result<User> {
            return try {
                val user = repository.getUserProfile(userId)
                if (user != null) {
                    Result.success(user)
                } else {
                    Result.failure(Exception("User not found"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    class UpdateUserProfileUseCase(private val repository: GameRepository) {
        suspend fun execute(userId: String, username: String?, avatarUrl: String?, city: String?): Result<Boolean> {
            return try {
                val success = repository.updateUserProfile(userId, username, avatarUrl, city)
                Result.success(success)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // Session Management Use Cases
    class StartGameSessionUseCase(private val repository: GameRepository) {
        suspend fun execute(city: String?): Result<GameSession> {
            return try {
                val session = repository.createSession(city)
                if (session != null) {
                    Result.success(session)
                } else {
                    Result.failure(Exception("Failed to create session"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    class EndGameSessionUseCase(private val repository: GameRepository) {
        suspend fun execute(sessionId: String): Result<Boolean> {
            return try {
                val success = repository.endSession(sessionId)
                Result.success(success)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // GPS and Location Use Cases
    class TrackLocationUseCase(private val repository: GameRepository) {
        suspend fun execute(sessionId: String, lat: Double, lng: Double, city: String?): Result<Boolean> {
            return try {
                // Submit GPS point to backend
                val success = repository.submitGpsPoint(sessionId, lat, lng, city)
                if (success) {
                    // Also update presence for real-time tracking
                    city?.let { repository.updatePresence(lat, lng, it) }
                }
                Result.success(success)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    class GetNearbyPlayersUseCase(private val repository: GameRepository) {
        suspend fun execute(lat: Double, lng: Double, city: String): Result<List<NearbyPlayer>> {
            return try {
                val players = repository.getNearbyPlayers(lat, lng, city)
                Result.success(players)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // Trail Management Use Cases
    class GetTrailStateUseCase(private val repository: GameRepository) {
        suspend fun execute(sessionId: String): Result<Trail> {
            return try {
                val trail = repository.getTrailState(sessionId)
                if (trail != null) {
                    Result.success(trail)
                } else {
                    Result.failure(Exception("Trail not found"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // Territory Management Use Cases
    class ClaimTerritoryUseCase(private val repository: GameRepository) {
        suspend fun execute(sessionId: String, areaM2: Float, h3Cells: List<String>): Result<TerritoryClaim> {
            return try {
                val claim = repository.submitClaim(sessionId, areaM2, h3Cells)
                if (claim != null) {
                    Result.success(claim)
                } else {
                    Result.failure(Exception("Failed to claim territory"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    class BankScoreUseCase(private val repository: GameRepository) {
        suspend fun execute(sessionId: String, city: String?, areaM2: Float, score: Int): Result<BankTransaction> {
            return try {
                val transaction = repository.bankScore(sessionId, city, areaM2, score)
                if (transaction != null) {
                    Result.success(transaction)
                } else {
                    Result.failure(Exception("Failed to bank score"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // Powerup Use Cases
    class GetPowerupsUseCase(private val repository: GameRepository) {
        suspend fun execute(): Result<List<Powerup>> {
            return try {
                val powerups = repository.getPowerups()
                Result.success(powerups)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    class UsePowerupUseCase(private val repository: GameRepository) {
        suspend fun execute(powerupId: String, sessionId: String?): Result<Boolean> {
            return try {
                val success = repository.usePowerup(powerupId, sessionId)
                Result.success(success)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // Leaderboard Use Cases
    class GetLeaderboardUseCase(private val repository: GameRepository) {
        suspend fun execute(city: String?, limit: Int = 10): Result<List<LeaderboardEntry>> {
            return try {
                val leaderboard = repository.getLeaderboard(city, limit)
                Result.success(leaderboard)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    class GetVeryLeaderboardUseCase(private val repository: GameRepository) {
        suspend fun execute(count: Int = 10): Result<List<LeaderboardEntry>> {
            return try {
                val leaderboard = repository.getVeryLeaderboard(count)
                Result.success(leaderboard)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    class GetVeryScoreUseCase(private val repository: GameRepository) {
        suspend fun execute(address: String): Result<Int> {
            return try {
                val score = repository.getVeryScore(address)
                Result.success(score)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // Health Check Use Case
    class HealthCheckUseCase(private val repository: GameRepository) {
        suspend fun execute(): Result<Boolean> {
            return try {
                val isHealthy = repository.healthCheck()
                Result.success(isHealthy)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // Composite Use Case for complete gameplay flow
    class StartGameFlowUseCase(private val repository: GameRepository) {
        suspend fun execute(userId: String, city: String?): Result<GameFlowData> {
            return try {
                // Get user profile
                val user = repository.getUserProfile(userId)
                    ?: return Result.failure(Exception("User not found"))

                // Create new session
                val session = repository.createSession(city)
                    ?: return Result.failure(Exception("Failed to create session"))

                // Get available powerups
                val powerups = repository.getPowerups()

                val gameFlowData = GameFlowData(
                    user = user,
                    session = session,
                    availablePowerups = powerups
                )

                Result.success(gameFlowData)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    // Data class for composite use case
    data class GameFlowData(
        val user: User,
        val session: GameSession,
        val availablePowerups: List<Powerup>
    )
}

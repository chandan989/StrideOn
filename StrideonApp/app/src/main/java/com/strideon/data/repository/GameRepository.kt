package com.strideon.data.repository

import com.strideon.ApiClient
import com.strideon.domain.models.*
import org.json.JSONObject
import org.json.JSONArray
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class GameRepository {
    
    suspend fun healthCheck(): Boolean = suspendCoroutine { continuation ->
        ApiClient.healthCheck { ok, _ ->
            continuation.resume(ok)
        }
    }

    // User Profile Operations
    suspend fun getUserProfile(userId: String): User? = suspendCoroutine { continuation ->
        ApiClient.getUserProfile(userId) { ok, body ->
            if (ok) {
                try {
                    val json = JSONObject(body)
                    val user = User(
                        userId = json.getString("user_id"),
                        username = json.optString("username").takeIf { it.isNotEmpty() },
                        avatarUrl = json.optString("avatar_url").takeIf { it.isNotEmpty() },
                        city = json.optString("city").takeIf { it.isNotEmpty() },
                        wepinUserId = json.optString("wepin_user_id").takeIf { it.isNotEmpty() },
                        wepinAddress = json.optString("wepin_address").takeIf { it.isNotEmpty() }
                    )
                    continuation.resume(user)
                } catch (e: Exception) {
                    continuation.resume(null)
                }
            } else {
                continuation.resume(null)
            }
        }
    }

    suspend fun updateUserProfile(userId: String, username: String?, avatarUrl: String?, city: String?): Boolean = 
        suspendCoroutine { continuation ->
            ApiClient.updateUserProfile(userId, username, avatarUrl, city) { ok, _ ->
                continuation.resume(ok)
            }
        }

    // Session Management
    suspend fun createSession(city: String?): GameSession? = suspendCoroutine { continuation ->
        ApiClient.createSession(city) { ok, body ->
            if (ok) {
                try {
                    val json = JSONObject(body)
                    val session = GameSession(
                        id = json.getString("id"),
                        userId = json.getString("user_id"),
                        city = json.optString("city").takeIf { it.isNotEmpty() },
                        startedAt = json.getString("started_at"),
                        endedAt = json.optString("ended_at").takeIf { it.isNotEmpty() },
                        status = json.getString("status")
                    )
                    continuation.resume(session)
                } catch (e: Exception) {
                    continuation.resume(null)
                }
            } else {
                continuation.resume(null)
            }
        }
    }

    suspend fun endSession(sessionId: String): Boolean = suspendCoroutine { continuation ->
        ApiClient.endSession(sessionId) { ok, _ ->
            continuation.resume(ok)
        }
    }

    // GPS and Presence
    suspend fun submitGpsPoint(sessionId: String, lat: Double, lng: Double, city: String?): Boolean = 
        suspendCoroutine { continuation ->
            ApiClient.submitGpsPoint(sessionId, lat, lng, city) { ok, _ ->
                continuation.resume(ok)
            }
        }

    suspend fun updatePresence(lat: Double, lng: Double, city: String): Boolean = 
        suspendCoroutine { continuation ->
            ApiClient.updatePresence(lat, lng, city) { ok, _ ->
                continuation.resume(ok)
            }
        }

    suspend fun getNearbyPlayers(lat: Double, lng: Double, city: String): List<NearbyPlayer> = 
        suspendCoroutine { continuation ->
            ApiClient.getNearbyPlayers(lat, lng, city) { ok, body ->
                if (ok) {
                    try {
                        val jsonArray = JSONArray(body)
                        val players = mutableListOf<NearbyPlayer>()
                        for (i in 0 until jsonArray.length()) {
                            val json = jsonArray.getJSONObject(i)
                            val player = NearbyPlayer(
                                userId = json.getString("user_id"),
                                distanceM = json.optDouble("dist_m").takeIf { !it.isNaN() }?.toFloat(),
                                lat = json.optDouble("lat").takeIf { !it.isNaN() },
                                lng = json.optDouble("lng").takeIf { !it.isNaN() },
                                h3Index = json.optString("h3_index").takeIf { it.isNotEmpty() },
                                updatedAt = json.optString("updated_at").takeIf { it.isNotEmpty() }
                            )
                            players.add(player)
                        }
                        continuation.resume(players)
                    } catch (e: Exception) {
                        continuation.resume(emptyList())
                    }
                } else {
                    continuation.resume(emptyList())
                }
            }
        }

    // Trail Management
    suspend fun getTrailState(sessionId: String): Trail? = suspendCoroutine { continuation ->
        ApiClient.getTrailState(sessionId) { ok, body ->
            if (ok) {
                try {
                    val json = JSONObject(body)
                    val trail = Trail(
                        sessionId = json.getString("session_id"),
                        userId = json.getString("user_id"),
                        status = json.getString("status"),
                        pointsCount = json.getInt("points_count"),
                        h3CellsCount = json.getInt("h3_cells_count"),
                        totalLengthM = json.getDouble("total_length_m").toFloat(),
                        lastUpdated = json.getString("last_updated"),
                        claimedTerritoryCount = json.getInt("claimed_territory_count")
                    )
                    continuation.resume(trail)
                } catch (e: Exception) {
                    continuation.resume(null)
                }
            } else {
                continuation.resume(null)
            }
        }
    }

    // Territory Claims
    suspend fun submitClaim(sessionId: String, areaM2: Float, h3Cells: List<String>): TerritoryClaim? = 
        suspendCoroutine { continuation ->
            ApiClient.submitClaim(sessionId, areaM2, h3Cells) { ok, body ->
                if (ok) {
                    try {
                        val json = JSONObject(body)
                        val claim = TerritoryClaim(
                            id = json.getString("id"),
                            sessionId = json.getString("session_id"),
                            userId = json.getString("user_id"),
                            areaM2 = json.getDouble("area_m2").toFloat(),
                            h3Cells = json.getJSONArray("h3_cells").let { arr ->
                                (0 until arr.length()).map { arr.getString(it) }
                            },
                            createdAt = json.getString("created_at")
                        )
                        continuation.resume(claim)
                    } catch (e: Exception) {
                        continuation.resume(null)
                    }
                } else {
                    continuation.resume(null)
                }
            }
        }

    // Banking
    suspend fun bankScore(sessionId: String, city: String?, areaM2: Float, score: Int): BankTransaction? = 
        suspendCoroutine { continuation ->
            ApiClient.bankScore(sessionId, city, areaM2, score) { ok, body ->
                if (ok) {
                    try {
                        val json = JSONObject(body)
                        val transaction = BankTransaction(
                            id = json.getString("id"),
                            userId = json.getString("user_id"),
                            sessionId = json.getString("session_id"),
                            city = json.optString("city").takeIf { it.isNotEmpty() },
                            timestamp = json.getString("ts"),
                            day = json.getString("day"),
                            areaM2 = json.getDouble("area_m2").toFloat(),
                            score = json.getInt("score"),
                            ipfsCid = json.optString("ipfs_cid").takeIf { it.isNotEmpty() },
                            signature = json.optString("signature").takeIf { it.isNotEmpty() }
                        )
                        continuation.resume(transaction)
                    } catch (e: Exception) {
                        continuation.resume(null)
                    }
                } else {
                    continuation.resume(null)
                }
            }
        }

    // Powerups
    suspend fun getPowerups(): List<Powerup> = suspendCoroutine { continuation ->
        ApiClient.getPowerups { ok, body ->
            if (ok) {
                try {
                    val jsonArray = JSONArray(body)
                    val powerups = mutableListOf<Powerup>()
                    for (i in 0 until jsonArray.length()) {
                        val json = jsonArray.getJSONObject(i)
                        val powerup = Powerup(
                            id = json.getString("id"),
                            name = json.getString("name"),
                            description = json.getString("description"),
                            cost = json.getInt("cost"),
                            duration = json.optInt("duration").takeIf { json.has("duration") },
                            effect = json.getString("effect")
                        )
                        powerups.add(powerup)
                    }
                    continuation.resume(powerups)
                } catch (e: Exception) {
                    continuation.resume(emptyList())
                }
            } else {
                continuation.resume(emptyList())
            }
        }
    }

    suspend fun usePowerup(powerupId: String, sessionId: String?): Boolean = 
        suspendCoroutine { continuation ->
            ApiClient.usePowerup(powerupId, sessionId) { ok, _ ->
                continuation.resume(ok)
            }
        }

    // Leaderboards
    suspend fun getLeaderboard(city: String?, limit: Int = 10): List<LeaderboardEntry> = 
        suspendCoroutine { continuation ->
            ApiClient.getLeaderboard(city, limit) { ok, body ->
                if (ok) {
                    try {
                        val jsonArray = JSONArray(body)
                        val entries = mutableListOf<LeaderboardEntry>()
                        for (i in 0 until jsonArray.length()) {
                            val json = jsonArray.getJSONObject(i)
                            val entry = LeaderboardEntry(
                                userId = json.getString("user_id"),
                                username = json.optString("username").takeIf { it.isNotEmpty() },
                                score = json.getInt("score"),
                                rank = i + 1, // Calculate rank based on position
                                city = json.optString("city").takeIf { it.isNotEmpty() }
                            )
                            entries.add(entry)
                        }
                        continuation.resume(entries)
                    } catch (e: Exception) {
                        continuation.resume(emptyList())
                    }
                } else {
                    continuation.resume(emptyList())
                }
            }
        }

    // Very Network Integration
    suspend fun getVeryLeaderboard(count: Int = 10): List<LeaderboardEntry> = 
        suspendCoroutine { continuation ->
            ApiClient.getVeryLeaderboard(count) { ok, body ->
                if (ok) {
                    try {
                        val jsonArray = JSONArray(body)
                        val entries = mutableListOf<LeaderboardEntry>()
                        for (i in 0 until jsonArray.length()) {
                            val json = jsonArray.getJSONObject(i)
                            val entry = LeaderboardEntry(
                                userId = json.getString("player"),
                                username = json.optString("username").takeIf { it.isNotEmpty() },
                                score = json.getInt("score"),
                                rank = i + 1,
                                city = null
                            )
                            entries.add(entry)
                        }
                        continuation.resume(entries)
                    } catch (e: Exception) {
                        continuation.resume(emptyList())
                    }
                } else {
                    continuation.resume(emptyList())
                }
            }
        }

    suspend fun getVeryScore(address: String): Int = suspendCoroutine { continuation ->
        ApiClient.getVeryScore(address) { ok, body ->
            if (ok) {
                try {
                    val json = JSONObject(body)
                    continuation.resume(json.getInt("score"))
                } catch (e: Exception) {
                    continuation.resume(0)
                }
            } else {
                continuation.resume(0)
            }
        }
    }
}

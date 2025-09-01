package com.strideon.domain.models

import java.util.*

// User Profile Model
data class User(
    val userId: String,
    val username: String?,
    val avatarUrl: String?,
    val city: String?,
    val wepinUserId: String?,
    val wepinAddress: String?
)

// Game Session Model
data class GameSession(
    val id: String,
    val userId: String,
    val city: String?,
    val startedAt: String,
    val endedAt: String?,
    val status: String // 'active', 'paused', 'ended'
)

// GPS Point Model
data class GpsPoint(
    val sessionId: String,
    val lat: Double,
    val lng: Double,
    val timestamp: Date?,
    val h3Resolution: Int = 9,
    val city: String?
)

// Trail State Model
data class Trail(
    val sessionId: String,
    val userId: String,
    val status: String, // 'active', 'completed', 'cut'
    val pointsCount: Int,
    val h3CellsCount: Int,
    val totalLengthM: Float,
    val lastUpdated: String,
    val claimedTerritoryCount: Int
)

// Territory Claim Model
data class TerritoryClaim(
    val id: String,
    val sessionId: String,
    val userId: String,
    val areaM2: Float,
    val h3Cells: List<String>,
    val createdAt: String
)

// Banking Model  
data class BankTransaction(
    val id: String,
    val userId: String,
    val sessionId: String,
    val city: String?,
    val timestamp: String,
    val day: String,
    val areaM2: Float,
    val score: Int,
    val ipfsCid: String?,
    val signature: String?
)

// Powerup Model
data class Powerup(
    val id: String,
    val name: String,
    val description: String,
    val cost: Int,
    val duration: Int?, // in seconds, null for instant effects
    val effect: String
)

// Leaderboard Entry Model
data class LeaderboardEntry(
    val userId: String,
    val username: String?,
    val score: Int,
    val rank: Int,
    val city: String?
)

// Nearby Player Model
data class NearbyPlayer(
    val userId: String,
    val distanceM: Float?,
    val lat: Double?,
    val lng: Double?,
    val h3Index: String?,
    val updatedAt: String?
)

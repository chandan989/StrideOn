package com.strideon.presentation.viewmodel

import androidx.lifecycle.ViewModel
import com.strideon.data.repository.GameRepository
import com.strideon.domain.models.*
import com.strideon.domain.usecase.GameUseCases
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

//// Home Screen ViewModel
//class HomeViewModel(private val gameUseCases: GameUseCases) : ViewModel() {
//    private val _uiState = MutableStateFlow(HomeUiState())
//    val uiState: StateFlow<HomeUiState> = _uiState
//
//    private val _user = MutableStateFlow<User?>(null)
//    val user: StateFlow<User?> = _user
//
//    private val _veryScore = MutableStateFlow(0)
//    val veryScore: StateFlow<Int> = _veryScore
//
//    fun loadUserProfile(userId: String) {
//        viewModelScope.launch {
//            _uiState.value = _uiState.value.copy(isLoading = true)
//
//            val getUserProfileUseCase = GameUseCases.GetUserProfileUseCase(GameRepository())
//            getUserProfileUseCase.execute(userId)
//                .onSuccess { user ->
//                    _user.value = user
//                    _uiState.value = _uiState.value.copy(isLoading = false)
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        errorMessage = error.message
//                    )
//                }
//        }
//    }
//
//    fun loadVeryScore(address: String) {
//        viewModelScope.launch {
//            val getVeryScoreUseCase = GameUseCases.GetVeryScoreUseCase(GameRepository())
//            getVeryScoreUseCase.execute(address)
//                .onSuccess { score ->
//                    _veryScore.value = score
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(errorMessage = error.message)
//                }
//        }
//    }
//
//    fun startGameSession(city: String?) {
//        viewModelScope.launch {
//            _uiState.value = _uiState.value.copy(isLoading = true)
//
//            val startSessionUseCase = GameUseCases.StartGameSessionUseCase(GameRepository())
//            startSessionUseCase.execute(city)
//                .onSuccess { session ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        activeSession = session
//                    )
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        errorMessage = error.message
//                    )
//                }
//        }
//    }
//
//    data class HomeUiState(
//        val isLoading: Boolean = false,
//        val errorMessage: String? = null,
//        val activeSession: GameSession? = null
//    )
//}
//
//// Leaderboard ViewModel
//class LeaderboardViewModel(private val gameUseCases: GameUseCases) : ViewModel() {
//    private val _uiState = MutableStateFlow(LeaderboardUiState())
//    val uiState: StateFlow<LeaderboardUiState> = _uiState
//
//    private val _leaderboard = MutableStateFlow<List<LeaderboardEntry>>(emptyList())
//    val leaderboard: StateFlow<List<LeaderboardEntry>> = _leaderboard
//
//    private val _veryLeaderboard = MutableStateFlow<List<LeaderboardEntry>>(emptyList())
//    val veryLeaderboard: StateFlow<List<LeaderboardEntry>> = _veryLeaderboard
//
//    fun loadLeaderboard(city: String?, limit: Int = 10) {
//        viewModelScope.launch {
//            _uiState.value = _uiState.value.copy(isLoading = true)
//
//            val getLeaderboardUseCase = GameUseCases.GetLeaderboardUseCase(GameRepository())
//            getLeaderboardUseCase.execute(city, limit)
//                .onSuccess { entries ->
//                    _leaderboard.value = entries
//                    _uiState.value = _uiState.value.copy(isLoading = false)
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        errorMessage = error.message
//                    )
//                }
//        }
//    }
//
//    fun loadVeryLeaderboard(count: Int = 10) {
//        viewModelScope.launch {
//            val getVeryLeaderboardUseCase = GameUseCases.GetVeryLeaderboardUseCase(GameRepository())
//            getVeryLeaderboardUseCase.execute(count)
//                .onSuccess { entries ->
//                    _veryLeaderboard.value = entries
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(errorMessage = error.message)
//                }
//        }
//    }
//
//    data class LeaderboardUiState(
//        val isLoading: Boolean = false,
//        val errorMessage: String? = null
//    )
//}
//
//// Game/Map ViewModel
//class GameViewModel(private val gameUseCases: GameUseCases) : ViewModel() {
//    private val _uiState = MutableStateFlow(GameUiState())
//    val uiState: StateFlow<GameUiState> = _uiState
//
//    private val _currentSession = MutableStateFlow<GameSession?>(null)
//    val currentSession: StateFlow<GameSession?> = _currentSession
//
//    private val _trailState = MutableStateFlow<Trail?>(null)
//    val trailState: StateFlow<Trail?> = _trailState
//
//    private val _nearbyPlayers = MutableStateFlow<List<NearbyPlayer>>(emptyList())
//    val nearbyPlayers: StateFlow<List<NearbyPlayer>> = _nearbyPlayers
//
//    fun trackLocation(sessionId: String, lat: Double, lng: Double, city: String?) {
//        viewModelScope.launch {
//            val trackLocationUseCase = GameUseCases.TrackLocationUseCase(GameRepository())
//            trackLocationUseCase.execute(sessionId, lat, lng, city)
//                .onSuccess { success ->
//                    if (success) {
//                        // Update trail state after successful GPS tracking
//                        loadTrailState(sessionId)
//                    }
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(errorMessage = error.message)
//                }
//        }
//    }
//
//    fun loadTrailState(sessionId: String) {
//        viewModelScope.launch {
//            val getTrailStateUseCase = GameUseCases.GetTrailStateUseCase(GameRepository())
//            getTrailStateUseCase.execute(sessionId)
//                .onSuccess { trail ->
//                    _trailState.value = trail
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(errorMessage = error.message)
//                }
//        }
//    }
//
//    fun getNearbyPlayers(lat: Double, lng: Double, city: String) {
//        viewModelScope.launch {
//            val getNearbyPlayersUseCase = GameUseCases.GetNearbyPlayersUseCase(GameRepository())
//            getNearbyPlayersUseCase.execute(lat, lng, city)
//                .onSuccess { players ->
//                    _nearbyPlayers.value = players
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(errorMessage = error.message)
//                }
//        }
//    }
//
//    fun claimTerritory(sessionId: String, areaM2: Float, h3Cells: List<String>) {
//        viewModelScope.launch {
//            _uiState.value = _uiState.value.copy(isLoading = true)
//
//            val claimTerritoryUseCase = GameUseCases.ClaimTerritoryUseCase(GameRepository())
//            claimTerritoryUseCase.execute(sessionId, areaM2, h3Cells)
//                .onSuccess { claim ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        lastClaim = claim
//                    )
//                    // Refresh trail state after claim
//                    loadTrailState(sessionId)
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        errorMessage = error.message
//                    )
//                }
//        }
//    }
//
//    fun bankScore(sessionId: String, city: String?, areaM2: Float, score: Int) {
//        viewModelScope.launch {
//            _uiState.value = _uiState.value.copy(isLoading = true)
//
//            val bankScoreUseCase = GameUseCases.BankScoreUseCase(GameRepository())
//            bankScoreUseCase.execute(sessionId, city, areaM2, score)
//                .onSuccess { transaction ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        lastBankTransaction = transaction
//                    )
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        errorMessage = error.message
//                    )
//                }
//        }
//    }
//
//    data class GameUiState(
//        val isLoading: Boolean = false,
//        val errorMessage: String? = null,
//        val lastClaim: TerritoryClaim? = null,
//        val lastBankTransaction: BankTransaction? = null
//    )
//}
//
//// Powerups ViewModel
//class PowerupsViewModel(private val gameUseCases: GameUseCases) : ViewModel() {
//    private val _uiState = MutableStateFlow(PowerupsUiState())
//    val uiState: StateFlow<PowerupsUiState> = _uiState
//
//    private val _powerups = MutableStateFlow<List<Powerup>>(emptyList())
//    val powerups: StateFlow<List<Powerup>> = _powerups
//
//    fun loadPowerups() {
//        viewModelScope.launch {
//            _uiState.value = _uiState.value.copy(isLoading = true)
//
//            val getPowerupsUseCase = GameUseCases.GetPowerupsUseCase(GameRepository())
//            getPowerupsUseCase.execute()
//                .onSuccess { powerupList ->
//                    _powerups.value = powerupList
//                    _uiState.value = _uiState.value.copy(isLoading = false)
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        errorMessage = error.message
//                    )
//                }
//        }
//    }
//
//    fun usePowerup(powerupId: String, sessionId: String?) {
//        viewModelScope.launch {
//            _uiState.value = _uiState.value.copy(isLoading = true)
//
//            val usePowerupUseCase = GameUseCases.UsePowerupUseCase(GameRepository())
//            usePowerupUseCase.execute(powerupId, sessionId)
//                .onSuccess { success ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        powerupUsed = success
//                    )
//                }
//                .onFailure { error ->
//                    _uiState.value = _uiState.value.copy(
//                        isLoading = false,
//                        errorMessage = error.message
//                    )
//                }
//        }
//    }
//
//    data class PowerupsUiState(
//        val isLoading: Boolean = false,
//        val errorMessage: String? = null,
//        val powerupUsed: Boolean = false
//    )
//}

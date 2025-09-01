package com.strideon

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import com.strideon.data.repository.GameRepository
import com.strideon.domain.usecase.GameUseCases
import com.strideon.presentation.viewmodel.LeaderboardViewModel
import kotlinx.coroutines.launch
import org.json.JSONObject

class LeaderboardActivity : AppCompatActivity() {
    
    private lateinit var viewModel: LeaderboardViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_leaderboard)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        // Initialize ViewModel
        val gameRepository = GameRepository()
        val gameUseCases = GameUseCases(gameRepository)
        viewModel = ViewModelProvider(this, object : ViewModelProvider.Factory {
            override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>): T {
                @Suppress("UNCHECKED_CAST")
                return LeaderboardViewModel(gameUseCases) as T
            }
        })[LeaderboardViewModel::class.java]

        setupUI()
        observeViewModel()
        loadData()
    }

    private fun setupUI() {
        // Wire button to demonstrate backend+web3 via Very Network
        findViewById<Button>(R.id.check_demo_score).setOnClickListener { 
            checkDemoScore() 
        }
        
        // Show loading state initially
        showLoadingState()
    }

    private fun observeViewModel() {
        lifecycleScope.launch {
            // Observe UI state
            viewModel.uiState.collect { uiState ->
                if (uiState.isLoading) {
                    showLoadingState()
                } else {
                    uiState.errorMessage?.let { error ->
                        Toast.makeText(this@LeaderboardActivity, "Error: $error", Toast.LENGTH_SHORT).show()
                        setupMockLeaderboard()
                    }
                }
            }
        }

        lifecycleScope.launch {
            // Observe leaderboard data
            viewModel.leaderboard.collect { entries ->
                if (entries.isNotEmpty()) {
                    val displayItems = entries.map { entry ->
                        "${entry.rank}. ${entry.username ?: shorten(entry.userId)} - ${entry.score} pts"
                    }
                    updateLeaderboard(displayItems)
                    findViewById<TextView>(R.id.leaderboard_title).text = "Daily Leaderboard - Chandigarh (Live)"
                }
            }
        }

        lifecycleScope.launch {
            // Observe Very Network leaderboard data
            viewModel.veryLeaderboard.collect { entries ->
                if (entries.isNotEmpty()) {
                    val displayItems = entries.map { entry ->
                        "${entry.rank}. ${shorten(entry.userId)} - ${entry.score} pts"
                    }
                    updateLeaderboard(displayItems)
                    findViewById<TextView>(R.id.leaderboard_title).text = "Very Network Leaderboard (Live)"
                }
            }
        }
    }

    private fun loadData() {
        // Load both regular leaderboard and Very Network leaderboard
        viewModel.loadLeaderboard("Chandigarh", 10)
        viewModel.loadVeryLeaderboard(10)
    }

    private fun checkDemoScore() {
        val demoAddr = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        
        // Use the repository directly for demo score check
        lifecycleScope.launch {
            try {
                val gameRepository = GameRepository()
                val score = gameRepository.getVeryScore(demoAddr)
                runOnUiThread {
                    Toast.makeText(this@LeaderboardActivity, "Demo score (${shorten(demoAddr)}): $score", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                runOnUiThread {
                    Toast.makeText(this@LeaderboardActivity, "Score fetch failed: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun showLoadingState() {
        findViewById<TextView>(R.id.leaderboard_title).text = "Daily Leaderboard - Chandigarh"
        val rankViews = listOf(
            R.id.rank_1, R.id.rank_2, R.id.rank_3, R.id.rank_4,
            R.id.rank_5, R.id.rank_6, R.id.rank_7, R.id.rank_8
        )
        rankViews.forEachIndexed { idx, id ->
            findViewById<TextView>(id).text = "${idx + 1}. Loading..."
        }
    }

    private fun shorten(address: String): String {
        return if (address.length > 12) address.take(6) + "…" + address.takeLast(4) else address
    }

    private fun updateLeaderboard(items: List<String>) {
        val rankViews = listOf(
            R.id.rank_1, R.id.rank_2, R.id.rank_3, R.id.rank_4,
            R.id.rank_5, R.id.rank_6, R.id.rank_7, R.id.rank_8
        )
        // Fill provided items then clear remaining
        items.forEachIndexed { index, data ->
            if (index < rankViews.size) {
                findViewById<TextView>(rankViews[index]).text = data
            }
        }
        if (items.size < rankViews.size) {
            for (i in items.size until rankViews.size) {
                findViewById<TextView>(rankViews[i]).text = "${i + 1}. —"
            }
        }
    }

    private fun setupMockLeaderboard() {
        // For demo: show static mock leaderboard data as fallback
        val mockData = listOf(
            "1. Runner_Alpha - 850 pts",
            "2. CityStrider - 720 pts", 
            "3. TerritoryKing - 680 pts",
            "4. You - 450 pts",
            "5. MapMaster - 380 pts",
            "6. HexHunter - 320 pts",
            "7. TrailBlazer - 280 pts",
            "8. GridWalker - 240 pts"
        )
        updateLeaderboard(mockData)
        findViewById<TextView>(R.id.leaderboard_title).text = "Daily Leaderboard - Chandigarh (Demo)"
    }
}
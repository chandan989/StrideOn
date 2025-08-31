package com.strideon

import android.os.Bundle
import android.widget.ListView
import android.widget.TextView
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class LeaderboardActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_leaderboard)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        // Set up mock leaderboard data
        setupMockLeaderboard()

        // Also try to fetch on-chain leaderboard via backend (Very Network)
        ApiClient.getVeryLeaderboard(10) { ok, body ->
            runOnUiThread {
                val msg = if (ok) "On-chain leaderboard fetched" else "On-chain leaderboard failed"
                android.util.Log.d("StrideOn", "VeryNet LB ok=$ok body=${body.take(120)}")
                android.widget.Toast.makeText(this, msg, android.widget.Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun setupMockLeaderboard() {
        // For demo: show static mock leaderboard data as specified in README
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

        // Find TextView elements and set mock data
        findViewById<TextView>(R.id.leaderboard_title).text = "Daily Leaderboard - Chandigarh"
        
        // Set individual rank TextViews
        val rankViews = listOf(
            R.id.rank_1, R.id.rank_2, R.id.rank_3, R.id.rank_4,
            R.id.rank_5, R.id.rank_6, R.id.rank_7, R.id.rank_8
        )

        mockData.forEachIndexed { index, data ->
            if (index < rankViews.size) {
                findViewById<TextView>(rankViews[index]).text = data
            }
        }
    }
}
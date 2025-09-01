package com.strideon

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import android.util.Log
import com.strideon.UI_Elements.StoryUI.StoryAdapter
import com.strideon.UI_Elements.StoryUI.StoryData
import com.strideon.data.repository.GameRepository
import com.strideon.domain.usecase.GameUseCases
import com.strideon.presentation.viewmodel.HomeViewModel
import com.wepin.android.widgetlib.WepinWidget
import com.wepin.android.widgetlib.types.LoginProviderInfo
import com.wepin.android.widgetlib.types.WepinWidgetAttribute
import com.wepin.android.widgetlib.types.WepinWidgetParams
import com.wepin.android.commonlib.types.WepinLifeCycle
import kotlinx.coroutines.launch

class Home : AppCompatActivity() {

    private lateinit var faviconBtn: ImageView
    private lateinit var balance: TextView
    private lateinit var price: TextView
    private lateinit var name: TextView
    private lateinit var changePercentage: TextView
    private lateinit var changeSign: ImageView

    private lateinit var runLight: View
    private lateinit var activeRun: LinearLayout
    private lateinit var runStatus: TextView
    private lateinit var runDuration: TextView
    private lateinit var distanceConquered: TextView

    private lateinit var storyView: ListView
    private var slist: ArrayList<StoryData> = ArrayList()
    private lateinit var storyAdapter: StoryAdapter

    private lateinit var wepinWidget: WepinWidget
    private var isWepinInitialized: Boolean = false
    private var isInitializingWepin: Boolean = false
    
    private lateinit var viewModel: HomeViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_home)
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
                return HomeViewModel(gameUseCases) as T
            }
        })[HomeViewModel::class.java]

        setupUI()
        setupWepin()
        observeViewModel()
        loadInitialData()
    }

    private fun setupUI() {
        balance = findViewById(R.id.balance)
        faviconBtn = findViewById(R.id.favicon_btn)
        
        faviconBtn.setOnClickListener {
            val intent = Intent(this, LeaderboardActivity::class.java)
            startActivity(intent)
        }

        findViewById<LinearLayout>(R.id.active_run).setOnClickListener {
            // Start new game session
            viewModel.startGameSession("Chandigarh")
        }

        findViewById<ImageView>(R.id.powerup).setOnClickListener {
            val intent = Intent(this, Powerups::class.java)
            startActivity(intent)
            finish()
        }

        findViewById<ImageView>(R.id.chat).setOnClickListener {
            val intent = Intent(this, Powerups::class.java)
            startActivity(intent)
            finish()
        }

        findViewById<ImageView>(R.id.account).setOnClickListener {
            val intent = Intent(this, Powerups::class.java)
            startActivity(intent)
            finish()
        }
    }

    private fun setupWepin() {
        val wepinWidgetParams = WepinWidgetParams(
            context = this,
            appId = "da2f065cb44fa7fd915a4796c6559246",
            appKey = "ak_live_mBMWdI11Vu2I7FwUg2YKiQA2gL5xdiKv4dzGgWHpMAu"
        )
        wepinWidget = WepinWidget(wepinWidgetParams)
        val attributes = WepinWidgetAttribute("en", "USD")
        val res = wepinWidget.initialize(attributes)
        res?.whenComplete { infResponse, error ->
            if (error == null) {
                println(infResponse)
            } else {
                println(error)
            }
        }

        balance.setOnClickListener {
            if(wepinWidget.isInitialized()){
                wepinWidget.getStatus()?.whenComplete { status, error ->
                    if (error == null) {
                        when (status) {
                            WepinLifeCycle.INITIALIZING -> Log.d("Home", "WepinSDK is initializing")
                            WepinLifeCycle.INITIALIZED -> {
                                val loginResult = wepinWidget.loginWithUI(this, listOf(
                                    LoginProviderInfo(provider = "google", clientId = "1023618994627-l0tc7oda5nk55k760eafti7c95kqakvb.apps.googleusercontent.com"),
                                    LoginProviderInfo(provider = "discord", clientId = "1411443642123554896")))
                                loginResult?.whenComplete { wepinUser, error ->
                                    if (error == null) {
                                        Log.d("Home", "Wepin User is $wepinUser")
                                        // Load VERY score when user is logged in
                                        wepinUser?.walletId?.let { address ->
                                            viewModel.loadVeryScore(address)
                                        }
                                    } else {
                                        Log.d("Home", "loginWithUI error: $error")
                                    }
                                }
                            }
                            WepinLifeCycle.BEFORE_LOGIN -> {
                                val loginResult = wepinWidget.loginWithUI(this, listOf(
                                    LoginProviderInfo(provider = "google", clientId = "1023618994627-l0tc7oda5nk55k760eafti7c95kqakvb.apps.googleusercontent.com"),
                                    LoginProviderInfo(provider = "discord", clientId = "1411443642123554896")))
                                loginResult?.whenComplete { wepinUser, error ->
                                    if (error == null) {
                                        Log.d("Home", "Wepin User is $wepinUser")
                                        wepinUser?.walletId?.let { address ->
                                            viewModel.loadVeryScore(address)
                                        }
                                    } else {
                                        Log.d("Home", "loginWithUI error: $error")
                                    }
                                }
                            }
                            WepinLifeCycle.LOGIN -> {
                                val res = wepinWidget.openWidget(this)
                                res?.whenComplete { result, error ->
                                    if (error == null) {
                                        Log.d("home", "openWidget result is $result")
                                    } else {
                                        Log.d("home", "openWidget error: $error")
                                    }
                                }
                            }
                            WepinLifeCycle.LOGIN_BEFORE_REGISTER -> Log.d(
                                "Home",
                                "User logged in but not registered with Wepin"
                            )
                            else -> Log.d("Home", "Unknown status: $status")
                        }
                    } else {
                        Log.d("Home", "getStatus error: $error")
                    }
                }
            }
        }
    }

    private fun observeViewModel() {
        lifecycleScope.launch {
            viewModel.uiState.collect { uiState ->
                // Handle loading states
                if (uiState.isLoading) {
                    // Show loading indicator if needed
                } else {
                    uiState.errorMessage?.let { error ->
                        Toast.makeText(this@Home, "Error: $error", Toast.LENGTH_SHORT).show()
                    }
                    
                    uiState.activeSession?.let { session ->
                        // Navigate to game when session is created
                        val intent = Intent(this@Home, MainActivity::class.java)
                        intent.putExtra("session_id", session.id)
                        startActivity(intent)
                        finish()
                    }
                }
            }
        }

        lifecycleScope.launch {
            viewModel.user.collect { user ->
                user?.let {
                    // Update UI with user data
                    // You can update username or other profile info here
                    Log.d("Home", "User loaded: ${it.username}")
                }
            }
        }

        lifecycleScope.launch {
            viewModel.veryScore.collect { score ->
                // Update balance display with VERY token score
                balance.text = "$score VERY"
                Log.d("Home", "VERY Score updated: $score")
            }
        }
    }

    private fun loadInitialData() {
        // Load user profile if we have a user ID
        // For now, using a demo user ID - in production this would come from auth
        val demoUserId = "demo-user-123"
        viewModel.loadUserProfile(demoUserId)
        
        // Load demo VERY score
        val demoAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        viewModel.loadVeryScore(demoAddress)
    }
}
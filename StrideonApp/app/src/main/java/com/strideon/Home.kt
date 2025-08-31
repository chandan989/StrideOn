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
import android.util.Log
import com.strideon.UI_Elements.StoryUI.StoryAdapter
import com.strideon.UI_Elements.StoryUI.StoryData
import com.wepin.android.widgetlib.WepinWidget
import com.wepin.android.widgetlib.types.LoginProviderInfo
import com.wepin.android.widgetlib.types.WepinWidgetAttribute
import com.wepin.android.widgetlib.types.WepinWidgetParams
import com.wepin.android.commonlib.types.WepinLifeCycle

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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_home)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        balance = findViewById(R.id.balance)

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

        // Lazy init: initialize on demand when user taps balance

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

        findViewById<LinearLayout>(R.id.active_run).setOnClickListener {
            val intent = Intent(this, MainActivity::class.java)
            startActivity(intent)
            finish()

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
}
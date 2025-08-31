package com.strideon

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class Splash : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_splash)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        // Try to connect to backend health endpoint on launch
        ApiClient.healthCheck { ok, msg ->
            runOnUiThread {
                Log.d("StrideOn", "Health: ok=$ok msg=${msg.take(120)}")
                val text = if (ok) "Connected to server" else "Server unavailable"
                Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
            }
        }

        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(this, Welcome::class.java)
            startActivity(intent)
            finish()
        }, 800)
    }
}
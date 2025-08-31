package com.strideon

import android.content.Intent
import android.os.Bundle
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class Register : AppCompatActivity() {

    private lateinit var registerBtn : TextView
    private lateinit var loginGoogle : LinearLayout
    private lateinit var loginApple : LinearLayout
    private lateinit var bottom : LinearLayout

    private lateinit var inpEmail: EditText
    private lateinit var inpPass: EditText
    lateinit var inpCountry: TextView

    private lateinit var checkBox: ImageView

    private var termsAgreed = false

    private val RC_SIGN_IN = 9001

    private var TAG = "Register.class"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_register)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        registerBtn = findViewById(R.id.register_btn)
        loginGoogle = findViewById(R.id.login_google)
        loginApple = findViewById(R.id.login_apple)
        bottom = findViewById(R.id.bottom)

        // Input Fields
        inpEmail = findViewById(R.id.inpEmail)
        inpPass = findViewById(R.id.inpPass)
        inpCountry = findViewById(R.id.inpCountry)

        checkBox = findViewById(R.id.checkBox)

        bottom.setOnClickListener {
            val intent = Intent(this, Login::class.java)
            startActivity(intent)
            finish()
        }

    }
}
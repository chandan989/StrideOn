package com.strideon

import android.R.id.home
import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class Login : AppCompatActivity() {
    private lateinit var backButton: ImageView
    private lateinit var inpEmail: EditText
    private lateinit var inpPass: EditText
    private lateinit var loginBtn: TextView

    private lateinit var emailGrp: LinearLayout
    private lateinit var passGrp: LinearLayout

    private lateinit var loginGoogle: LinearLayout
    private lateinit var loginApple: LinearLayout
    private lateinit var forgotPass: TextView

    private var isPasswordVisible = false

    private val RC_SIGN_IN = 9001

    private var TAG = "Login.class"

    private lateinit var googleSignInLauncher: ActivityResultLauncher<Intent>

    override fun onCreate(savedInstanceState: Bundle?) {

        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_login)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        backButton = findViewById(R.id.BackBtn)

        loginBtn = findViewById(R.id.login_btn)
        inpEmail = findViewById(R.id.inpEmail)
        inpPass = findViewById(R.id.inpPass)

        emailGrp = findViewById(R.id.emailGrp)
        passGrp = findViewById(R.id.passGrp)

        loginGoogle = findViewById(R.id.login_google)
        loginApple = findViewById(R.id.login_apple)

        forgotPass = findViewById(R.id.forgotPass)


        backButton.setOnClickListener {
            emailGrp.visibility = View.VISIBLE
            passGrp.visibility = View.GONE
            forgotPass.visibility = View.GONE
            findViewById<TextView>(R.id.orTxt).visibility = View.VISIBLE
            loginGoogle.visibility = View.VISIBLE
            loginApple.visibility = View.VISIBLE
            backButton.visibility = View.GONE
            isPasswordVisible = false
        }

        loginBtn.setOnClickListener{
            if (isPasswordVisible) {
//                usrlogin()
                val intent = Intent(this, Home::class.java)
                startActivity(intent)
                finish()
            }else{
                isPasswordVisible = true
                emailGrp.visibility = View.GONE
                passGrp.visibility = View.VISIBLE
                forgotPass.visibility = View.VISIBLE
                findViewById<TextView>(R.id.orTxt).visibility = View.GONE
                loginGoogle.visibility = View.GONE
                loginApple.visibility = View.GONE
                backButton.visibility = View.VISIBLE
            }
        }

//        loginGoogle.setOnClickListener { GoogleSignIn() }

        findViewById<LinearLayout>(R.id.bottom).setOnClickListener{
            val intent = Intent(this, Register::class.java)
            startActivity(intent)
            finish()
        }

        findViewById<TextView>(R.id.forgotPass).setOnClickListener {
            val intent = Intent(this, ForgotPassword::class.java)
            startActivity(intent)
            finish()
        }

//        if(TokenManager.getInstance(applicationContext)!!.isLoggedIn && TokenManager.getInstance(applicationContext)!!.isVerified){
//            finish()
//            startActivity(Intent(applicationContext, ProfileSetup::class.java))
//        }else if(TokenManager.getInstance(applicationContext)!!.isLoggedIn && TokenManager.getInstance(applicationContext)!!.isVerified == false){
//            val args: Bundle = Bundle()
//            args.putInt("mode", 2)
//            args.putString("email","your registered email")
//            val dialog: verify_dialog = verify_dialog()
//            dialog.setArguments(args)
//            dialog.setCancelable(false)
//            dialog.show(getSupportFragmentManager(), "Verify Dialog")
//        }

    }
}
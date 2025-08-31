package com.strideon

import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import java.io.IOException
import java.util.concurrent.TimeUnit

object ApiClient {
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(3, TimeUnit.SECONDS)
        .readTimeout(5, TimeUnit.SECONDS)
        .callTimeout(5, TimeUnit.SECONDS)
        .build()

    private fun baseUrl(): String = BuildConfig.API_BASE_URL.trimEnd('/')

    fun healthCheck(callback: (ok: Boolean, message: String) -> Unit) {
        val req = Request.Builder()
            .url("${baseUrl()}/health")
            .get()
            .build()
        client.newCall(req).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                callback(false, e.message ?: "Network error")
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (it.isSuccessful) {
                        callback(true, it.body?.string() ?: "")
                    } else {
                        callback(false, "HTTP ${it.code}")
                    }
                }
            }
        })
    }

    fun getVeryLeaderboard(count: Int = 10, callback: (ok: Boolean, body: String) -> Unit) {
        val url = "${baseUrl()}/verynet/leaderboard?count=${count}"
        val req = Request.Builder().url(url).get().build()
        client.newCall(req).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                callback(false, e.message ?: "Network error")
            }
            override fun onResponse(call: Call, response: Response) {
                response.use {
                    val body = it.body?.string() ?: ""
                    callback(it.isSuccessful, body)
                }
            }
        })
    }

    fun getVeryScore(address: String, callback: (ok: Boolean, body: String) -> Unit) {
        val url = "${baseUrl()}/verynet/score/${address}"
        val req = Request.Builder().url(url).get().build()
        client.newCall(req).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                callback(false, e.message ?: "Network error")
            }
            override fun onResponse(call: Call, response: Response) {
                response.use {
                    val body = it.body?.string() ?: ""
                    callback(it.isSuccessful, body)
                }
            }
        })
    }
}

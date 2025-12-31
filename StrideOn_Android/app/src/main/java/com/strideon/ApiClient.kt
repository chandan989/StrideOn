package com.strideon

import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

object ApiClient {
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .callTimeout(15, TimeUnit.SECONDS)
        .build()

    private val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
    private fun baseUrl(): String = BuildConfig.API_BASE_URL.trimEnd('/')

    // Health Check
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

    // User Profile Endpoints
    fun getUserProfile(userId: String, callback: (ok: Boolean, body: String) -> Unit) {
        val url = "${baseUrl()}/profiles/$userId"
        val req = Request.Builder().url(url).get().build()
        executeCall(req, callback)
    }

    fun updateUserProfile(userId: String, username: String?, avatarUrl: String?, city: String?, callback: (ok: Boolean, body: String) -> Unit) {
        val json = JSONObject()
        username?.let { json.put("username", it) }
        avatarUrl?.let { json.put("avatar_url", it) }
        city?.let { json.put("city", it) }
        
        val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
        val req = Request.Builder()
            .url("${baseUrl()}/profiles/$userId")
            .patch(requestBody)
            .build()
        executeCall(req, callback)
    }

    // Session Management
    fun createSession(city: String?, callback: (ok: Boolean, body: String) -> Unit) {
        val json = JSONObject()
        city?.let { json.put("city", it) }
        
        val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
        val req = Request.Builder()
            .url("${baseUrl()}/sessions")
            .post(requestBody)
            .build()
        executeCall(req, callback)
    }

    fun endSession(sessionId: String, callback: (ok: Boolean, body: String) -> Unit) {
        val req = Request.Builder()
            .url("${baseUrl()}/sessions/$sessionId/end")
            .post("".toRequestBody(JSON_MEDIA_TYPE))
            .build()
        executeCall(req, callback)
    }

    // GPS Tracking
    fun submitGpsPoint(sessionId: String, lat: Double, lng: Double, city: String?, callback: (ok: Boolean, body: String) -> Unit) {
        val json = JSONObject().apply {
            put("session_id", sessionId)
            put("lat", lat)
            put("lng", lng)
            city?.let { put("city", it) }
        }
        
        val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
        val req = Request.Builder()
            .url("${baseUrl()}/gps/points")
            .post(requestBody)
            .build()
        executeCall(req, callback)
    }

    fun updatePresence(lat: Double, lng: Double, city: String, callback: (ok: Boolean, body: String) -> Unit) {
        val json = JSONObject().apply {
            put("lat", lat)
            put("lng", lng)
            put("city", city)
        }
        
        val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
        val req = Request.Builder()
            .url("${baseUrl()}/presence")
            .post(requestBody)
            .build()
        executeCall(req, callback)
    }

    fun getNearbyPlayers(lat: Double, lng: Double, city: String, callback: (ok: Boolean, body: String) -> Unit) {
        val url = "${baseUrl()}/presence/nearby?lat=$lat&lng=$lng&city=$city"
        val req = Request.Builder().url(url).get().build()
        executeCall(req, callback)
    }

    // Trail Management
    fun getTrailState(sessionId: String, callback: (ok: Boolean, body: String) -> Unit) {
        val url = "${baseUrl()}/trails/state/$sessionId"
        val req = Request.Builder().url(url).get().build()
        executeCall(req, callback)
    }

    // Territory Claims
    fun submitClaim(sessionId: String, areaM2: Float, h3Cells: List<String>, callback: (ok: Boolean, body: String) -> Unit) {
        val json = JSONObject().apply {
            put("session_id", sessionId)
            put("area_m2", areaM2)
            put("h3_cells", org.json.JSONArray(h3Cells))
        }
        
        val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
        val req = Request.Builder()
            .url("${baseUrl()}/claims")
            .post(requestBody)
            .build()
        executeCall(req, callback)
    }

    // Banking
    fun bankScore(sessionId: String, city: String?, areaM2: Float, score: Int, callback: (ok: Boolean, body: String) -> Unit) {
        val json = JSONObject().apply {
            put("session_id", sessionId)
            put("area_m2", areaM2)
            put("score", score)
            city?.let { put("city", it) }
        }
        
        val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
        val req = Request.Builder()
            .url("${baseUrl()}/bank")
            .post(requestBody)
            .build()
        executeCall(req, callback)
    }

    // Powerups
    fun getPowerups(callback: (ok: Boolean, body: String) -> Unit) {
        val url = "${baseUrl()}/powerups"
        val req = Request.Builder().url(url).get().build()
        executeCall(req, callback)
    }

    fun usePowerup(powerupId: String, sessionId: String?, callback: (ok: Boolean, body: String) -> Unit) {
        val json = JSONObject().apply {
            put("powerup_id", powerupId)
            sessionId?.let { put("session_id", it) }
        }
        
        val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
        val req = Request.Builder()
            .url("${baseUrl()}/powerups/use")
            .post(requestBody)
            .build()
        executeCall(req, callback)
    }

    // Leaderboards
    fun getLeaderboard(city: String?, limit: Int = 10, callback: (ok: Boolean, body: String) -> Unit) {
        var url = "${baseUrl()}/leaderboard?limit=$limit"
        city?.let { url += "&city=$it" }
        val req = Request.Builder().url(url).get().build()
        executeCall(req, callback)
    }

    // Very Network Integration
    fun getVeryLeaderboard(count: Int = 10, callback: (ok: Boolean, body: String) -> Unit) {
        val url = "${baseUrl()}/verynet/leaderboard?count=$count"
        val req = Request.Builder().url(url).get().build()
        executeCall(req, callback)
    }

    fun getVeryScore(address: String, callback: (ok: Boolean, body: String) -> Unit) {
        val url = "${baseUrl()}/verynet/score/$address"
        val req = Request.Builder().url(url).get().build()
        executeCall(req, callback)
    }

    // Helper method to execute calls
    private fun executeCall(request: Request, callback: (ok: Boolean, body: String) -> Unit) {
        client.newCall(request).enqueue(object : Callback {
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

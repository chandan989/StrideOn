package com.strideon

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Color
import android.location.Location
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Button
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.google.android.gms.location.*
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.*
import kotlin.math.*
// Removed H3Core import - using simplified hex grid implementation
import android.content.Intent

class MainActivity : AppCompatActivity(), OnMapReadyCallback {

    private lateinit var mMap: GoogleMap
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    
    // UI Elements
    private lateinit var backButton: ImageButton
    private lateinit var distanceValue: TextView
    private lateinit var timeValue: TextView
    private lateinit var speedValue: TextView
    private lateinit var scoreValue: TextView
    private lateinit var startStopButton: Button
    private lateinit var pauseButton: Button
    private lateinit var centerLocationButton: Button
    private lateinit var bankButton: Button
    
    // Game State
    private var isTracking = false
    private var isPaused = false
    private var startTime = 0L
    private var elapsedTime = 0L
    private var pausedTime = 0L
    private var totalDistance = 0.0
    private var currentSpeed = 0.0
    private var currentScore = 0
    
    // Trail tracking
    private val trailPoints = mutableListOf<LatLng>()
    private var polyline: Polyline? = null
    private var lastLocation: Location? = null
    
    // Simplified hex grid and territory tracking (no native H3 library)
    private val claimedCells = mutableSetOf<String>()
    private val trailCells = mutableListOf<String>()
    private val hexPolygons = mutableMapOf<String, Polygon>()
    private val nearbyRunners = mutableListOf<Marker>()
    private val HEX_GRID_SIZE = 0.001 // Approximate hex grid size in degrees
    
    // Timer
    private val handler = Handler(Looper.getMainLooper())
    private val timerRunnable = object : Runnable {
        override fun run() {
            if (isTracking && !isPaused) {
                elapsedTime = System.currentTimeMillis() - startTime - pausedTime
                updateTimeDisplay()
                handler.postDelayed(this, 1000)
            }
        }
    }
    
    companion object {
        private const val LOCATION_PERMISSION_REQUEST_CODE = 1
        private const val MIN_DISTANCE_BETWEEN_POINTS = 5.0 // meters
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        initializeViews()
        initializeLocationServices()
        initializeHexGrid()
        setupMapFragment()
        setupButtonListeners()
    }
    
    private fun initializeViews() {
        backButton = findViewById(R.id.back_button)
        distanceValue = findViewById(R.id.distance_value)
        timeValue = findViewById(R.id.time_value)
        speedValue = findViewById(R.id.speed_value)
        scoreValue = findViewById(R.id.score_value)
        startStopButton = findViewById(R.id.start_stop_button)
        pauseButton = findViewById(R.id.pause_button)
        centerLocationButton = findViewById(R.id.center_location_button)
        bankButton = findViewById(R.id.bank_button)
    }
    
    private fun initializeLocationServices() {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    onLocationUpdate(location)
                }
            }
        }
    }
    
    private fun initializeHexGrid() {
        // Simplified hex grid initialization - no native library required
        Toast.makeText(this, "Hex grid system initialized for demo", Toast.LENGTH_SHORT).show()
    }
    
    private fun setupMapFragment() {
        val mapFragment = supportFragmentManager.findFragmentById(R.id.map) as SupportMapFragment
        mapFragment.getMapAsync(this)
    }
    
    private fun setupButtonListeners() {
        backButton.setOnClickListener {
            finish() // Close current activity and go back
        }
        
        startStopButton.setOnClickListener {
            if (!isTracking) {
                startTracking()
            } else {
                stopTracking()
            }
        }
        
        pauseButton.setOnClickListener {
            if (isPaused) {
                resumeTracking()
            } else {
                pauseTracking()
            }
        }
        
        centerLocationButton.setOnClickListener {
            centerOnCurrentLocation()
        }
        
        bankButton.setOnClickListener {
            bankCurrentScore()
        }
        
        // Make score clickable to open leaderboard
        scoreValue.setOnClickListener {
            val intent = Intent(this, LeaderboardActivity::class.java)
            startActivity(intent)
        }
    }

    override fun onMapReady(googleMap: GoogleMap) {
        mMap = googleMap
        
        // Configure map settings
        mMap.mapType = GoogleMap.MAP_TYPE_NORMAL
        mMap.uiSettings.isZoomControlsEnabled = false
        mMap.uiSettings.isMyLocationButtonEnabled = false
        mMap.uiSettings.isCompassEnabled = true
        
        // Check and request location permissions
        if (checkLocationPermissions()) {
            enableMyLocation()
            centerOnCurrentLocation()
            addNearbyRunners()
        } else {
            requestLocationPermissions()
        }
    }
    
    private fun checkLocationPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestLocationPermissions() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }
    
    private fun enableMyLocation() {
        if (checkLocationPermissions()) {
            try {
                mMap.isMyLocationEnabled = true
            } catch (e: SecurityException) {
                Toast.makeText(this, "Location permission denied", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun centerOnCurrentLocation() {
        if (checkLocationPermissions()) {
            try {
                fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                    location?.let {
                        val currentLatLng = LatLng(it.latitude, it.longitude)
                        mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(currentLatLng, 18f))
                    }
                }
            } catch (e: SecurityException) {
                Toast.makeText(this, "Location permission denied", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun startTracking() {
        if (!checkLocationPermissions()) {
            requestLocationPermissions()
            return
        }
        
        isTracking = true
        isPaused = false
        startTime = System.currentTimeMillis()
        pausedTime = 0L
        totalDistance = 0.0
        trailPoints.clear()
        
        // Clear previous polyline
        polyline?.remove()
        
        // Start location updates
        startLocationUpdates()
        
        // Start timer
        handler.post(timerRunnable)
        
        // Update UI
        startStopButton.text = "STOP"
        pauseButton.visibility = Button.VISIBLE
        
        Toast.makeText(this, "Tracking started!", Toast.LENGTH_SHORT).show()
    }
    
    private fun stopTracking() {
        isTracking = false
        isPaused = false
        
        // Stop location updates
        stopLocationUpdates()
        
        // Stop timer
        handler.removeCallbacks(timerRunnable)
        
        // Update UI
        startStopButton.text = "START"
        pauseButton.visibility = Button.GONE
        
        // Show completion message
        Toast.makeText(
            this, 
            "Run completed! Distance: ${String.format("%.2f", totalDistance)} km", 
            Toast.LENGTH_LONG
        ).show()
        
        // Reset for next run
        resetGameState()
    }
    
    private fun pauseTracking() {
        if (isTracking && !isPaused) {
            isPaused = true
            pausedTime = System.currentTimeMillis() - startTime - elapsedTime
            stopLocationUpdates()
            pauseButton.text = "RESUME"
            Toast.makeText(this, "Tracking paused", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun resumeTracking() {
        if (isTracking && isPaused) {
            isPaused = false
            startLocationUpdates()
            handler.post(timerRunnable)
            pauseButton.text = "PAUSE"
            Toast.makeText(this, "Tracking resumed", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun resetGameState() {
        elapsedTime = 0L
        pausedTime = 0L
        totalDistance = 0.0
        currentSpeed = 0.0
        trailPoints.clear()
        lastLocation = null
        updateAllDisplays()
    }
    
    private fun startLocationUpdates() {
        if (!checkLocationPermissions()) return
        
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY, 2000
        ).apply {
            setMinUpdateDistanceMeters(5f)
            setMaxUpdateDelayMillis(5000)
        }.build()
        
        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
        } catch (e: SecurityException) {
            Toast.makeText(this, "Location permission denied", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun stopLocationUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }
    
    private fun onLocationUpdate(location: Location) {
        if (!isTracking || isPaused) return
        
        val currentLatLng = LatLng(location.latitude, location.longitude)
        
        // Calculate distance if we have a previous location
        lastLocation?.let { previousLocation ->
            val distance = calculateDistance(
                previousLocation.latitude, previousLocation.longitude,
                location.latitude, location.longitude
            )
            
            // Only add point if distance is significant enough
            if (distance >= MIN_DISTANCE_BETWEEN_POINTS) {
                totalDistance += distance / 1000.0 // Convert to kilometers
                trailPoints.add(currentLatLng)
                updateTrail()
            }
        }
        
        // Calculate speed (km/h)
        if (location.hasSpeed()) {
            currentSpeed = (location.speed * 3.6) // Convert m/s to km/h
        }
        
        lastLocation = location
        
        // Update H3 hex grid
        updateTrailHexes(location)
        
        // Check for loop closure and claim territory
        val enclosedCells = checkLoopClosure()
        if (enclosedCells.isNotEmpty()) {
            claimTerritory(enclosedCells)
            // Reset trail for next loop
            trailCells.clear()
        }
        
        updateAllDisplays()
    }
    
    private fun updateTrail() {
        if (trailPoints.size > 1) {
            // Remove old polyline
            polyline?.remove()
            
            // Create new polyline with gradient effect
            val polylineOptions = PolylineOptions()
                .addAll(trailPoints)
                .width(12f)
                .color(Color.parseColor("#FF6B35"))
                .geodesic(true)
            
            polyline = mMap.addPolyline(polylineOptions)
        }
    }
    
    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val earthRadius = 6371000.0 // Earth's radius in meters
        
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        
        val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    private fun updateAllDisplays() {
        updateDistanceDisplay()
        updateSpeedDisplay()
        updateTimeDisplay()
        updateScoreDisplay()
    }
    
    private fun updateDistanceDisplay() {
        distanceValue.text = String.format("%.2f", totalDistance)
    }
    
    private fun updateSpeedDisplay() {
        speedValue.text = String.format("%.1f", currentSpeed)
    }
    
    private fun updateTimeDisplay() {
        val seconds = (elapsedTime / 1000) % 60
        val minutes = (elapsedTime / 1000) / 60
        timeValue.text = String.format("%02d:%02d", minutes, seconds)
    }
    
    private fun updateScoreDisplay() {
        scoreValue.text = currentScore.toString()
    }
    
    private fun bankCurrentScore() {
        if (currentScore > 0) {
            Toast.makeText(
                this,
                "Score banked: $currentScore points! (Simulated for demo)",
                Toast.LENGTH_LONG
            ).show()
            
            // For demo: reset current score after banking
            currentScore = 0
            updateScoreDisplay()
        } else {
            Toast.makeText(this, "No score to bank!", Toast.LENGTH_SHORT).show()
        }
    }
    
    // Simplified Hex Grid Methods (No native H3 library required)
    private fun generateCellId(lat: Double, lng: Double): String {
        // Create a simple grid-based cell ID using coordinate rounding
        val gridLat = (lat / HEX_GRID_SIZE).toInt()
        val gridLng = (lng / HEX_GRID_SIZE).toInt()
        return "${gridLat}_${gridLng}"
    }
    
    private fun drawHexCell(cellId: String, color: Int, fillColor: Int) {
        try {
            // Parse cell ID to get grid coordinates
            val parts = cellId.split("_")
            if (parts.size != 2) return
            
            val gridLat = parts[0].toInt()
            val gridLng = parts[1].toInt()
            
            // Create a simple rectangular "hex" cell for demo
            val centerLat = gridLat * HEX_GRID_SIZE
            val centerLng = gridLng * HEX_GRID_SIZE
            val halfSize = HEX_GRID_SIZE / 2
            
            val polygonOptions = PolygonOptions()
                .add(LatLng(centerLat - halfSize, centerLng - halfSize))
                .add(LatLng(centerLat - halfSize, centerLng + halfSize))
                .add(LatLng(centerLat + halfSize, centerLng + halfSize))
                .add(LatLng(centerLat + halfSize, centerLng - halfSize))
                .strokeColor(color)
                .strokeWidth(3f)
                .fillColor(fillColor)
            
            val polygon = mMap.addPolygon(polygonOptions)
            hexPolygons[cellId] = polygon
            
        } catch (e: Exception) {
            // Handle errors silently for demo
        }
    }
    
    private fun updateTrailHexes(location: Location) {
        try {
            val cellId = generateCellId(location.latitude, location.longitude)
            
            if (!trailCells.contains(cellId)) {
                trailCells.add(cellId)
                // Draw trail cell in orange
                drawHexCell(cellId, Color.parseColor("#FF6B35"), Color.parseColor("#33FF6B35"))
            }
        } catch (e: Exception) {
            // Handle errors silently for demo
        }
    }
    
    private fun checkLoopClosure(): List<String> {
        if (trailCells.size < 4) return emptyList()
        
        try {
            val startCell = trailCells.first()
            val currentCell = trailCells.last()
            
            // Simple loop closure: check if current cell is near the start cell
            val startParts = startCell.split("_")
            val currentParts = currentCell.split("_")
            
            if (startParts.size == 2 && currentParts.size == 2) {
                val startLat = startParts[0].toInt()
                val startLng = startParts[1].toInt()
                val currentLat = currentParts[0].toInt()
                val currentLng = currentParts[1].toInt()
                
                val distance = abs(startLat - currentLat) + abs(startLng - currentLng)
                
                if (distance <= 2 && trailCells.size > 3) {
                    // For demo: create some mock enclosed cells
                    val enclosedCells = mutableListOf<String>()
                    val trailSet = trailCells.toSet()
                    
                    // Add some cells "inside" the rough trail boundary
                    for (i in 0 until min(5, trailCells.size / 2)) {
                        val mockCellId = "${startLat + i}_${startLng + i}"
                        if (!trailSet.contains(mockCellId) && !claimedCells.contains(mockCellId)) {
                            enclosedCells.add(mockCellId)
                        }
                    }
                    
                    return enclosedCells
                }
            }
        } catch (e: Exception) {
            // Handle errors silently for demo
        }
        
        return emptyList()
    }
    
    private fun claimTerritory(newCells: List<String>) {
        newCells.forEach { cellId ->
            claimedCells.add(cellId)
            // Remove existing polygon if any
            hexPolygons[cellId]?.remove()
            // Draw claimed cell in green
            drawHexCell(cellId, Color.parseColor("#4CAF50"), Color.parseColor("#664CAF50"))
        }
        
        currentScore += newCells.size * 10
        Toast.makeText(this, "Territory claimed! +${newCells.size * 10} points", Toast.LENGTH_SHORT).show()
    }
    
    private fun addNearbyRunners() {
        // Add 2-3 fake nearby runners as specified in README
        val fakeRunners = listOf(
            LatLng(30.7333 + 0.001, 76.7794 + 0.001),
            LatLng(30.7333 - 0.002, 76.7794 + 0.002),
            LatLng(30.7333 + 0.0015, 76.7794 - 0.001)
        )
        
        fakeRunners.forEachIndexed { index, position ->
            val marker = mMap.addMarker(
                MarkerOptions()
                    .position(position)
                    .title("Runner ${index + 1}")
                    .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_BLUE))
            )
            marker?.let { nearbyRunners.add(it) }
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            LOCATION_PERMISSION_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() && 
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    enableMyLocation()
                    centerOnCurrentLocation()
                } else {
                    Toast.makeText(
                        this,
                        "Location permission is required for tracking",
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopLocationUpdates()
        handler.removeCallbacks(timerRunnable)
    }
}
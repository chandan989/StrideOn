
import Foundation
import CoreLocation
import Combine

@MainActor
class MockData: ObservableObject {
    static let shared = MockData()
    
    @Published var gameState: GameState
    @Published var timeRemaining: TimeInterval = 3600 // 1 hour
    @Published var isSessionActive: Bool = false
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastLocation: CLLocation? // Used for distance calcs inside game loop
    private var latestUserLocation: CLLocation? // Buffer for incoming GPS
    private var hasSpawnedNearbyUsers = false
    
    // Bot Physics
    private var botHeadings: [String: Double] = [:] // Headings in degrees
    private var physicsTicks = 0
    
    private init() {
        self.gameState = MockData.generateMockGameState()
        // Clear initial mock trails for a fresh start feeling
        self.gameState.activeTrail.points = []
        // Clear other trails initially, we will spawn them near the user
        self.gameState.otherTrails = []
        
        self.gameState.totalDistance = 0
        self.gameState.caloriesBurned = 0
        self.gameState.territoryClaimed = 0
        
        setupLocationUpdates()
    }
    
    func startSession() {
        guard !isSessionActive else { return }
        isSessionActive = true
        timeRemaining = 3600 // Reset to 1 hour
        gameState.totalDistance = 0
        gameState.caloriesBurned = 0
        gameState.territoryClaimed = 0
        gameState.activeTrail.points = []
        lastLocation = LocationManager.shared.userLocation
        physicsTicks = 0
        
        // If we have a location, ensure we have spawned users
        if let loc = lastLocation, !hasSpawnedNearbyUsers {
            spawnNearbyUsers(center: loc)
        }
        
        // High frequency timer for smooth movement (e.g., 5 Hz = 0.2s)
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.gameTick()
            }
        }
    }
    
    func stopSession() {
        isSessionActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func setupLocationUpdates() {
        LocationManager.shared.$userLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main) // Ensure we receive on main thread
            .sink { [weak self] location in
                guard let self = self else { return }
                
                // Spawn nearby users once if not done
                if !self.hasSpawnedNearbyUsers {
                     self.spawnNearbyUsers(center: location)
                }
                
                // Just buffer the location, do NOT update stats directly (Race condition fix)
                self.latestUserLocation = location
            }
            .store(in: &cancellables)
    }
    
    private func spawnNearbyUsers(center: CLLocation) {
        hasSpawnedNearbyUsers = true
        var newOtherTrails: [Trail] = []
        
        // Strict limit: 4 players + User = 5 total on map
        let count = 4
        // Predefined palette excluding user's Green (#00FF00)
        let availableColors = ["#00FFFF", "#FF0000", "#FF00FF", "#FFFF00"] // Cyan, Red, Magenta, Yellow
        
        for i in 0..<count {
            // Random offset within 1km (approx 0.009 degrees)
            let latOffset = Double.random(in: -0.009...0.009)
            let lngOffset = Double.random(in: -0.009...0.009)
            let startLat = center.coordinate.latitude + latOffset
            let startLng = center.coordinate.longitude + lngOffset
            
            let userId = "user_\(i)"
            
            let startPoint = RoutePoint(
                lat: startLat,
                lng: startLng,
                timestamp: Date(),
                sessionId: "session_other_\(i)"
            )
            
            // Assign unique color cyclically
            let color = availableColors[i % availableColors.count]
            
            let trail = Trail(
                id: "other_trail_\(i)",
                userId: userId,
                points: [startPoint],
                status: .active,
                colorHex: color
            )
            newOtherTrails.append(trail)
            
            // Initialize random heading (0-360 degrees)
            botHeadings[userId] = Double.random(in: 0...360)
        }
        
        self.gameState.otherTrails = newOtherTrails
    }
    
    // Unified Game Loop
    private func gameTick() {
        // Create a working copy of the state
        var currentGameState = self.gameState
        var newClaimedAreas: [ClaimedArea] = []
        
        // 1. Update Other Users (Bots)
        currentGameState.otherTrails = updateOtherTrails(trails: currentGameState.otherTrails, newClaimedAreas: &newClaimedAreas)

        // 2. Update Active User (You)
        if let userLoc = self.latestUserLocation {
            currentGameState = updateActiveUser(gameState: currentGameState, location: userLoc, newClaimedAreas: &newClaimedAreas)
        }
        
        // 2. CHECK TRAIL CUTTING (Intersections)
        // We check if any trail's HEAD intersects any OTHER trail's body.
        checkTrailCutting(gameState: &currentGameState)
        
        // 3. Update Global Stats & Time
        physicsTicks += 1
        if physicsTicks % 5 == 0 {
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopSession()
            }
        }
        
        // 4. Batch Commit: Apply all changes to published property at once
        if !newClaimedAreas.isEmpty {
             currentGameState.claimedAreas.append(contentsOf: newClaimedAreas)
        }
        
        self.gameState = currentGameState
    }

    // MARK: - Trail Cutting Logic
    
    private func checkTrailCutting(gameState: inout GameState) {
        // Collect all trails (Active User + Bots)
        // We use indices to identify them easily.
        // 0 = Active User, 1...N = Bots
        
        var allTrails: [Trail] = [gameState.activeTrail] + gameState.otherTrails
        
        // For each trail "Attacker"
        for i in 0..<allTrails.count {
            let attacker = allTrails[i]
            guard let headStart = attacker.points.dropLast().last,
                  let headEnd = attacker.points.last else { continue }
            
            // Check against every "Victim" trail
            for j in 0..<allTrails.count {
                if i == j { continue } // Don't cut self (that's a loop, handled elsewhere)
                
                let victim = allTrails[j]
                if victim.points.count < 2 { continue }
                
                // Check intersection with Victim's segments
                if checkIntersection(p1: headStart, p2: headEnd, trail: victim) {
                    // CUT DETECTED!
                    print("Trail Cut! \(attacker.userId) cut \(victim.userId)")
                    
                    // Reset the victim's trail
                    // Keep only the last point to restart
                    if let last = victim.points.last {
                        allTrails[j].points = [last]
                        allTrails[j].status = .cut
                    } else {
                        allTrails[j].points = []
                    }
                }
            }
        }
        
        // Write back to GameState
        gameState.activeTrail = allTrails[0]
        gameState.otherTrails = Array(allTrails.dropFirst())
    }
    
    private func checkIntersection(p1: RoutePoint, p2: RoutePoint, trail: Trail) -> Bool {
        // Check "Attacker" segment (p1->p2) against all segments of "Victim" trail
        let points = trail.points
        guard points.count > 1 else { return false }
        
        for k in 0..<(points.count - 1) {
            let v1 = points[k]
            let v2 = points[k+1]
            
            if segmentsIntersect(a: p1, b: p2, c: v1, d: v2) {
                return true
            }
        }
        return false
    }
    
    // Standard segment-segment intersection
    private func segmentsIntersect(a: RoutePoint, b: RoutePoint, c: RoutePoint, d: RoutePoint) -> Bool {
        let d1 = direction(c, d, a)
        let d2 = direction(c, d, b)
        let d3 = direction(a, b, c)
        let d4 = direction(a, b, d)
        
        if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
            return true
        }
        return false
    }
    
    // Using lat/lng as x/y for 2D intersection check
    private func direction(_ pi: RoutePoint, _ pj: RoutePoint, _ pk: RoutePoint) -> Double {
        return (pk.lat - pi.lat) * (pj.lng - pi.lng) - (pj.lat - pi.lat) * (pk.lng - pi.lng)
    }

    private func updateOtherTrails(trails: [Trail], newClaimedAreas: inout [ClaimedArea]) -> [Trail] {
        var updatedTrails = trails
        
        for i in 0..<updatedTrails.count {
            var trail = updatedTrails[i]
            guard let lastPoint = trail.points.last else { continue }
            let userId = trail.userId
            
            // Physics: Heading & Speed
            var heading = botHeadings[userId] ?? 0.0
            let steering = Double.random(in: -15...15) // More erratic steering
            heading += steering
            botHeadings[userId] = heading
            
            // Speed: Randomize slightly for variety (approx 1.5m to 3.5m per tick)
            let speed = Double.random(in: 0.000015...0.000030)
            
            let rad = heading * .pi / 180
            let latStep = cos(rad) * speed
            let lngStep = sin(rad) * speed
            
            let newLat = lastPoint.lat + latStep
            let newLng = lastPoint.lng + lngStep
            
            // Optimization: Distance Check
            let lastLoc = CLLocation(latitude: lastPoint.lat, longitude: lastPoint.lng)
            let newLoc = CLLocation(latitude: newLat, longitude: newLng)
            
            // Fixed: Reduced threshold to 0.5m so they actually move every tick (speed > 0.5m)
            // Re-adjusting to 2.0m for better storage efficiency and longer trails
            if lastLoc.distance(from: newLoc) > 2.0 {
                let newPoint = RoutePoint(
                    lat: newLat,
                    lng: newLng,
                    timestamp: Date(),
                    sessionId: lastPoint.sessionId
                )
                
                trail.points.append(newPoint)
                
                // Allow longer trails (1km history: 500 points * 2m)
                if trail.points.count > 500 {
                    let removeCount = trail.points.count - 500
                    trail.points.removeFirst(removeCount)
                }
                
                // Loop Detection
                if let claimedArea = detectLoop(in: trail, newPoint: newPoint) {
                    newClaimedAreas.append(claimedArea)
                }
                
                updatedTrails[i] = trail
            }
        }
        return updatedTrails
    }
    
    private func updateActiveUser(gameState: GameState, location: CLLocation, newClaimedAreas: inout [ClaimedArea]) -> GameState {
        var state = gameState
        
        // Use last processed location for distance check
        let lastProcessedLoc = state.activeTrail.points.last.map { CLLocation(latitude: $0.lat, longitude: $0.lng) }
        
        let shouldAddPoint: Bool
        if let last = lastProcessedLoc {
            shouldAddPoint = location.distance(from: last) > 2.0
        } else {
            shouldAddPoint = true // First point
        }
        
        if shouldAddPoint {
            let newPoint = RoutePoint(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude,
                timestamp: Date(),
                sessionId: state.currentSessionId
            )
            
            state.activeTrail.points.append(newPoint)
            
            // STRICT MEMORY CAP
            if state.activeTrail.points.count > 500 {
                let removeCount = state.activeTrail.points.count - 500
                state.activeTrail.points.removeFirst(removeCount)
            }

            // Update Distances
            if let last = lastLocation { // Previous raw location
                let dist = location.distance(from: last)
                state.totalDistance += (dist / 1000.0)
                state.caloriesBurned += (dist * 0.06)
            }
            // Update raw pointer
            self.lastLocation = location 
            
            // Loop Detection
            if let claimedArea = detectLoop(in: state.activeTrail, newPoint: newPoint) {
                newClaimedAreas.append(claimedArea)
                let areaSqKm = calculatePolygonArea(points: claimedArea.points)
                state.territoryClaimed += areaSqKm
            }
        } else {
           // Even if we don't add a point, we might want to update calories/distance for small movements? 
           // For now, let's tie them to trail updates to stay consistent.
           // Avoiding frequent "micro" updates updates saves View refreshes.
        }
        
        return state
    }
    
    // Generalized Loop Detection
    private func detectLoop(in trail: Trail, newPoint: RoutePoint) -> ClaimedArea? {
         let points = trail.points
         let count = points.count
         
         // Need at least a few points to form a loop
         guard count > 10 else { return nil }
         
         let currentLocation = CLLocation(latitude: newPoint.lat, longitude: newPoint.lng)
         
         // Check previous points (ignoring the most recent ~10)
         let threshold: Double = 20.0 // meters
         let minimumLoopSize = 10
         
         for i in (0..<(count - minimumLoopSize)).reversed() {
             let point = points[i]
             let pLoc = CLLocation(latitude: point.lat, longitude: point.lng)
             let dist = currentLocation.distance(from: pLoc)
             
             if dist < threshold {
                 // LOOP DETECTED!
                 // Extract the loop: from i to end
                 let loopPoints = Array(points[i..<count])
                 
                 // Create Claimed Area with the user's color
                 return ClaimedArea(
                     userId: trail.userId,
                     points: loopPoints,
                     colorHex: trail.colorHex // Consistent color
                 )
             }
         }
         return nil
    }
    
    private func calculatePolygonArea(points: [RoutePoint]) -> Double {
        // Simple client-side approximation for immediate feedback.
        // The backend will perform precise geodesic area calculations using H3.
        guard points.count > 2 else { return 0 }
        return 0.05 // Placeholder value for visual reward
    }
    
    static func generateMockGameState() -> GameState {
        let currentSessionId = "session_123"
        
        // Main User Route (Green)
        let mainRoutePoints: [RoutePoint] = [
            RoutePoint(lat: 26.8500, lng: 80.9499, timestamp: Date(), sessionId: currentSessionId),
            RoutePoint(lat: 26.8515, lng: 80.9515, timestamp: Date().addingTimeInterval(60), sessionId: currentSessionId),
            RoutePoint(lat: 26.8525, lng: 80.9535, timestamp: Date().addingTimeInterval(120), sessionId: currentSessionId)
        ]
        
        // Other trails will be generated dynamically near user

        let mainTrail = Trail(
            id: "main_trail",
            userId: "current_user",
            points: mainRoutePoints,
            status: .active,
            colorHex: "#00FF00" // Green
        )
        
        let mockUser = UserProfile(
            id: "current_user",
            userName: "Chandan",
            veryUserId: "very_auth_token_mock",
            wepinAddress: "0x1234567890abcdef",
            city: "Lucknow",
            avatarUrl: nil
        )
        
        return GameState(
            currentSessionId: currentSessionId,
            currentUser: mockUser,
            activeTrail: mainTrail,
            claimedAreas: [],
            otherTrails: [], // Empty initially
            totalDistance: 0.5,
            caloriesBurned: 150.0,
            territoryClaimed: 0.1
        )
    }
}

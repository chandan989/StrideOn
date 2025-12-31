
import Foundation
import CoreLocation

// MARK: - Core Data Structures

struct RoutePoint: Identifiable, Codable {
    var id: UUID = UUID()
    let lat: Double
    let lng: Double
    let timestamp: Date
    let sessionId: String? // Added to match backend, optional for now as legacy data might not have it
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    enum CodingKeys: String, CodingKey {
        case lat, lng, timestamp
        case sessionId = "session_id"
    }
}

struct UserProfile: Codable, Identifiable {
    var id: String // This maps to user_id
    var userName: String?
    var veryUserId: String?
    var wepinAddress: String?
    var city: String?
    var avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case userName = "user_name"
        case veryUserId = "very_user_id"
        case wepinAddress = "wepin_address"
        case city
        case avatarUrl = "avatar_url"
    }
}

struct Trail: Identifiable, Codable {
    var id: String
    var userId: String
    var points: [RoutePoint]
    var status: TrailStatus
    var colorHex: String // For UI purposes
    
    enum TrailStatus: String, Codable {
        case active
        case completed
        case cut
    }
}

struct ClaimedArea: Identifiable, Codable {
    var id: UUID = UUID()
    var userId: String
    var points: [RoutePoint]
    var colorHex: String
}

struct GameState: Codable {
    var currentSessionId: String
    var currentUser: UserProfile? // Added to store current user info
    var activeTrail: Trail
    var claimedAreas: [ClaimedArea] // Areas conquered by looping
    var otherTrails: [Trail]
    var totalDistance: Double
    var caloriesBurned: Double
    var territoryClaimed: Double
    
    // Add any other game-related state provided by backend
}

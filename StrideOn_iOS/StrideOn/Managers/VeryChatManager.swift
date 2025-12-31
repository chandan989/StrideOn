import Foundation
import Combine

class VeryChatManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var userProfile: VeryChatUserProfile?
    @Published var debugLog: String = ""
    
    private let projectId = "4c91d123-03b8-4c8b-b7c9-8700ac95c22f"
    private let baseURL = "https://gapi.veryapi.io/auth"
    
    // Keys for persistence
    private let kIsAuthenticated = "very_is_authenticated"
    private let kAccessToken = "very_access_token"
    private let kProfileId = "very_profile_id"
    private let kProfileName = "very_profile_name"
    private let kProfileImage = "very_profile_image"
    
    init() {
        // Load persisted state
        self.isAuthenticated = UserDefaults.standard.bool(forKey: kIsAuthenticated)
        self.accessToken = UserDefaults.standard.string(forKey: kAccessToken)
        
        let pId = UserDefaults.standard.string(forKey: kProfileId)
        let pName = UserDefaults.standard.string(forKey: kProfileName)
        let pImage = UserDefaults.standard.string(forKey: kProfileImage)
        
        // Allow partial profile restore
        if pId != nil || pName != nil {
            self.userProfile = VeryChatUserProfile(profileId: pId, profileName: pName, profileImage: pImage)
        }
    }
    
    func requestVerificationCode(handleId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/request-verification-code") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            completion(false)
            return
        }
        
        let parameters: [String: Any] = [
            "projectId": projectId,
            "handleId": handleId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            self.errorMessage = "Failed to encode parameters"
            self.isLoading = false
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    completion(false)
                    return
                }
                
                // Debugging: Print response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Request Verification Response: \(jsonString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let statusCode = json["statusCode"] as? Int, statusCode == 200 {
                            completion(true)
                        } else {
                            self?.errorMessage = json["message"] as? String ?? "Unknown error"
                            completion(false)
                        }
                    }
                } catch {
                    self?.errorMessage = "Failed to decode response"
                    completion(false)
                }
            }
        }.resume()
    }
    
    func getTokens(handleId: String, verificationCode: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/get-tokens") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            completion(false)
            return
        }
        
        // Ensure verification code is treated as integer if possible, or string based on API requirement.
        let codeInt = Int(verificationCode) ?? 0
        
        let parameters: [String: Any] = [
            "projectId": projectId,
            "handleId": handleId,
            "verificationCode": codeInt
        ]
        
        print("Sending get-token params: \(parameters)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            self.errorMessage = "Failed to encode parameters"
            self.isLoading = false
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    completion(false)
                    return
                }

                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Get Tokens Response: \(jsonString)")
                    self?.debugLog = jsonString
                }

                do {
                    // Manual decoding to be resilient to missing fields like profileImage
                    let raw = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let dict = raw as? [String: Any] else {
                        self?.errorMessage = "Unexpected response format"
                        completion(false)
                        return
                    }

                    let statusCode = dict["statusCode"] as? Int ?? (dict["status"] as? Int ?? 0)
                    let accessToken = dict["accessToken"] as? String
                    let refreshToken = dict["refreshToken"] as? String // kept for potential future use

                    var userProfile: VeryChatUserProfile? = nil
                    if let userDict = dict["user"] as? [String: Any] {
                        let profileId = userDict["profileId"] as? String
                        let profileName = userDict["profileName"] as? String
                        let profileImage: String? = userDict.keys.contains("profileImage") ? (userDict["profileImage"] as? String) : nil
                        userProfile = VeryChatUserProfile(profileId: profileId, profileName: profileName, profileImage: profileImage)
                    } else {
                        // Some responses return profile fields at the top level (no nested `user` object)
                        let profileId = dict["profileId"] as? String
                        let profileName = dict["profileName"] as? String
                        let profileImage: String? = dict.keys.contains("profileImage") ? (dict["profileImage"] as? String) : nil
                        // Only construct a profile if at least one field is non-empty
                        if (profileId?.isEmpty == false) || (profileName?.isEmpty == false) || (profileImage?.isEmpty == false) {
                            userProfile = VeryChatUserProfile(profileId: profileId, profileName: profileName, profileImage: profileImage)
                        }
                    }

                    if statusCode == 200 {
                        self?.accessToken = accessToken
                        self?.userProfile = userProfile
                        self?.isAuthenticated = true

                        UserDefaults.standard.set(true, forKey: self?.kIsAuthenticated ?? "very_is_authenticated")
                        if let at = accessToken {
                            UserDefaults.standard.set(at, forKey: self?.kAccessToken ?? "very_access_token")
                        }
                        if let user = userProfile {
                            if let pId = user.profileId { UserDefaults.standard.set(pId, forKey: self?.kProfileId ?? "very_profile_id") }
                            if let pName = user.profileName { UserDefaults.standard.set(pName, forKey: self?.kProfileName ?? "very_profile_name") }
                            // Persist profile image if present, otherwise clear any stale value
                            if let pImage = user.profileImage {
                                UserDefaults.standard.set(pImage, forKey: self?.kProfileImage ?? "very_profile_image")
                            } else {
                                UserDefaults.standard.removeObject(forKey: self?.kProfileImage ?? "very_profile_image")
                            }
                        }

                        completion(true)
                    } else {
                        let message = dict["message"] as? String
                        self?.errorMessage = message ?? "Authentication failed"
                        completion(false)
                    }
                } catch {
                    print("Manual Decoding Error: \(error)")
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = json["message"] as? String {
                        self?.errorMessage = message
                    } else {
                        self?.errorMessage = "Failed to decode token response: \(error.localizedDescription)"
                    }
                    completion(false)
                }
            }
        }.resume()
    }
    
    func logout() {
        self.isAuthenticated = false
        self.accessToken = nil
        self.userProfile = nil
        
        UserDefaults.standard.removeObject(forKey: kIsAuthenticated)
        UserDefaults.standard.removeObject(forKey: kAccessToken)
        UserDefaults.standard.removeObject(forKey: kProfileId)
        UserDefaults.standard.removeObject(forKey: kProfileName)
        UserDefaults.standard.removeObject(forKey: kProfileImage)
    }
    
    struct VeryChatTokenResponse: Codable {
        let statusCode: Int
        let accessToken: String?
        let refreshToken: String?
        let user: VeryChatUserProfile?
        let message: String?
    }
    
    struct VeryChatUserProfile: Codable {
        let profileId: String?
        let profileName: String?
        let profileImage: String?
    }
}

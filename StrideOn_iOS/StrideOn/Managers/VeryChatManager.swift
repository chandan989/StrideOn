
import Foundation
import Combine

class VeryChatManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var userProfile: VeryChatUserProfile?
    
    private let projectId = "4c91d123-03b8-4c8b-b7c9-8700ac95c22f"
    private let baseURL = "https://gapi.veryapi.io/auth"
    
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
        // The example showed integer `123456`.
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
                 }
                
                do {
                     let decoder = JSONDecoder()
                     let response = try decoder.decode(VeryChatTokenResponse.self, from: data)
                     
                     if response.statusCode == 200 {
                         self?.accessToken = response.accessToken
                         self?.userProfile = response.user
                         self?.isAuthenticated = true
                         completion(true)
                     } else {
                         self?.errorMessage = response.message ?? "Authentication failed"
                         completion(false)
                     }
                } catch {
                    // Try parsing as simple error dict if struct decode fails
                     if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                        let message = json["message"] as? String {
                         self?.errorMessage = message
                     } else {
                         self?.errorMessage = "Failed to decode token response"
                     }
                     completion(false)
                }
            }
        }.resume()
    }
}

struct VeryChatTokenResponse: Codable {
    let statusCode: Int
    let accessToken: String?
    let refreshToken: String?
    let user: VeryChatUserProfile?
    let message: String?
}

struct VeryChatUserProfile: Codable {
    let profileId: String
    let profileName: String
    let profileImage: String?
}

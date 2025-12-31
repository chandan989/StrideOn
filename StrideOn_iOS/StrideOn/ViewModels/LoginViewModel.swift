//
//  LoginViewModel.swift
//  StrideOn
//
//  Created by Chandan on 30/12/25.
//

import Foundation
import AuthenticationServices
import Combine

@MainActor
class LoginViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    @Published var emailText: String = ""
    @Published var passwordText: String = ""
    @Published var errorText: String = ""
    @Published var successText: String = ""
    @Published var otp = ""
    @Published var isLoading = false
    @Published var isPasswordVisible = false
    @Published var isSuccess = false
    @Published var hasError = false
    @Published var accessToken: String = ""
    @Published var refreshToken: String = ""
    @Published var LoggedIn = false
    @Published var notVerified = false
    
    @Published var inputError = false
    @Published var inputErrorText = ""
    
    private var appleSignInController: ASAuthorizationController?

    func login() {
        self.isLoading = true
//        let user = UserLogin(email: emailText, password: passwordText)
//        
//        NetworkService.shared.login(user: user) { result in
//            DispatchQueue.main.async {
//                self.isLoading = false
//                switch result {
//                case .success(let token):
//                    self.accessToken = token.access_token
//                    self.LoggedIn = true
//                case .failure(let error):
//                    self.errorText = error.localizedDescription
//                    self.hasError = true
//                }
//            }
//        }
    }
}

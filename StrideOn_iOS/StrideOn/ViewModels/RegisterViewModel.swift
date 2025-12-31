//
//  RegisterViewModel.swift
//  StrideOn
//
//  Created by Chandan on 29/12/25.
//

import SwiftUI
import AuthenticationServices
import Combine

@MainActor
class RegisterViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    @Published var emailText: String = ""
    @Published var passwordText: String = ""
    @Published var walletAddressText: String = ""
    @Published var countryText: String = ""
    
    @Published var isLoading = false
    @Published var isPasswordVisible = false
    @Published var hasError = false
    @Published var isSuccess: Bool = false
    @Published var LoggedIn: Bool = false
    @Published var successText: String = ""
    @Published var errorText: String = ""
    
    @Published var otp = ""
    @Published var notVerified = false
    
    @Published var inputError = false
    @Published var inputErrorText = ""
    
    @Published var isChecked = false
    
    private var appleSignInController: ASAuthorizationController?

    func register() {
        self.isLoading = true
//        let user = UserCreate(email: emailText, wallet_address: walletAddressText, password: passwordText)
//        
//        NetworkService.shared.register(user: user) { result in
//            DispatchQueue.main.async {
//                self.isLoading = false
//                switch result {
//                case .success(let token):
//                    // Handle successful registration
//                    self.isSuccess = true
//                    self.successText = "Registration successful!"
//                case .failure(let error):
//                    self.errorText = error.localizedDescription
//                    self.hasError = true
//                }
//            }
//        }
    }
}


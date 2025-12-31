//
//  ForgotPasswordViewModel.swift
//  StrideOn
//
//  Created by Chandan on 30/12/25.
//

import Foundation
import Combine

@MainActor class ForgotPasswordViewModel: ObservableObject {
    @Published var emailText: String = ""
    @Published var errorText: String = ""
    @Published var successText: String = ""
    @Published var isLoading = false
    @Published var hasError = false
    @Published var isSuccess = false
    
    
}


import SwiftUI

struct VeryChatConnectionView: View {
    @StateObject private var manager = VeryChatManager()
    @State private var handleId: String = ""
    @State private var verificationCode: String = ""
    @State private var showVerificationInput = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    Spacer()
                    Text("Connect VeryChat")
                        .customFont(.semiBold, 20)
                        .foregroundColor(.white)
                    Spacer()
                    // Spacer to balance the back button
                    Image(systemName: "chevron.left").hidden()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Logo
                Image(.veryLogo) // Assuming .veryLogo exists as it was used in Home.swift
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                
                Text("Connect your VeryChat account to unlock exclusive features.")
                    .customFont(.regular, 16)
                    .foregroundColor(.nsTxt) // Assuming .nsTxt exists
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer().frame(height: 30)
                
                if !manager.isAuthenticated {
                    VStack(alignment: .leading, spacing: 15) {
                        
                        if !showVerificationInput {
                            // Step 1: Input Handle
                            Text("VeryChat Handle")
                                .customFont(.medium, 14)
                                .foregroundColor(.white)
                            
                            TextField("e.g. @username", text: $handleId)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            Button(action: {
                                manager.requestVerificationCode(handleId: handleId) { success in
                                    if success {
                                        withAnimation {
                                            showVerificationInput = true
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    if manager.isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Send Code")
                                            .customFont(.bold, 18)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(20)
                            }
                            .disabled(handleId.isEmpty || manager.isLoading)
                            .opacity(handleId.isEmpty ? 0.6 : 1.0)
                            
                        } else {
                            // Step 2: Input Code
                            Text("Verification Code")
                                .customFont(.medium, 14)
                                .foregroundColor(.white)
                            
                            TextField("123456", text: $verificationCode)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                            
                            Button(action: {
                                manager.getTokens(handleId: handleId, verificationCode: verificationCode) { success in
                                    // Handle success is mainly handled by view state update
                                }
                            }) {
                                HStack {
                                    if manager.isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Connect")
                                            .customFont(.bold, 18)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(20)
                            }
                            .disabled(verificationCode.isEmpty || manager.isLoading)
                            .opacity(verificationCode.isEmpty ? 0.6 : 1.0)
                            
                            Button("Change Handle") {
                                withAnimation {
                                    showVerificationInput = false
                                    verificationCode = ""
                                }
                            }
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                            .font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    if let error = manager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                } else {
                    // Success State
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.green)
                        
                        Text("Connected!")
                            .customFont(.bold, 24)
                            .foregroundColor(.white)
                        
                        if let user = manager.userProfile {
                            HStack {
                                AsyncImage(url: URL(string: user.profileImage ?? "")) { image in
                                    image.resizable()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(user.profileName)
                                        .customFont(.bold, 18)
                                        .foregroundColor(.white)
                                    Text("@\(user.profileId)")
                                        .customFont(.regular, 14)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                        }
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Done")
                                .customFont(.bold, 18)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 30)
                        
                        NavigationLink(destination: VeryChatWebView(accessToken: manager.accessToken)) {
                            Text("Open Chat")
                                .customFont(.bold, 18)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentColor"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 30)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    VeryChatConnectionView()
}

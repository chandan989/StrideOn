import SwiftUI

struct VeryChatConnectionView: View {
    @StateObject private var manager = VeryChatManager()
    @State private var handleId: String = ""
    @State private var verificationCode: String = ""
    @State private var showVerificationInput = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    Spacer()
                    Text(manager.isAuthenticated ? "My Profile" : "Connect VeryChat")
                        .customFont(.semiBold, 20)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.left").hidden() // Spacer to balance the back button
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Logo
                Image(.veryLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                
                if !manager.isAuthenticated {
                    Text("Connect your VeryChat account to unlock exclusive features.")
                        .customFont(.regular, 16)
                        .foregroundColor(.nsTxt)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
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
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            
                            Button(action: {
                                manager.requestVerificationCode(handleId: handleId) { success in
                                    if success {
                                        withAnimation { showVerificationInput = true }
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
                            
                            Button("I already have a code") {
                                withAnimation {
                                    manager.errorMessage = nil
                                    showVerificationInput = true
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.top, 10)
                            .font(.system(size: 14))
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
                                manager.getTokens(handleId: handleId, verificationCode: verificationCode) { _ in }
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
                    // Authenticated Profile State
                    VStack(spacing: 30) {
                        Spacer()
                        
                        // Show profile UI only if we actually have any user data; otherwise show the unavailable message
                        if let user = manager.userProfile,
                           ((user.profileName?.isEmpty == false) ||
                            (user.profileId?.isEmpty == false) ||
                            (user.profileImage?.isEmpty == false)) {
                            VStack(spacing: 15) {
                                if let imageStr = user.profileImage, !imageStr.isEmpty, let url = URL(string: imageStr) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                             .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 10)
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(.white.opacity(0.9))
                                        .frame(width: 120, height: 120)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        .shadow(radius: 10)
                                }
                                
                                VStack(spacing: 5) {
                                    Text(user.profileName ?? "Unknown Name")
                                        .customFont(.bold, 24)
                                        .foregroundColor(.white)
                                    
                                    if let pId = user.profileId {
                                        Text("@\(pId)")
                                            .customFont(.regular, 16)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            .padding()
                        } else {
                            Text("Profile data currently unavailable.")
                                .customFont(.regular, 16)
                                .foregroundColor(.gray)
                                .padding()
                        }
                        
                        Spacer()
                        
                        Button(action: { manager.logout() }) {
                            Text("Disconnect")
                                .customFont(.bold, 18)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 30)
                        
                        Button(action: { dismiss() }) {
                            Text("Close")
                                .customFont(.bold, 18)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer().frame(height: 20)
                        
                        // Debug Output
//                        ScrollView {
//                            Text(manager.debugLog)
//                                .font(.caption2)
//                                .foregroundColor(.gray)
//                                .padding()
//                        }
//                        .frame(height: 100)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    VeryChatConnectionView()
}


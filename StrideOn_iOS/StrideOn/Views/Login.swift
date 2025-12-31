//
//  Login.swift
//  StrideOn
//
//  Created by Chandan on 29/12/25.
//

import SwiftUI
import AlertToast
import AuthenticationServices

struct Login: View {
    
    @StateObject var viewModel: LoginViewModel = LoginViewModel()
    @State var AlreadyHaveAccount: Bool = true
    @State private var sheetHeight: CGFloat = 300
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @FocusState private var isFocused: Bool

    var body: some View {
        
        if viewModel.LoggedIn && viewModel.notVerified == false{
//            ProfileSetup()
            Home()
        }else if !AlreadyHaveAccount{
            Register()
        }else{
            NavigationView{
                ZStack{
                    
                    VStack{
                        
                        Text("Welcome\nback, Buddy!")
                            .customFont(.semiBold,35)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if viewModel.isPasswordVisible == false{
                            
                            HStack {
                                Image("Filled_email")
                                    .foregroundStyle(.nsTxt)
                                
                                TextField("Enter your email", text: $viewModel.emailText)
                                    .font(.custom("Lufga-Regular", size: 15))
                                    .textInputAutocapitalization(.never)
                                    .foregroundColor(Color(.label))
                            }
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.inputBorders, lineWidth: 1)
                            )
                        }
                        
                        if viewModel.isPasswordVisible{
                            HStack {
                                Image("Filled_Lock")
                                    .foregroundStyle(.nsTxt)
                                
                                SecureField("Enter your password", text: $viewModel.passwordText)
                                    .font(.custom("Lufga-Regular", size: 15))
                                    .textInputAutocapitalization(.never)
                                    .foregroundColor(Color(.label))
                            }
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.inputBorders, lineWidth: 1)
                            )
                        }
                        
                        Spacer().frame(height: 30)
                        
                        if viewModel.isLoading{
                            ProgressView()
                        }else{
                            
                            SmallButton(
                                buttonText: viewModel.isPasswordVisible ? "Login" : "Continue",
                                buttonColor: .accent,
                                buttonTextColor: .black,
                                action: {
                                    
//                                    if viewModel.isPasswordVisible{
//                                        if viewModel.passwordText.isEmpty{
//                                            viewModel.inputError = true
//                                            viewModel.inputErrorText = "Please enter your password"
//                                        }else{
//                                            withAnimation {
////                                                viewModel.login()
//                                                //viewModel.LoggedIn.toggle()
//                                            }
//                                        }
//                                    }else{
//                                        if viewModel.emailText.isEmpty{
//                                            viewModel.inputError = true
//                                            viewModel.inputErrorText = "Please enter your email"
//                                        }else{
//                                            withAnimation{
//                                                viewModel.isPasswordVisible.toggle()
//                                            }
//                                        }
//                                    }
                                    
                                    
                                    viewModel.LoggedIn = true
                                    viewModel.notVerified = false
                                    
                                }
                            )
                            
                            
                        }
                        
                        Spacer().frame(height: 20)
                        
                        if viewModel.isPasswordVisible{
                            HStack{
                                Spacer()
                                
                                NavigationLink(destination: ForgotPassword()) {
                                    Text("Forgot password")
                                        .customFont(.regular, 15)
                                        .foregroundStyle(Color(.label))
                                    
                                }
                                
                            }
                        }
                        
                    }
                    .padding([.leading, .trailing], 30).frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                    
                    
                    VStack {
                        Spacer()
                        
                        HStack {
                            Text("Not a member?")
                                .customFont(.regular, 15)
                            
                            Button {
                                withAnimation {
                                    AlreadyHaveAccount = false
                                }
                            } label: {
                                Text("Register")
                                    .customFont(.semiBold, 15)
                                    .foregroundStyle(.accent)
                            }
                        }.frame(maxWidth: .infinity, minHeight: 30).background(Color(.systemBackground))
                    }
                    
                    VStack{
                        if viewModel.isPasswordVisible {
                            Button(action: {
                                withAnimation{
                                    viewModel.isPasswordVisible.toggle()
                                }
                            }) {
                                HStack {
                                    Spacer().frame(width: 20, height: 20)
                                    Image("back_icon").resizable().scaledToFit().frame(height: 20).foregroundStyle(Color(.label)).padding(.top, horizontalSizeClass == .regular ? 20 : 0)
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                    }
                }.background(Color(.systemBackground))
                    
            }.sheet(isPresented: $viewModel.notVerified ) {
                
                VStack(alignment: .center, spacing: 0) {
                    
                    Text("Verify Your Account")
                        .customFont(.semiBold, 20)
                        .foregroundStyle(Color(.label))
                    
                    Spacer().frame(height: 7)
                    
                    Text("Please enter the 6-digit code we set to")
                        .customFont(.regular, 13)
                        .foregroundStyle(Color(.nsTxt))
                    
                    Text(viewModel.emailText)
                        .customFont(.regular, 13)
                        .foregroundStyle(Color(.label))
                    
                    Spacer().frame(height: 20)
                    
                    ZStack {
                        // Visible OTP boxes
                        HStack(spacing: 15) {
                            ForEach(0..<3, id: \.self) { index in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color(.cards), lineWidth: 2)
                                        .frame(width: 35, height: 40)
                                    if index < viewModel.otp.count {
                                        Text(String(viewModel.otp[viewModel.otp.index(viewModel.otp.startIndex, offsetBy: index)]))
                                            .customFont(.regular, 20)
                                    }
                                }
                            }
                            Text("-")
                                .foregroundColor(Color(.label))
                            ForEach(3..<6, id: \.self) { index in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color(.cards), lineWidth: 2)
                                        .frame(width: 35, height: 40)
                                    if index < viewModel.otp.count {
                                        Text(String(viewModel.otp[viewModel.otp.index(viewModel.otp.startIndex, offsetBy: index)]))
                                            .customFont(.regular, 20)
                                    }
                                }
                            }
                        }
                        
                        // Transparent TextField overlay with an explicit tappable area
                        TextField("", text: $viewModel.otp)
                            .contentShape(Rectangle()) // makes the entire frame tappable
                            .keyboardType(.numberPad)
                            .focused($isFocused)
                            .foregroundColor(.clear)
                            .accentColor(.clear)
                            .frame(maxWidth: .infinity, maxHeight: 40)
                            .onChange(of: viewModel.otp) { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    viewModel.otp = filtered
                                }
                                if filtered.count > 6 {
                                    viewModel.otp = String(filtered.prefix(6))
                                }
                            }
                    }

                    
                    Spacer().frame(height: 20)
                    
                    Button{
//                        viewModel.requestVerificationCode()
                    }label: {
                        Text("Send Again").customFont(.semiBold, 15).foregroundStyle(Color(.label))
                    }
                    
                    Spacer().frame(height: 20)
                    
                    if viewModel.isLoading{
                        ProgressView()
                    }else{
                        Button{
                            
//                            viewModel.verifyAccount(code: viewModel.otp)
                        }label: {
                            Text("Continue")
                                .customFont(.semiBold,15)
                                .foregroundStyle(Color(.white))
                                .padding(15)
                                .frame(maxWidth: .infinity)
                                .background(Color(.black))
                                .cornerRadius(10)
                        }
                    }
                  
                }
                .padding(25).interactiveDismissDisabled(true)
                .overlay {GeometryReader { geometry in
                    Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                }
                }.onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                    sheetHeight = newHeight
                }.presentationDetents([.height(sheetHeight)])
                    .presentationCornerRadius(30)
                    .toast(isPresenting: $viewModel.hasError, duration: 2, tapToDismiss: true){
                    AlertToast(displayMode: .alert, type: .systemImage("exclamationmark.circle.fill", .aidiosRed), title: viewModel.errorText)
                }.onAppear(){
                    for scene in UIApplication.shared.connectedScenes {
                        if let windowScene = scene as? UIWindowScene {
                            for window in windowScene.windows {
                                let AppearanceMode: Int = UserDefaults.standard.integer(forKey: "appearance")
                                if AppearanceMode == 1{
                                    window.overrideUserInterfaceStyle = .light
                                }else if AppearanceMode == 2{
                                    window.overrideUserInterfaceStyle = .dark
                                }
                            }
                        }
                    }
                }.toast(isPresenting: $viewModel.isSuccess, duration: 2, tapToDismiss: true){
                    AlertToast(displayMode: .alert, type: .systemImage("checkmark.circle", .green), title: viewModel.successText)
                }
                
            }.toast(isPresenting: $viewModel.hasError, duration: 2, tapToDismiss: true){
                AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.circle.fill", .aidiosRed), title: viewModel.errorText)
            }.toast(isPresenting: $viewModel.inputError, duration: 2, tapToDismiss: true){
                AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.circle.fill", .aidiosRed), title: viewModel.inputErrorText)
            }.navigationBarBackButtonHidden(true).statusBar(hidden: true).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

#Preview {
    Login()
}

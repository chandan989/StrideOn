//
//  Register.swift
//  StrideOn
//
//  Created by Chandan on 29/12/25.
//

import SwiftUI
import AlertToast
import SwiftfulLoadingIndicators

struct Register: View {
    @StateObject var viewModel: RegisterViewModel = RegisterViewModel()
    @State var AlreadyHaveAccount: Bool = false
    @FocusState private var isFocused: Bool
    @State private var sheetHeight: CGFloat = 300
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if AlreadyHaveAccount {
            Login()
        } else {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        if horizontalSizeClass == .regular {
                            Spacer().frame(height: 50)
                        }

                        Text("Join us!")
                            .customFont(.semiBold, 30)
                            .padding(.bottom, 30)
                            .foregroundStyle(Color(.label))

                        // Email Input
                        InputBox(
                            title: "What's your email?",
                            imageName: "Filled_email",
                            placeholder: "Enter your Email",
                            value: $viewModel.emailText
                        )

                        Spacer().frame(height: 20)

                        // Password Input
                        PasswordField(password: $viewModel.passwordText)

                        Spacer().frame(height: 20)

                        // Country Picker
                        CountryPicker(country: $viewModel.countryText)

                        Spacer().frame(height: 20)

                        // Terms Row
                        TermsRow(isChecked: $viewModel.isChecked)

                        Spacer().frame(height: 20)

                        // Register Button
                        SmallButton(
                            buttonText: "Register",
                            buttonColor: .accent,
                            buttonTextColor: .black,
                            action: {
                                AlreadyHaveAccount = true
                            }
                        )

                        Spacer()
                    }
                    .padding([.leading, .trailing], 30)
                    .padding(.bottom, 50)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                }

                // Login link at bottom
                .safeAreaInset(edge: .bottom) {
                    HaveAccountButton {
                        withAnimation { AlreadyHaveAccount = true }
                    }
                }

                // Verification Sheet
                .sheet(isPresented: $viewModel.notVerified) {
                    VerificationSheet(viewModel: viewModel, isFocused: _isFocused, sheetHeight: $sheetHeight)
                }

                // Toasts
                .toast(isPresenting: $viewModel.isSuccess, duration: 2, tapToDismiss: true) {
                    AlertToast(displayMode: .alert, type: .systemImage("checkmark.circle", .green), title: viewModel.successText)
                }
                .toast(isPresenting: $viewModel.hasError) {
                    AlertToast(displayMode: .alert, type: .systemImage("exclamationmark.circle.fill", .aidiosRed), title: viewModel.errorText)
                }
                .toast(isPresenting: $viewModel.inputError, duration: 2, tapToDismiss: true) {
                    AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.circle.fill", .aidiosRed), title: viewModel.inputErrorText)
                }

                .background(Color(.systemBackground))

                // Loading Overlay
                .overlay {
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            LoadingIndicator(animation: .circleRunner)
                            Spacer().frame(height: 20)
                            Text("Creating your account...")
                                .customFont(.regular, 15)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                    }
                }
            }
            .statusBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                applyAppearance()
            }
        }
    }

    private func applyAppearance() {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    let mode = UserDefaults.standard.integer(forKey: "appearance")
                    if mode == 1 {
                        window.overrideUserInterfaceStyle = .light
                    } else if mode == 2 {
                        window.overrideUserInterfaceStyle = .dark
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

struct PasswordField: View {
    @Binding var password: String
    var body: some View {
        VStack(alignment: .leading) {
            Text("Create a password")
                .customFont(.semiBold, 17)
            HStack {
                Image("Filled_Lock")
                    .foregroundStyle(.nsTxt)
                SecureField("Enter your password", text: $password)
                    .textInputAutocapitalization(.never)
                    .foregroundColor(Color(.label))
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.inputBorders, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CountryPicker: View {
    @Binding var country: String
    var body: some View {
        Menu {
            ForEach(SpaceOptimizer.countries, id: \.self) { option in
                Button(option) { country = option }
            }
        } label: {
            VStack {
                Text("Where do you live?")
                    .customFont(.semiBold, 17)
                    .foregroundStyle(Color(.label))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Image("location_pin")
                        .foregroundStyle(.nsTxt)
                    TextField("Enter your country", text: $country)
                        .foregroundColor(Color(.label))
                        .font(Font.custom("Lufga-Regular", size: 15))
                        .multilineTextAlignment(.leading)
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.inputBorders, lineWidth: 1))
            }
        }
    }
}

struct TermsRow: View {
    @Binding var isChecked: Bool
    var body: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation { isChecked.toggle() }
            } label: {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isChecked ? Color(.label) : Color(.inputBorders))
            }
            .padding(.trailing, 10)

            Text("Agree to the ")
                .customFont(.regular, 13)
                .foregroundStyle(Color(.label))
            NavigationLink(destination: Login()) {
                Text("Terms of Use")
                    .customFont(.regular, 13)
                    .foregroundStyle(.accent)
            }
            Spacer()
        }
    }
}

struct HaveAccountButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text("Have an account?")
                    .customFont(.regular, 15)
                    .foregroundStyle(Color(.label))
                Text("Login")
                    .customFont(.semiBold, 15)
                    .foregroundStyle(.accent)
            }
            .frame(maxWidth: .infinity, minHeight: 30)
        }
    }
}

// MARK: - Verification Sheet
struct VerificationSheet: View {
    @ObservedObject var viewModel: RegisterViewModel
    @FocusState var isFocused: Bool
    @Binding var sheetHeight: CGFloat

    var body: some View {
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

            OTPInputView(otp: $viewModel.otp, isFocused: _isFocused)

            Spacer().frame(height: 20)

            Button { princ() } label: {
                Text("Send Again").customFont(.semiBold, 15).foregroundStyle(Color(.label))
            }

            Spacer().frame(height: 20)

            if viewModel.isLoading {
                ProgressView()
            } else {
                Button {
//                    viewModel.verifyAccount(code: viewModel.otp)
                } label: {
                    Text("Continue")
                        .customFont(.semiBold, 15)
                        .foregroundStyle(Color(.white))
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .background(Color(.black))
                        .cornerRadius(10)
                }
            }
        }
        .padding(25)
        .interactiveDismissDisabled(true)
        .overlay {
            GeometryReader { geometry in
                Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
            sheetHeight = newHeight
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationCornerRadius(30)
        .toast(isPresenting: $viewModel.hasError, duration: 2, tapToDismiss: true) {
            AlertToast(displayMode: .alert, type: .systemImage("exclamationmark.circle.fill", .aidiosRed), title: viewModel.errorText)
        }
        .toast(isPresenting: $viewModel.isSuccess, duration: 2, tapToDismiss: true) {
            AlertToast(displayMode: .alert, type: .systemImage("checkmark.circle", .green), title: viewModel.successText)
        }
    }
}

// MARK: - OTP Components
struct OTPInputView: View {
    @Binding var otp: String
    @FocusState var isFocused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 15) {
                ForEach(0..<3, id: \.self) { index in
                    OTPBoxView(character: character(at: index))
                }
                Text("-").foregroundColor(Color(.label))
                ForEach(3..<6, id: \.self) { index in
                    OTPBoxView(character: character(at: index))
                }
            }

            TextField("", text: $otp)
                .contentShape(Rectangle())
                .keyboardType(.numberPad)
                .focused($isFocused)
                .foregroundColor(.clear)
                .accentColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: 40)
                .onChange(of: otp) { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue { otp = filtered }
                    if filtered.count > 6 { otp = String(filtered.prefix(6)) }
                }
        }
    }

    private func character(at index: Int) -> String? {
        guard index < otp.count else { return nil }
        return String(otp[otp.index(otp.startIndex, offsetBy: index)])
    }
}

struct OTPBoxView: View {
    let character: String?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(.cards), lineWidth: 2)
                .frame(width: 35, height: 40)
            if let char = character {
                Text(char).customFont(.regular, 20)
            }
        }
    }
}

#Preview {
    Register()
}

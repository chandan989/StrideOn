//
//  ForgotPassword.swift
//  StrideOn
//
//  Created by Chandan on 30/12/25.
//

import SwiftUI
import AlertToast

struct ForgotPassword: View {
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: ForgotPasswordViewModel = ForgotPasswordViewModel()
    
    var body: some View {

        ZStack{
            
            VStack{
                
                Text("Trouble\nLogging In?")
                    .customFont(.semiBold,35)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Image("Filled_email")
                        .foregroundStyle(.nsTxt)
                    
                    TextField("Enter your email", text: $viewModel.emailText)
                        .textInputAutocapitalization(.never)
                        .foregroundColor(Color(.label))
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.inputBorders, lineWidth: 1)
                )
                
                
                Spacer().frame(height: 30)
                
                if viewModel.isLoading{
                    ProgressView()
                }else{
                    
                    SmallButton(
                        buttonText: "Recover",
                        buttonColor: .accent,
                        buttonTextColor: .black,
                        action: {
//                            viewModel.request_email()
                        }
                    )
                    
                    
                }
                
                Spacer().frame(height: 20)
                
                Text("Enter your email and we’ll send you a link to get you back into your account.")
                    .customFont(.regular, 15)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.nsTxt)
                    .padding([.leading, .trailing],5)
                
                
            }
            .padding([.leading, .trailing], 30)
            
            VStack{
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Spacer().frame(width: 20, height: 20)
                        Image("back_icon").resizable().scaledToFit().frame(height: 20).foregroundStyle(Color(.label))
                        Spacer()
                    }
                }
                Spacer()
            }
        }.background(Color(.systemBackground)).onAppear(){
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
        }
        .toast(isPresenting: $viewModel.isSuccess, duration: 2, tapToDismiss: true){
            AlertToast(displayMode: .alert, type: .systemImage("checkmark.circle", .green), title: viewModel.successText)
        }.toast(isPresenting: $viewModel.hasError, duration: 2, tapToDismiss: true){
            AlertToast(displayMode: .alert, type: .systemImage("exclamationmark.circle.fill", .aidiosRed), title: viewModel.errorText)
        }.navigationBarBackButtonHidden(true).statusBar(hidden: true)
        
    }
}


#Preview {
    ForgotPassword()
}

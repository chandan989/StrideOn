//
//  ContentView.swift
//  StrideOn
//
//  Created by Chandan on 29/12/25.
//

import SwiftUI

struct Welcome: View {
    @State private var scale: CGFloat = 1.0
    @State var isActive: Bool = false
    @State var showRegisterView: Bool = false
    @State var showConnectionView: Bool = false
    @EnvironmentObject var wepinManager: WepinManager
    @EnvironmentObject var veryChatManager: VeryChatManager
    
    private var userProfileIsEmpty: Bool { !veryChatManager.isAuthenticated }
    
    var body: some View {
        ZStack {
            if showRegisterView {
                Home()
            } else {
                ZStack {
                    HStack{
                        Spacer()
                        Text("")
                    }
                    
                    VStack{
                        
                        Spacer()
                        
                        Image(.logo)
                            .resizable()
                            .foregroundColor(Color(.black))
                            .scaledToFit()
                            .frame(width: 150)
                        //                    .scaleEffect(scale) // Apply scaling effect
                        //                    .onAppear {
                        //                        // Scale animation for a popping effect
                        //                        withAnimation(Animation.easeInOut(duration: 0.5)) {
                        //                            scale = 1.1
                        //                        }
                        //                    }
                        //                    .onAppear {
                        //                        // Reset scale back to 1 after a delay
                        //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        //                            withAnimation {
                        //                                scale = 1.0
                        //                            }
                        //                        }
                        //                    }
                        
                        Spacer()
                        Text("StrideOn")
                            .customFont(.bold,30)
                            .foregroundStyle(.black)
                        
                        if isActive && userProfileIsEmpty {
                            Text("Your city is your\narena.")
                                .customFont(.bold,30)
                                .foregroundStyle(.black).multilineTextAlignment(.center)
                            
                            Button{
                                withAnimation {
                                    showConnectionView = true
                                }
                            } label: {
                                Text("Join!")
                                    .customFont(.bold,20)
                            }
                            .padding([.top, .bottom], 15)
                            .padding([.leading, .trailing], 30)
                            .foregroundStyle(.white)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                }.onAppear{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            // Check if VeryChat is authenticated
                            if veryChatManager.isAuthenticated {
                                self.showRegisterView = true // triggers Home()
                            } else if self.isActive {
                                self.showRegisterView = false
                            } else {
                                self.isActive = true
                            }
                        }
                    }
                    wepinManager.checkInitializationUsingRoot()
                }
                .background(Color.accentColor)
                .fullScreenCover(isPresented: $showConnectionView) {
                    VeryChatConnectionView()
                }
            }
        }
        .onChange(of: veryChatManager.isAuthenticated) { isAuthenticated in
            withAnimation {
                showRegisterView = isAuthenticated
                if isAuthenticated {
                    showConnectionView = false
                }
            }
        }
    }
    
    
    func promptUserToUpdate(appStoreVersion: String) {
        let alert = UIAlertController(title: "Update Available",
                                      message: "A shiny new update \(appStoreVersion) is here.\n Time to explore!",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Update Now!", style: .default, handler: { _ in
            if let url = URL(string: "https://apps.apple.com/app/6743492394") {
                UIApplication.shared.open(url)
            }
        }))

        // Retrieve the active window's root view controller
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
           let topController = keyWindow.rootViewController {
            topController.present(alert, animated: true, completion: nil)
        }
    }
}

#Preview {
    Welcome()
}

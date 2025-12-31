//
//  WepinManager.swift
//  StrideOn
//
//  Created by Antigravity on 30/12/25.
//

import Foundation
import SwiftUI
import WepinWidget
import Combine

class WepinManager: ObservableObject {
    @Published var isInitialized: Bool = false
    @Published var lifecycle: WepinLifeCycle = .notInitialized
    @Published var isAuthenticated: Bool = false
    @Published var userProfileIsEmpty: Bool = true
    
    // TODO: Replace with your actual App Key if needed, though usually App ID is enough for public init in some SDKs, 
    // but WepinWidgetParams requires appKey. 
    // Using placeholder based on Info.plist App ID: da2f065cb44fa7fd915a4796c6559246
    let appId = "da2f065cb44fa7fd915a4796c6559246"
    let appKey = "ak_live_PWX6lcDrUOv3GomnEC74r85QSnbt1dMHrXxPVm3JPmV" // PLACEHOLDER: USER MUST REPLACE THIS
    
    private var wepinWidget: WepinWidget?
    
    func initWepin(viewController: UIViewController) {
        guard wepinWidget == nil else { return }
        
        let params = WepinWidgetParams(
            viewController: viewController, appId: appId,
            appKey: appKey
        )
        
        do {
            wepinWidget = try WepinWidget(wepinWidgetParams: params)
            
            Task {
                do {
                    let attributes = WepinWidgetAttribute(defaultLanguage: "en", defaultCurrency: "USD")
                    let result = try await wepinWidget?.initialize(attributes: attributes)
                    
                    await MainActor.run {
                        self.isInitialized = true
                        print("Wepin Initialized: \(String(describing: result))")
                        checkStatus()
                    }
                } catch {
                    print("Wepin Initialization Error: \(error)")
                }
            }
        } catch {
            print("Wepin Widget Creation Error: \(error)")
        }
    }
    
    func checkStatus() {
        guard let widget = wepinWidget else { return }
        Task {
            do {
                let status = try await widget.getStatus()
                await MainActor.run {
                    self.lifecycle = status
                    print("Wepin Lifecycle: \(status)")
                    // Simple logic: if status implies we need login, then we are not authenticated.
                    // Ideally, we'd check for a user session specifically.
                    if status == .login || status == .loginBeforeRegister || status == .notInitialized {
                        self.isAuthenticated = false
                    }
                    // Note: If status is .initialized, sometimes it means we are ready but not logged in?
                    // Or maybe it means logged in? Assuming 'initialized' + no further action needed = logged in? 
                    // Actually, 'openWallet' treats 'initialized' as needing 'loginWithUI'. 
                    // So 'initialized' seems to be NOT authenticated.
                    // Thus, we primarily rely on explicit login success or maybe getAccounts?
                }
            } catch {
                print("Wepin Status Error: \(error)")
            }
        }
    }
    
    func openWallet(viewController: UIViewController) {
        guard let widget = wepinWidget, isInitialized else {
            print("Wepin not initialized")
            initWepin(viewController: viewController)
            return
        }
        
        Task {
            do {
                let status = try await widget.getStatus()
                print("Wepin Status before open: \(status)")
                
                switch status {
                case .login:
                    let result = try await widget.openWidget(viewController: viewController)
                    print("Widget Opened: \(result)")
                case .loginBeforeRegister:
                    let result = try await widget.register(viewController: viewController)
                    print("Register Result: \(result)")
                case .notInitialized, .initializing:
                    print("Wepin not ready")
                default:
                    // .initialized, .beforeLogin
                    let result = try await widget.loginWithUI(viewController: viewController, loginProviders: [])
                    print("Login Result: \(result)")
                    
                    if result.status == "success" {
                        if result.userStatus?.loginStatus == .registerRequired {
                             let regRes = try await widget.register(viewController: viewController)
                             print("Register after login: \(regRes)")
                             // verify register success
                        } else {
                            let openRes = try await widget.openWidget(viewController: viewController)
                            print("Widget Opened after login: \(openRes)")
                            await MainActor.run {
                                self.isAuthenticated = true
                                self.userProfileIsEmpty = false // Assuming full profile if successfully opened
                            }
                        }
                    }
                }
            } catch {
                print("Wepin Open/Login Error: \(error)")
            }
        }
    }
    
    func checkInitializationUsingRoot() {
        // Attempt to find the root view controller to initialize Wepin automatically
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
               let rootVC = window.rootViewController {
                print("Found root VC for Wepin auto-init: \(rootVC)")
                self.initWepin(viewController: rootVC)
            } else {
                print("Could not find root VC for Wepin auto-init")
                // Retailer logic? Retry maybe?
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                     self.checkInitializationUsingRoot()
                }
            }
        }
    }
}

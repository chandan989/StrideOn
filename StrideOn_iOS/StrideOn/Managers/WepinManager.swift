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
                        } else {
                            let openRes = try await widget.openWidget(viewController: viewController)
                            print("Widget Opened after login: \(openRes)")
                        }
                    }
                }
            } catch {
                print("Wepin Open/Login Error: \(error)")
            }
        }
    }
}

//
//  StrideOnApp.swift
//  StrideOn
//
//  Created by Chandan on 29/12/25.
//

import SwiftUI

@main
struct StrideOnApp: App {
    @StateObject private var wepinManager = WepinManager()
    
    var body: some Scene {
        WindowGroup {
            Welcome()
                .environmentObject(wepinManager)
        }
    }
}

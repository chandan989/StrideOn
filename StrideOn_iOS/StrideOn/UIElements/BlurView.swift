//
//  BlurView.swift
//  Elykid
//
//  Created by Chandan on 30/01/25.
//

import SwiftUI

struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        return UIVisualEffectView(effect: blurEffect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // No update needed
    }
}

#Preview {
    BlurView()
}

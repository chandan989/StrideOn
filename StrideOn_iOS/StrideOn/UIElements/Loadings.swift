//
//  Loadings.swift
//  Elykid
//
//  Created by Chandan on 20/02/25.
//

import SwiftUI

struct CircularProgressView: View {
    // 1
    @Binding var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(.label).opacity(0.5),
                    lineWidth: 10
                )
            Circle()
                // 2
                .trim(from: 0, to: progress)
                .stroke(
                    Color(.label),
                    style: StrokeStyle(
                        lineWidth: 10,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    CircularProgressView(progress: .constant(0.25)).frame(width: 30)
}

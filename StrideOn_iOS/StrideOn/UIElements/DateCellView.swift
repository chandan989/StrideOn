//
//  DateCellView.swift
//  Sonic Arena
//
//  Created by Chandan on 05/09/25.
//

import SwiftUI

struct DateCellView: View {
    let date: Date
    let isSelected: Bool

    // Static formatters for efficiency
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private static let numberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private var dayLetter: String {
        let day = Self.dayFormatter.string(from: date)
        return day.first.map { String($0) } ?? ""
    }

    private var dateNumber: String {
        Self.numberFormatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetter)
            Text(dateNumber)

            if isSelected {
                Image(systemName: "figure.run") // Replace with .runLogo if available
                    .resizable()
                    .scaledToFit()
                    .frame(height: 13)
            }
        }
        .font(.system(size: 13, weight: .semibold)) // Standard SwiftUI font
        .frame(width: 36, height: 56) // Adjusted for better tap target
        .padding(6)
        .foregroundColor(isSelected ? .white : .primary)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Color.green : Color.clear) // Replace with .signatureGreen
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray, lineWidth: 2) // Replace with .signatureGrey
                )
        )
    }
}

#Preview {
    HStack(spacing: 16) {
        DateCellView(date: Date(), isSelected: true)
        DateCellView(date: Date(), isSelected: false)
    }
    .padding()
}

//
//  Utils.swift
//  StrideOn
//
//  Created by Chandan on 29/12/25.
//

import SwiftUI
import UIKit

enum FontWeight {
    case thin
    case light
    case regular
    case medium
    case semiBold
    case bold
    case extraBold
    case black
}

extension Font {
    static let customFont: (FontWeight, CGFloat) -> Font = { fontType, size in
        switch fontType {
        case .thin:
            Font.custom("Lufga-Thin", size: size)
        case .light:
            Font.custom("Lufga-Light", size: size)
        case .regular:
            Font.custom("Lufga-Regular", size: size)
        case .medium:
            Font.custom("Lufga-Medium", size: size)
        case .semiBold:
            Font.custom("Lufga-SemiBold", size: size)
        case .bold:
            Font.custom("Lufga-Bold", size: size)
        case .extraBold:
            Font.custom("Lufga-ExtraBold", size: size)
        case .black:
            Font.custom("Lufga-Black", size: size)
        }
    }
}

extension Text {
    func customFont(_ fontWeight: FontWeight? = .regular, _ size: CGFloat? = nil) -> Text {
        return self.font(.customFont(fontWeight ?? .regular, size ?? 16))
    }
}

extension Color {
    init(hex string: String) {
        var string: String = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.hasPrefix("#") {
            _ = string.removeFirst()
        }

        // Double the last value if incomplete hex
        if !string.count.isMultiple(of: 2), let last = string.last {
            string.append(last)
        }

        // Fix invalid values
        if string.count > 8 {
            string = String(string.prefix(8))
        }

        // Scanner creation
        let scanner = Scanner(string: string)

        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        if string.count == 2 {
            let mask = 0xFF

            let g = Int(color) & mask

            let gray = Double(g) / 255.0

            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)

        } else if string.count == 4 {
            let mask = 0x00FF

            let g = Int(color >> 8) & mask
            let a = Int(color) & mask

            let gray = Double(g) / 255.0
            let alpha = Double(a) / 255.0

            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)

        } else if string.count == 6 {
            let mask = 0x0000FF
            let r = Int(color >> 16) & mask
            let g = Int(color >> 8) & mask
            let b = Int(color) & mask

            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0

            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)

        } else if string.count == 8 {
            let mask = 0x000000FF
            let r = Int(color >> 24) & mask
            let g = Int(color >> 16) & mask
            let b = Int(color >> 8) & mask
            let a = Int(color) & mask

            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0
            let alpha = Double(a) / 255.0

            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)

        } else {
            self.init(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        }
    }
}

func decodeOptionalString(_ input: String) -> String {
    // Remove "Optional(...)" wrapper if present
    let trimmed = input.replacingOccurrences(of: "Optional(", with: "")
                       .replacingOccurrences(of: ")", with: "")

    // Remove surrounding quotes if encoded
    let unwrapped = trimmed.removingPercentEncoding ?? trimmed
    return unwrapped.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
}

func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MM yyyy"
    return formatter.string(from: date)
}

func dateFromFormattedString(_ dateString: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MM yyyy"
    return formatter.date(from: dateString)
}

func TimeStampFromFormattedString(_ dateString: String) -> Date? {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "EEEE, MMMM d, yyyy 'at' hh:mm:ss a"
    inputFormatter.locale = Locale(identifier: "en_US_POSIX")
    return inputFormatter.date(from: dateString)
}

func formattedTime(_ date: Date) -> String {
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "hh:mm a"
    return outputFormatter.string(from: date)
}

func getTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    let dateString = formatter.string(from: Date())
    return dateString
}

func getDate() -> String {
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d MMM yyyy"
    return dateFormatter.string(from: date)
}

func convertDateString(input: String) -> String? {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    inputFormatter.locale = Locale(identifier: "en_US_POSIX")
    inputFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    guard let date = inputFormatter.date(from: input) else {
        return nil
    }

    let day = Calendar.current.component(.day, from: date)
    let ordinalSuffix: String
    switch day {
    case 11...13:
        ordinalSuffix = "th"
    default:
        switch day % 10 {
        case 1:
            ordinalSuffix = "st"
        case 2:
            ordinalSuffix = "nd"
        case 3:
            ordinalSuffix = "rd"
        default:
            ordinalSuffix = "th"
        }
    }

    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "d MMM yyyy"
    outputFormatter.locale = Locale(identifier: "en_US_POSIX")
    outputFormatter.timeZone = TimeZone.current

    let formattedDate = outputFormatter.string(from: date)
    let dayString = String(day)
    let formattedDateWithSuffix = formattedDate.replacingOccurrences(of: dayString, with: "\(dayString)\(ordinalSuffix)")

    return formattedDateWithSuffix
}

func makeJSONSafe(_ input: String) -> String {
    let jsonData = try? JSONSerialization.data(withJSONObject: [input])
    if let jsonString = jsonData.flatMap({ String(data: $0, encoding: .utf8) }) {
        // Remove surrounding brackets ["..."] to return just the escaped string
        return String(jsonString.dropFirst().dropLast())
    }
    return input // Return original if conversion fails
}


struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

enum ImageFormat {
    case jpeg
    case png
    case heif
    case unsupported
}

extension Data {
    func imageFormat() -> ImageFormat {
        var buffer = [UInt8](repeating: 0, count: 1)
        self.copyBytes(to: &buffer, count: 1)
        switch buffer {
        case [0xFF]:
            return .jpeg
        case [0x89]:
            return .png
        case [0x00]:
            return .heif
        default:
            return .unsupported
        }
    }
}

func convertImageToBase64(image: UIImage) -> String? {
    guard let imageData = image.pngData() else {
        print("Error: Unable to extract image data.")
        return nil
    }

    let format = imageData.imageFormat()
    var base64String: String?

    switch format {
    case .jpeg:
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            base64String = jpegData.base64EncodedString()
        }
    case .png:
        base64String = imageData.base64EncodedString()
    case .heif:
        if let heifData = image.heicData(){
            base64String = heifData.base64EncodedString()
        }
    case .unsupported:
        print("Error: Unsupported image format.")
        return nil
    }

    return base64String
}


func decodeIdentityToken(_ identityToken: Data) -> [String: Any]? {
    guard let tokenString = String(data: identityToken, encoding: .utf8) else {
        return nil
    }

    let segments = tokenString.split(separator: ".")
    guard segments.count > 1 else {
        return nil
    }

    let base64String = String(segments[1])
    var decodedData = base64String.replacingOccurrences(of: "-", with: "+")
                                 .replacingOccurrences(of: "_", with: "/")

    // Pad the string with '=' to make its length a multiple of 4
    while decodedData.count % 4 != 0 {
        decodedData.append("=")
    }

    guard let data = Data(base64Encoded: decodedData) else {
        return nil
    }

    let json = try? JSONSerialization.jsonObject(with: data, options: [])
    return json as? [String: Any]
}

// MARK: — Hex Wei <→> Sonic (S) conversion
func weiHexToEthString(_ hex: String, decimals: Int = 18, maxFractionDigits: Int = 6) -> String {
    // Remove 0x prefix
    let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex

    // Hex string → Decimal (precise)
    var total = Decimal(0)
    let base = Decimal(16)
    for ch in cleaned {
        guard let digit = Int(String(ch), radix: 16) else { continue }
        total = total * base + Decimal(digit)
    }

    // Scale by 10^decimals (Wei → ETH)
    var divisor = Decimal(1)
    for _ in 0..<decimals { divisor *= 10 }
    var eth = total / divisor

    // Format
    var rounded = Decimal()
    NSDecimalRound(&rounded, &eth, maxFractionDigits, .plain)
    return "\(rounded) ETH"
}


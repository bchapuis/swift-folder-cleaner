import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// File type classification for visualization
enum FileType: String, Codable, Sendable, CaseIterable {
    case directory
    case image
    case video
    case audio
    case document
    case code
    case archive
    case executable
    case system
    case other

    /// Color mapping for treemap visualization (WCAG AA compliant, modern refined palette)
    /// Colors are adjusted for contrast ratio >= 4.5:1 with softer saturation for Apple aesthetic
    var color: Color {
        switch self {
        case .directory:
            return Color(red: 0.0, green: 0.45, blue: 0.85)  // Refined Blue
        case .image:
            return Color(red: 0.62, green: 0.30, blue: 0.78)  // Refined Purple
        case .video:
            return Color(red: 0.85, green: 0.24, blue: 0.52)  // Refined Pink
        case .audio:
            return Color(red: 0.0, green: 0.60, blue: 0.70)  // Refined Cyan
        case .document:
            return Color(red: 0.92, green: 0.52, blue: 0.0)  // Refined Orange
        case .code:
            return Color(red: 0.18, green: 0.70, blue: 0.32)  // Refined Green
        case .archive:
            return Color(red: 0.85, green: 0.68, blue: 0.05)  // Refined Yellow
        case .executable:
            return Color(red: 0.82, green: 0.24, blue: 0.20)  // Refined Red
        case .system:
            return Color(red: 0.52, green: 0.52, blue: 0.54)  // Refined Gray
        case .other:
            return Color(red: 0.44, green: 0.44, blue: 0.46)  // Refined Secondary
        }
    }

    /// Alternative color for better contrast in dark mode (refined, softer palette)
    var darkModeColor: Color {
        switch self {
        case .directory:
            return Color(red: 0.35, green: 0.65, blue: 0.92)  // Refined Light Blue
        case .image:
            return Color(red: 0.72, green: 0.48, blue: 0.86)  // Refined Light Purple
        case .video:
            return Color(red: 0.92, green: 0.42, blue: 0.66)  // Refined Light Pink
        case .audio:
            return Color(red: 0.35, green: 0.78, blue: 0.85)  // Refined Light Cyan
        case .document:
            return Color(red: 0.92, green: 0.64, blue: 0.28)  // Refined Light Orange
        case .code:
            return Color(red: 0.44, green: 0.84, blue: 0.55)  // Refined Light Green
        case .archive:
            return Color(red: 0.92, green: 0.80, blue: 0.32)  // Refined Light Yellow
        case .executable:
            return Color(red: 0.92, green: 0.42, blue: 0.38)  // Refined Light Red
        case .system:
            return Color(red: 0.62, green: 0.62, blue: 0.64)  // Refined Light Gray
        case .other:
            return Color(red: 0.58, green: 0.58, blue: 0.60)  // Refined Light Secondary
        }
    }


    /// SF Symbol icon for this file type
    var icon: String {
        switch self {
        case .directory:
            return "folder.fill"
        case .image:
            return "photo"
        case .video:
            return "film"
        case .audio:
            return "waveform"
        case .document:
            return "doc.text"
        case .code:
            return "doc.plaintext"
        case .archive:
            return "doc.zipper"
        case .executable:
            return "gearshape.2"
        case .system:
            return "gear"
        case .other:
            return "doc"
        }
    }
}

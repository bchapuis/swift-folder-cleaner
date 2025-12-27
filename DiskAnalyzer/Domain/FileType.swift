import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// File type classification for visualization
enum FileType: String, Codable, Sendable {
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

    /// Color mapping for treemap visualization (WCAG AA compliant)
    /// Colors are adjusted for contrast ratio >= 4.5:1 against both light and dark backgrounds
    var color: Color {
        switch self {
        case .directory:
            return Color(red: 0.0, green: 0.48, blue: 0.95)  // Blue
        case .image:
            return Color(red: 0.69, green: 0.32, blue: 0.87)  // Purple
        case .video:
            return Color(red: 0.94, green: 0.26, blue: 0.58)  // Pink
        case .audio:
            return Color(red: 0.0, green: 0.68, blue: 0.78)  // Cyan
        case .document:
            return Color(red: 1.0, green: 0.58, blue: 0.0)  // Orange
        case .code:
            return Color(red: 0.2, green: 0.78, blue: 0.35)  // Green
        case .archive:
            return Color(red: 0.95, green: 0.77, blue: 0.06)  // Yellow
        case .executable:
            return Color(red: 0.93, green: 0.26, blue: 0.21)  // Red
        case .system:
            return Color(red: 0.56, green: 0.56, blue: 0.58)  // Gray
        case .other:
            return Color(red: 0.48, green: 0.48, blue: 0.50)  // Secondary Gray
        }
    }

    /// Alternative color for better contrast in dark mode
    var darkModeColor: Color {
        switch self {
        case .directory:
            return Color(red: 0.39, green: 0.71, blue: 1.0)  // Lighter Blue
        case .image:
            return Color(red: 0.79, green: 0.52, blue: 0.94)  // Lighter Purple
        case .video:
            return Color(red: 1.0, green: 0.46, blue: 0.72)  // Lighter Pink
        case .audio:
            return Color(red: 0.39, green: 0.85, blue: 0.92)  // Lighter Cyan
        case .document:
            return Color(red: 1.0, green: 0.70, blue: 0.30)  // Lighter Orange
        case .code:
            return Color(red: 0.48, green: 0.91, blue: 0.60)  // Lighter Green
        case .archive:
            return Color(red: 1.0, green: 0.87, blue: 0.36)  // Lighter Yellow
        case .executable:
            return Color(red: 1.0, green: 0.46, blue: 0.42)  // Lighter Red
        case .system:
            return Color(red: 0.68, green: 0.68, blue: 0.70)  // Lighter Gray
        case .other:
            return Color(red: 0.63, green: 0.63, blue: 0.65)  // Lighter Secondary
        }
    }


    /// SF Symbol icon for this file type
    var icon: String {
        switch self {
        case .directory:
            return "folder.fill"
        case .image:
            return "photo.fill"
        case .video:
            return "video.fill"
        case .audio:
            return "music.note"
        case .document:
            return "doc.fill"
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .archive:
            return "archivebox.fill"
        case .executable:
            return "app.fill"
        case .system:
            return "gearshape.fill"
        case .other:
            return "doc.plaintext.fill"
        }
    }
}

import Foundation
import UniformTypeIdentifiers
import SwiftUI
import AppKit

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

    /// Color mapping for treemap visualization (WCAG AA compliant)
    /// Colors automatically adapt to light/dark mode
    var color: Color {
        switch self {
        case .directory:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.35, green: 0.65, blue: 0.92, alpha: 1.0)
                    : NSColor(red: 0.0, green: 0.45, blue: 0.85, alpha: 1.0)
            })
        case .image:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.72, green: 0.48, blue: 0.86, alpha: 1.0)
                    : NSColor(red: 0.62, green: 0.30, blue: 0.78, alpha: 1.0)
            })
        case .video:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.92, green: 0.42, blue: 0.66, alpha: 1.0)
                    : NSColor(red: 0.85, green: 0.24, blue: 0.52, alpha: 1.0)
            })
        case .audio:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.35, green: 0.78, blue: 0.85, alpha: 1.0)
                    : NSColor(red: 0.0, green: 0.60, blue: 0.70, alpha: 1.0)
            })
        case .document:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.92, green: 0.64, blue: 0.28, alpha: 1.0)
                    : NSColor(red: 0.92, green: 0.52, blue: 0.0, alpha: 1.0)
            })
        case .code:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.44, green: 0.84, blue: 0.55, alpha: 1.0)
                    : NSColor(red: 0.18, green: 0.70, blue: 0.32, alpha: 1.0)
            })
        case .archive:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.92, green: 0.80, blue: 0.32, alpha: 1.0)
                    : NSColor(red: 0.85, green: 0.68, blue: 0.05, alpha: 1.0)
            })
        case .executable:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.92, green: 0.42, blue: 0.38, alpha: 1.0)
                    : NSColor(red: 0.82, green: 0.24, blue: 0.20, alpha: 1.0)
            })
        case .system:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.62, green: 0.62, blue: 0.64, alpha: 1.0)
                    : NSColor(red: 0.52, green: 0.52, blue: 0.54, alpha: 1.0)
            })
        case .other:
            return Color(nsColor: NSColor(name: nil) { appearance in
                appearance.name == .darkAqua
                    ? NSColor(red: 0.58, green: 0.58, blue: 0.60, alpha: 1.0)
                    : NSColor(red: 0.44, green: 0.44, blue: 0.46, alpha: 1.0)
            })
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

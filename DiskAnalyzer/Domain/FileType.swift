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
    var color: Color {
        switch self {
        case .directory:
            return .blue
        case .image:
            return .purple
        case .video:
            return .pink
        case .audio:
            return .cyan
        case .document:
            return .orange
        case .code:
            return .green
        case .archive:
            return .yellow
        case .executable:
            return .red
        case .system:
            return .gray
        case .other:
            return .secondary
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

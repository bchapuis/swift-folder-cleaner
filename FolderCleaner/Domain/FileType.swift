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

    /// Color mapping for treemap visualization (WCAG AA compliant)
    /// Colors automatically adapt to light/dark mode via asset catalog
    var color: Color {
        switch self {
        case .directory:
            return Color("FileTypeDirectory")
        case .image:
            return Color("FileTypeImage")
        case .video:
            return Color("FileTypeVideo")
        case .audio:
            return Color("FileTypeAudio")
        case .document:
            return Color("FileTypeDocument")
        case .code:
            return Color("FileTypeCode")
        case .archive:
            return Color("FileTypeArchive")
        case .executable:
            return Color("FileTypeExecutable")
        case .system:
            return Color("FileTypeSystem")
        case .other:
            return Color("FileTypeOther")
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

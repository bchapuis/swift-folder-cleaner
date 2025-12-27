import Foundation
import UniformTypeIdentifiers

/// Detects file types based on path extension and UTType
struct FileTypeDetector: Sendable {
    /// Detects the file type for a given URL
    static func detectType(for url: URL) -> FileType {
        // Check if it's a directory first
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
           isDirectory.boolValue {
            return .directory
        }

        // Get the file extension
        let pathExtension = url.pathExtension.lowercased()

        // Try to get UTType from the file extension
        if let utType = UTType(filenameExtension: pathExtension) {
            return classify(utType: utType, extension: pathExtension)
        }

        // Fallback to extension-based detection
        return classify(extension: pathExtension)
    }

    /// Classifies a file type based on UTType
    private static func classify(utType: UTType, extension ext: String) -> FileType {
        // Images
        if utType.conforms(to: .image) {
            return .image
        }

        // Videos
        if utType.conforms(to: .movie) || utType.conforms(to: .video) {
            return .video
        }

        // Audio
        if utType.conforms(to: .audio) {
            return .audio
        }

        // Documents
        if utType.conforms(to: .pdf) ||
           utType.conforms(to: .rtf) ||
           utType.conforms(to: .text) ||
           utType.conforms(to: .plainText) ||
           utType.conforms(to: .presentation) ||
           utType.conforms(to: .spreadsheet) {
            return .document
        }

        // Source code
        if utType.conforms(to: .sourceCode) {
            return .code
        }

        // Archives
        if utType.conforms(to: .archive) || utType.conforms(to: .zip) {
            return .archive
        }

        // Executables and applications
        if utType.conforms(to: .executable) ||
           utType.conforms(to: .application) ||
           utType == .unixExecutable {
            return .executable
        }

        // Fallback to extension-based detection
        return classify(extension: ext)
    }

    /// Classifies a file type based on file extension only
    private static func classify(extension ext: String) -> FileType {
        switch ext {
        // Images
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "svg", "webp", "heic", "heif", "ico", "raw", "cr2", "nef":
            return .image

        // Videos
        case "mp4", "mov", "avi", "mkv", "flv", "wmv", "webm", "m4v", "mpg", "mpeg", "3gp":
            return .video

        // Audio
        case "mp3", "wav", "aac", "flac", "ogg", "m4a", "wma", "aiff", "alac", "opus":
            return .audio

        // Documents
        case "pdf", "doc", "docx", "txt", "rtf", "odt", "pages", "tex", "md", "markdown",
             "xls", "xlsx", "csv", "numbers", "ods",
             "ppt", "pptx", "key", "odp":
            return .document

        // Code
        case "swift", "c", "cpp", "h", "hpp", "m", "mm", "java", "py", "js", "ts", "jsx", "tsx",
             "html", "css", "scss", "sass", "less",
             "xml", "json", "yaml", "yml", "toml",
             "sh", "bash", "zsh", "fish",
             "rb", "go", "rs", "php", "pl", "lua", "sql", "r", "scala", "kt", "kts",
             "vim", "el", "lisp", "clj", "ex", "exs", "erl", "hs", "ml", "fs":
            return .code

        // Archives
        case "zip", "tar", "gz", "bz2", "7z", "rar", "xz", "tgz", "tbz2", "dmg", "pkg", "deb", "rpm":
            return .archive

        // Executables
        case "app", "exe", "dll", "so", "dylib", "bin", "out", "o", "a":
            return .executable

        // System files
        case "sys", "ini", "cfg", "conf", "plist", "log", "bak", "tmp", "cache":
            return .system

        default:
            return .other
        }
    }
}

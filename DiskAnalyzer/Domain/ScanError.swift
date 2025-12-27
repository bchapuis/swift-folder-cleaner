import Foundation

/// Errors that can occur during file scanning
enum ScanError: LocalizedError, Sendable {
    case permissionDenied(path: String)
    case pathNotFound(path: String)
    case notADirectory(path: String)
    case cancelled
    case unknown(underlying: String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let path):
            return "Access denied: \(path)"
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .notADirectory(let path):
            return "Not a directory: \(path)"
        case .cancelled:
            return "Scan was cancelled"
        case .unknown(let underlying):
            return "An error occurred: \(underlying)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Make sure you have permission to access this folder. Try selecting a different folder or granting access in System Settings."
        case .pathNotFound:
            return "The selected path no longer exists. Please select a different folder."
        case .notADirectory:
            return "Please select a folder, not a file."
        case .cancelled:
            return nil
        case .unknown:
            return "Please try again or select a different folder."
        }
    }

    var failureReason: String? {
        switch self {
        case .permissionDenied:
            return "The application does not have permission to access this folder."
        case .pathNotFound:
            return "The folder was moved or deleted."
        case .notADirectory:
            return "The selected item is a file, not a folder."
        case .cancelled:
            return "The user cancelled the scan operation."
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}

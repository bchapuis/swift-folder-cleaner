import Foundation

/// Service for performing file system operations on FileNodes
/// Separates file operations from ViewModel to improve testability
@MainActor
final class FileOperationsService {
    // MARK: - Operations

    /// Show file or directory in Finder
    func showInFinder(_ node: FileNode) {
        FileActions.showInFinder([node])
    }

    /// Move file or directory to trash
    /// - Returns: Result indicating success or failure with message
    func moveToTrash(_ node: FileNode) async -> FileActionResult {
        await FileActions.moveToTrash([node])
    }

    /// Move multiple files or directories to trash
    /// - Returns: Result indicating success or failure with message
    func moveToTrash(_ nodes: Set<FileNode>) async -> FileActionResult {
        await FileActions.moveToTrash(nodes)
    }

    /// Format a result message for display to user
    func formatResultMessage(_ result: FileActionResult) -> String {
        FileActions.formatResultMessage(result)
    }
}

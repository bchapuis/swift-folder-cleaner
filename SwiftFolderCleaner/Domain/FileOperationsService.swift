import Foundation
import SwiftData

/// Service for performing file system operations on FileItems
/// Separates file operations from ViewModel to improve testability
@MainActor
final class FileOperationsService {
    // MARK: - Operations

    /// Show file or directory in Finder
    func showInFinder(_ item: FileItem) {
        FileActions.showInFinder([item])
    }

    /// Open file in Preview
    func showInPreview(_ item: FileItem) {
        FileActions.showInPreview(item)
    }

    /// Check if item can be previewed
    func canPreview(_ item: FileItem) -> Bool {
        FileActions.canPreview(item)
    }

    /// Move file or directory to trash
    /// - Returns: Result indicating success or failure with message
    func moveToTrash(_ item: FileItem) async -> FileActionResult {
        await FileActions.moveToTrash([item])
    }

    /// Move multiple files or directories to trash
    /// - Returns: Result indicating success or failure with message
    func moveToTrash(_ items: Set<FileItem>) async -> FileActionResult {
        await FileActions.moveToTrash(items)
    }

    /// Format a result message for display to user
    func formatResultMessage(_ result: FileActionResult) -> String {
        FileActions.formatResultMessage(result)
    }
}

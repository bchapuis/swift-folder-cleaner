import Foundation
import AppKit

/// File operation results
enum FileActionResult {
    case success(deletedCount: Int, freedSpace: Int64)
    case cancelled
    case error(Error)
}

/// File operation errors
enum FileActionError: LocalizedError {
    case noSelection
    case accessDenied
    case systemError(Error)

    var errorDescription: String? {
        switch self {
        case .noSelection:
            return "No files selected"
        case .accessDenied:
            return "Access denied. App Sandbox prevents this operation."
        case .systemError(let error):
            return error.localizedDescription
        }
    }
}

/// Handles file operations (delete, show in Finder, etc.)
@MainActor
class FileActions {

    /// Show file or folder in Finder
    static func showInFinder(_ node: FileNode) {
        NSWorkspace.shared.activateFileViewerSelecting([node.path])
    }

    /// Show multiple files in Finder
    static func showInFinder(_ nodes: [FileNode]) {
        let urls = nodes.map { $0.path }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    /// Open file in Quick Look Preview
    static func showInPreview(_ node: FileNode) {
        guard !node.isDirectory else { return }
        NSWorkspace.shared.open(node.path)
    }

    /// Check if node can be previewed (only files, not directories)
    static func canPreview(_ node: FileNode) -> Bool {
        return !node.isDirectory
    }

    /// Move files to trash with confirmation
    static func moveToTrash(_ nodes: Set<FileNode>) async -> FileActionResult {
        guard !nodes.isEmpty else {
            return .error(FileActionError.noSelection)
        }

        // Calculate totals
        let totalSize = FileFilters.totalSize(of: nodes)
        let totalFiles = FileFilters.totalFiles(of: nodes)

        // Show confirmation if needed
        if await shouldConfirmDeletion(count: totalFiles, size: totalSize) {
            let confirmed = await showConfirmationDialog(count: totalFiles, size: totalSize)
            guard confirmed else {
                return .cancelled
            }
        }

        // Delete files
        var deletedCount = 0
        var deletedSize: Int64 = 0
        let fileManager = FileManager.default

        for node in nodes {
            do {
                // Move to trash
                try fileManager.trashItem(at: node.path, resultingItemURL: nil)

                deletedCount += 1
                deletedSize += node.totalSize

            } catch {
                print("Failed to delete \(node.path.path): \(error)")
                // Continue deleting other files
            }
        }

        if deletedCount > 0 {
            return .success(deletedCount: deletedCount, freedSpace: deletedSize)
        } else {
            return .error(FileActionError.accessDenied)
        }
    }

    /// Check if confirmation is needed
    private static func shouldConfirmDeletion(count: Int, size: Int64) -> Bool {
        // Confirm if >10 files OR >100MB
        return count > 10 || size > (100 * 1024 * 1024)
    }

    /// Show confirmation dialog
    private static func showConfirmationDialog(count: Int, size: Int64) async -> Bool {
        let sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        let itemWord = count == 1 ? "item" : "items"

        let alert = NSAlert()
        alert.messageText = "Move to Trash?"
        alert.informativeText = "This will move \(count.formatted(.number)) \(itemWord) (\(sizeStr)) to the Trash."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")

        return await alert.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) == .alertFirstButtonReturn
    }

    /// Format action result message
    static func formatResultMessage(_ result: FileActionResult) -> String {
        switch result {
        case .success(let count, let size):
            let sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            let itemWord = count == 1 ? "item" : "items"
            return "Moved \(count.formatted(.number)) \(itemWord) to Trash (\(sizeStr) freed)"

        case .cancelled:
            return "Operation cancelled"

        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
}

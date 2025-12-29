import Foundation

/// Deep module for path-based navigation in FileNode trees
/// Provides efficient navigation without storing mutable state
/// Minimal API hides complexity of tree traversal and breadcrumb generation
struct FileTreeNavigator: Sendable {
    let root: FileNode

    // MARK: - Public API (Deep Module: 2 primary methods)

    /// Navigate to a node using a URL path array
    /// Hides complexity of path validation and tree traversal
    func node(at paths: [URL]) -> FileNode? {
        guard !paths.isEmpty else {
            return nil
        }

        var current = root

        // Skip first path if it's the root (use standardized URLs for comparison)
        let pathsToTraverse = paths.first?.standardized == root.path.standardized ? Array(paths.dropFirst()) : paths

        for path in pathsToTraverse {
            // Standardize URL for proper comparison (handles spaces and special chars)
            let standardizedPath = path.standardized
            guard let child = current.children.first(where: { $0.path.standardized == standardizedPath }) else {
                return nil
            }
            current = child
        }

        return current
    }

    /// Generate breadcrumb trail from URL path array
    /// Hides complexity of building hierarchical trail with error handling
    func breadcrumb(from paths: [URL]) -> [FileNode] {
        var trail: [FileNode] = []
        var current = root
        trail.append(current)

        // Skip first URL (it's the root)
        for url in paths.dropFirst() {
            // Standardize URL for proper comparison (handles spaces and special chars)
            let standardizedURL = url.standardized
            if let child = current.children.first(where: { $0.path.standardized == standardizedURL }) {
                trail.append(child)
                current = child
            } else {
                break
            }
        }

        return trail
    }
}

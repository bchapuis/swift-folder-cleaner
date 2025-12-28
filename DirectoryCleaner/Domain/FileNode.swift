import Foundation

/// Represents a file or directory in the file tree
/// Immutable recursive structure with cached computations for performance
struct FileNode: Identifiable, Sendable {
    /// Unique identifier based on file path
    var id: URL { path }

    let path: URL
    let name: String
    let size: Int64
    let fileType: FileType
    let modifiedDate: Date
    let children: [FileNode]
    let isDirectory: Bool

    /// Total size including all children (cached for performance)
    let totalSize: Int64

    /// Total file count including this node and all children (cached)
    let fileCount: Int

    /// Depth of subtree from this node (cached)
    let maxDepth: Int

    /// Percentage of total size relative to a parent size
    func percentage(of totalSize: Int64) -> Double {
        guard totalSize > 0 else { return 0.0 }
        return Double(self.totalSize) / Double(totalSize) * 100.0
    }

    /// Human-readable size string (e.g., "1.5 GB", "342 MB")
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

extension FileNode {
    /// Creates a file node for a directory
    static func directory(
        path: URL,
        name: String,
        modifiedDate: Date,
        children: [FileNode] = []
    ) -> FileNode {
        let totalSize = children.reduce(0) { $0 + $1.totalSize }
        let fileCount = 1 + children.reduce(0) { $0 + $1.fileCount }
        let maxDepth = children.isEmpty ? 0 : (children.map(\.maxDepth).max() ?? 0) + 1

        return FileNode(
            path: path,
            name: name,
            size: 0,
            fileType: .directory,
            modifiedDate: modifiedDate,
            children: children,
            isDirectory: true,
            totalSize: totalSize,
            fileCount: fileCount,
            maxDepth: maxDepth
        )
    }

    /// Creates a file node for a regular file
    static func file(
        path: URL,
        name: String,
        size: Int64,
        fileType: FileType,
        modifiedDate: Date
    ) -> FileNode {
        FileNode(
            path: path,
            name: name,
            size: size,
            fileType: fileType,
            modifiedDate: modifiedDate,
            children: [],
            isDirectory: false,
            totalSize: size,
            fileCount: 1,
            maxDepth: 0
        )
    }
}

extension FileNode: Equatable {
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.path.standardized == rhs.path.standardized
    }
}

extension FileNode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(path.standardized)
    }
}

// MARK: - Filtering

extension FileNode {
    /// Creates a filtered copy of this node tree containing only nodes of specified types
    /// - Parameter selectedTypes: Set of file types to include
    /// - Returns: Filtered node, or nil if no matching nodes found
    func filtered(by selectedTypes: Set<FileType>) -> FileNode? {
        // For files: include only if type is selected
        if !isDirectory {
            return selectedTypes.contains(fileType) ? self : nil
        }

        // For directories: recursively filter children
        let filteredChildren = children.compactMap { child in
            child.filtered(by: selectedTypes)
        }

        // Include directory only if:
        // 1. It has matching children, OR
        // 2. Directory type is selected and it's empty/has no children
        if !filteredChildren.isEmpty {
            let filteredTotalSize = filteredChildren.reduce(0) { $0 + $1.totalSize }
            let filteredFileCount = 1 + filteredChildren.reduce(0) { $0 + $1.fileCount }
            let filteredMaxDepth = filteredChildren.isEmpty ? 0 : (filteredChildren.map(\.maxDepth).max() ?? 0) + 1

            return FileNode(
                path: path,
                name: name,
                size: size,
                fileType: fileType,
                modifiedDate: modifiedDate,
                children: filteredChildren,
                isDirectory: isDirectory,
                totalSize: filteredTotalSize,
                fileCount: filteredFileCount,
                maxDepth: filteredMaxDepth
            )
        } else if selectedTypes.contains(.directory) && children.isEmpty {
            return self
        }

        return nil
    }
}

// MARK: - Navigation

extension FileNode {
    /// Find a direct child by path
    func child(at path: URL) -> FileNode? {
        let standardizedPath = path.standardized
        return children.first(where: { $0.path.standardized == standardizedPath })
    }

    /// Find a descendant node by following a path
    func descendant(at paths: [URL]) -> FileNode? {
        var current = self

        for path in paths {
            let standardizedPath = path.standardized
            guard let child = current.children.first(where: { $0.path.standardized == standardizedPath }) else {
                return nil
            }
            current = child
        }

        return current
    }

    /// Check if this subtree contains a node with the given path
    func contains(path: URL) -> Bool {
        let standardizedPath = path.standardized
        if self.path.standardized == standardizedPath {
            return true
        }

        return children.contains(where: { $0.contains(path: path) })
    }
}

// MARK: - Query

extension FileNode {
    /// Find all nodes matching a predicate
    func find(where predicate: (FileNode) -> Bool) -> [FileNode] {
        var results: [FileNode] = []

        if predicate(self) {
            results.append(self)
        }

        for child in children {
            results.append(contentsOf: child.find(where: predicate))
        }

        return results
    }

    /// Find first node matching a predicate (depth-first search)
    func findFirst(where predicate: (FileNode) -> Bool) -> FileNode? {
        if predicate(self) {
            return self
        }

        for child in children {
            if let found = child.findFirst(where: predicate) {
                return found
            }
        }

        return nil
    }

    /// Find a node by exact path
    func findNode(at path: URL) -> FileNode? {
        let standardizedPath = path.standardized
        return findFirst(where: { $0.path.standardized == standardizedPath })
    }
}

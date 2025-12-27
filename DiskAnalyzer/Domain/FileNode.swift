import Foundation

/// Represents a file or directory in the file tree
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

    /// Total size including all children
    var totalSize: Int64 {
        if isDirectory {
            return children.reduce(size) { $0 + $1.totalSize }
        }
        return size
    }

    /// Total file count including this node and all children
    var fileCount: Int {
        if isDirectory {
            return 1 + children.reduce(0) { $0 + $1.fileCount }
        }
        return 1
    }

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
        FileNode(
            path: path,
            name: name,
            size: 0,
            fileType: .directory,
            modifiedDate: modifiedDate,
            children: children,
            isDirectory: true
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
            isDirectory: false
        )
    }
}

extension FileNode: Equatable {
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.path == rhs.path
    }
}

extension FileNode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

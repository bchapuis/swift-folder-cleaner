import Foundation

/// High-performance flat file tree with multiple indexes
/// Replaces recursive tree traversal with O(1) hash lookups
struct IndexedFileTree: Sendable {
    // MARK: - Storage

    /// All files in flat array (single source of truth)
    private let allFiles: [FileNode]

    /// Root node for hierarchy navigation
    let root: FileNode

    // MARK: - Indexes

    /// Path index: URL -> FileNode (O(1) lookup)
    private let pathIndex: [URL: FileNode]

    /// Type index: FileType -> [FileNode] (O(1) filter by type)
    private let typeIndex: [FileType: [FileNode]]

    /// Hierarchy index: parent URL -> children (O(1) get children)
    private let hierarchyIndex: [URL: [FileNode]]

    /// Size buckets for range queries
    private let sizeBuckets: SizeBuckets

    // MARK: - Initialization

    init(root: FileNode) {
        self.root = root

        // Flatten tree into array
        var files: [FileNode] = []
        root.traverse(order: .depthFirst) { node, _ in
            files.append(node)
            return true
        }
        self.allFiles = files

        // Build path index
        var pathIdx: [URL: FileNode] = [:]
        for file in files {
            pathIdx[file.path] = file
        }
        self.pathIndex = pathIdx

        // Build type index
        var typeIdx: [FileType: [FileNode]] = [:]
        for file in files {
            typeIdx[file.fileType, default: []].append(file)
        }
        self.typeIndex = typeIdx

        // Build hierarchy index (parent -> children)
        var hierarchyIdx: [URL: [FileNode]] = [:]
        for file in files {
            let parent = file.path.deletingLastPathComponent()
            hierarchyIdx[parent, default: []].append(file)
        }
        self.hierarchyIndex = hierarchyIdx

        // Build size buckets
        self.sizeBuckets = SizeBuckets(files: files)
    }

    // MARK: - Lookup Operations (O(1))

    /// Find file by path
    func node(at path: URL) -> FileNode? {
        pathIndex[path]
    }

    /// Get immediate children of a directory
    func children(of path: URL) -> [FileNode] {
        hierarchyIndex[path] ?? []
    }

    /// Get all files of a specific type
    func files(ofType type: FileType) -> [FileNode] {
        typeIndex[type] ?? []
    }

    /// Get all files of multiple types
    func files(ofTypes types: Set<FileType>) -> [FileNode] {
        types.flatMap { typeIndex[$0] ?? [] }
    }

    // MARK: - Filter Operations

    /// Filter files only (no directories)
    func filesOnly() -> [FileNode] {
        allFiles.filter { !$0.isDirectory }
    }

    /// Filter by size range
    func files(largerThan minSize: Int64) -> [FileNode] {
        sizeBuckets.files(largerThan: minSize)
    }

    /// Filter by multiple criteria (fast!)
    func filter(types: Set<FileType>, minSize: Int64?) -> [FileNode] {
        var result = files(ofTypes: types)

        // Apply size filter if specified
        if let minSize = minSize, minSize > 0 {
            result = result.filter { !$0.isDirectory && $0.totalSize >= minSize }
        } else {
            // Only files, no directories
            result = result.filter { !$0.isDirectory }
        }

        return result
    }

    /// Filter by multiple criteria within a specific directory subtree
    /// Returns matching files and (optionally) directories that contain matching files
    /// If .directory is NOT in the types filter, directories are excluded entirely
    func filter(types: Set<FileType>, minSize: Int64?, underPath: URL, filenamePattern: String? = nil) -> [FileNode] {
        // Filter to only descendants of the given path
        let pathString = underPath.path
        let descendantsUnderPath = allFiles.filter { node in
            // Must be under the given path (but not the path itself)
            node.path.path.hasPrefix(pathString) && node.path != underPath
        }

        // First pass: identify matching FILES
        let matchingFiles = descendantsUnderPath.filter { node in
            guard !node.isDirectory else { return false }

            // Files must match type filter
            guard types.contains(node.fileType) else { return false }

            // Apply size filter if specified
            if let minSize = minSize, minSize > 0 {
                guard node.totalSize >= minSize else { return false }
            }

            // Apply filename filter if specified
            if let pattern = filenamePattern, !pattern.isEmpty {
                let filter = FilenameFilter(pattern: pattern)
                guard filter.matches(node) else { return false }
            }

            return true
        }

        // Second pass: include directories ONLY if .directory type is selected
        // This makes the filter intuitive: unchecking "Folder" hides ALL folders
        let shouldIncludeFolders = types.contains(.directory)

        if shouldIncludeFolders {
            // Find all ancestor directories of matching files
            var ancestorDirs = Set<URL>()
            for file in matchingFiles {
                var currentPath = file.path.deletingLastPathComponent()
                // Walk up the tree until we reach underPath or root
                while currentPath.path.hasPrefix(pathString) && currentPath != underPath {
                    ancestorDirs.insert(currentPath)
                    currentPath = currentPath.deletingLastPathComponent()
                }
            }

            // Include directories that are ancestors of matching files
            let matchingDirectories = descendantsUnderPath.filter { node in
                node.isDirectory && ancestorDirs.contains(node.path)
            }

            // Combine matching files and directories
            return matchingFiles + matchingDirectories
        } else {
            // User unchecked "Folder" → show ONLY files, no directories
            return matchingFiles
        }
    }

    // MARK: - Statistics

    var totalFiles: Int { allFiles.count }
    var fileCount: Int { allFiles.filter { !$0.isDirectory }.count }
    var directoryCount: Int { allFiles.filter { $0.isDirectory }.count }
}

// MARK: - Size Buckets

/// Bucket files by size for fast range queries
private struct SizeBuckets: Sendable {
    private let buckets: [Int64: [FileNode]]

    // Size bucket thresholds (powers of 10)
    private static let thresholds: [Int64] = [
        1024,              // 1 KB
        10 * 1024,         // 10 KB
        100 * 1024,        // 100 KB
        1024 * 1024,       // 1 MB
        10 * 1024 * 1024,  // 10 MB
        100 * 1024 * 1024, // 100 MB
        1024 * 1024 * 1024 // 1 GB
    ]

    init(files: [FileNode]) {
        var buckets: [Int64: [FileNode]] = [:]

        for threshold in Self.thresholds {
            buckets[threshold] = files.filter { !$0.isDirectory && $0.totalSize >= threshold }
        }

        self.buckets = buckets
    }

    func files(largerThan minSize: Int64) -> [FileNode] {
        // Find the closest bucket
        guard let bucket = Self.thresholds.last(where: { $0 <= minSize }) ?? Self.thresholds.first else {
            return []
        }

        // Get files from bucket and filter precisely
        return buckets[bucket]?.filter { $0.totalSize >= minSize } ?? []
    }
}

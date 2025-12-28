import Foundation

// MARK: - Search Criteria

/// Criteria for searching the file tree
enum SearchCriteria {
    /// Search by name (substring match)
    case name(String, caseSensitive: Bool = false)

    /// Search by pattern (regex or wildcard)
    case pattern(String, isRegex: Bool = false)

    /// Search by file extension
    case fileExtension(String)

    /// Custom predicate
    case custom(@Sendable (FileNode) -> Bool)
}

// MARK: - Sort Criteria

/// Criteria for sorting and ranking results
enum SortCriteria: Sendable {
    /// Sort by total size (largest first)
    case size(filesOnly: Bool = false)

    /// Sort by file count (most files first, directories only)
    case fileCount

    /// Sort by modification date
    case modificationDate(newest: Bool)
}

// MARK: - File Tree Query

/// Deep module for querying FileNode trees
/// Provides powerful search and ranking with a minimal API
struct FileTreeQuery: Sendable {
    let root: FileNode

    init(root: FileNode) {
        self.root = root
    }

    // MARK: - Public API (Deep Module: 3 methods)

    /// Search for nodes matching criteria
    /// Hides complexity of different search algorithms behind unified interface
    func find(_ criteria: SearchCriteria) -> [FileNode] {
        switch criteria {
        case .name(let searchName, let caseSensitive):
            return root.find(where: { node in
                if caseSensitive {
                    return node.name.contains(searchName)
                } else {
                    return node.name.localizedCaseInsensitiveContains(searchName)
                }
            })

        case .pattern(let pattern, let isRegex):
            if isRegex {
                guard let regex = try? NSRegularExpression(pattern: pattern) else {
                    return []
                }
                return root.find(where: { node in
                    let range = NSRange(node.name.startIndex..., in: node.name)
                    return regex.firstMatch(in: node.name, range: range) != nil
                })
            } else {
                // Wildcard pattern (convert to regex)
                let regexPattern = pattern
                    .replacingOccurrences(of: ".", with: "\\.")
                    .replacingOccurrences(of: "*", with: ".*")
                    .replacingOccurrences(of: "?", with: ".")
                return find(.pattern(regexPattern, isRegex: true))
            }

        case .fileExtension(let ext):
            return root.find(where: { node in
                !node.isDirectory && node.path.pathExtension.lowercased() == ext.lowercased()
            })

        case .custom(let predicate):
            return root.find(where: predicate)
        }
    }

    /// Get top N nodes ranked by criteria
    /// Hides complexity of filtering, sorting, and ranking behind unified interface
    func top(_ count: Int, by criteria: SortCriteria) -> [FileNode] {
        switch criteria {
        case .size(let filesOnly):
            var all = filesOnly
                ? root.find(where: { !$0.isDirectory })
                : root.find(where: { _ in true })
            all.sort { $0.totalSize > $1.totalSize }
            return Array(all.prefix(count))

        case .fileCount:
            var directories = root.find(where: { $0.isDirectory })
            directories.sort { $0.fileCount > $1.fileCount }
            return Array(directories.prefix(count))

        case .modificationDate(let newest):
            var files = root.find(where: { !$0.isDirectory })
            files.sort { newest ? $0.modifiedDate > $1.modifiedDate : $0.modifiedDate < $1.modifiedDate }
            return Array(files.prefix(count))
        }
    }

    /// Compute comprehensive statistics for the tree
    /// Hides complexity of tree traversal, median calculation, and data aggregation
    func statistics() -> FileTreeStatistics {
        var totalSize: Int64 = 0
        var totalFiles = 0
        var totalDirectories = 0
        var largestFile: FileNode?
        var fileSizes: [Int64] = []

        func traverse(_ node: FileNode) {
            if node.isDirectory {
                totalDirectories += 1
                for child in node.children {
                    traverse(child)
                }
            } else {
                totalFiles += 1
                totalSize += node.size
                fileSizes.append(node.size)

                if largestFile == nil || node.size > (largestFile?.size ?? 0) {
                    largestFile = node
                }
            }
        }

        traverse(root)

        // Calculate median
        fileSizes.sort()
        let medianFileSize: Int64
        if fileSizes.isEmpty {
            medianFileSize = 0
        } else if fileSizes.count % 2 == 0 {
            let mid = fileSizes.count / 2
            medianFileSize = (fileSizes[mid - 1] + fileSizes[mid]) / 2
        } else {
            medianFileSize = fileSizes[fileSizes.count / 2]
        }

        return FileTreeStatistics(
            totalSize: totalSize,
            totalFiles: totalFiles,
            totalDirectories: totalDirectories,
            maxDepth: root.maxDepth,
            averageFileSize: totalFiles > 0 ? totalSize / Int64(totalFiles) : 0,
            medianFileSize: medianFileSize,
            largestFile: largestFile
        )
    }
}

// MARK: - Statistics Result

/// Comprehensive statistics for a file tree
struct FileTreeStatistics: Sendable {
    let totalSize: Int64
    let totalFiles: Int
    let totalDirectories: Int
    let maxDepth: Int
    let averageFileSize: Int64
    let medianFileSize: Int64
    let largestFile: FileNode?

    /// Human-readable summary
    var summary: String {
        """
        Total Size: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
        Files: \(totalFiles.formatted())
        Directories: \(totalDirectories.formatted())
        Max Depth: \(maxDepth)
        Average File Size: \(ByteCountFormatter.string(fromByteCount: averageFileSize, countStyle: .file))
        Median File Size: \(ByteCountFormatter.string(fromByteCount: medianFileSize, countStyle: .file))
        """
    }
}

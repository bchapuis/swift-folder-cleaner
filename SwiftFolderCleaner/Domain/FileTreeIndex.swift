import Foundation

/// Fast lookup index for FileNode trees
/// Builds indices on construction for O(1) lookups vs O(n) tree traversal
/// Useful for large trees with frequent lookups
struct FileTreeIndex: Sendable {
    // MARK: - Indices

    /// Path → Node lookup (O(1))
    private let pathIndex: [URL: FileNode]

    /// FileType → Nodes lookup (O(1))
    private let typeIndex: [FileType: [FileNode]]

    /// Name → Nodes lookup (O(1))
    private let nameIndex: [String: [FileNode]]

    /// Extension → Nodes lookup (O(1))
    private let extensionIndex: [String: [FileNode]]

    /// Size range buckets for fast size-based queries
    private let sizeIndex: SizeBucketIndex

    /// Statistics (pre-computed)
    private let cachedStatistics: FileTreeStatistics

    // MARK: - Initialization

    init(root: FileNode) {
        var pathIdx: [URL: FileNode] = [:]
        var typeIdx: [FileType: [FileNode]] = [:]
        var nameIdx: [String: [FileNode]] = [:]
        var extIdx: [String: [FileNode]] = [:]
        var sizeBuckets: [Int: [FileNode]] = [:]

        // Build all indices in one traversal
        root.traverse { node, _ in
            // Path index
            pathIdx[node.path] = node

            // Type index
            typeIdx[node.fileType, default: []].append(node)

            // Name index
            nameIdx[node.name, default: []].append(node)

            // Extension index
            if !node.isDirectory {
                let ext = node.path.pathExtension.lowercased()
                if !ext.isEmpty {
                    extIdx[ext, default: []].append(node)
                }
            }

            // Size bucket index (for size-based queries)
            let bucket = SizeBucketIndex.bucket(for: node.totalSize)
            sizeBuckets[bucket, default: []].append(node)

            return true
        }

        self.pathIndex = pathIdx
        self.typeIndex = typeIdx
        self.nameIndex = nameIdx
        self.extensionIndex = extIdx
        self.sizeIndex = SizeBucketIndex(buckets: sizeBuckets)

        // Pre-compute statistics
        self.cachedStatistics = FileTreeQuery(root: root).statistics()
    }

    // MARK: - Fast Lookups (O(1))

    /// Get node by path - O(1) instead of O(n)
    func node(at path: URL) -> FileNode? {
        pathIndex[path]
    }

    /// Get all nodes of a specific type - O(1) instead of O(n)
    func nodes(ofType type: FileType) -> [FileNode] {
        typeIndex[type] ?? []
    }

    /// Get all nodes with a specific name - O(1) instead of O(n)
    func nodes(named name: String) -> [FileNode] {
        nameIndex[name] ?? []
    }

    /// Get all nodes with a specific extension - O(1) instead of O(n)
    func nodes(withExtension ext: String) -> [FileNode] {
        extensionIndex[ext.lowercased()] ?? []
    }

    /// Get nodes in a size range - O(k) where k is nodes in range
    func nodes(inSizeRange range: ClosedRange<Int64>) -> [FileNode] {
        sizeIndex.nodes(in: range)
    }

    // MARK: - Statistics

    /// Get pre-computed statistics - O(1)
    var statistics: FileTreeStatistics {
        cachedStatistics
    }

    /// Get file count by type - O(1)
    func fileCount(ofType type: FileType) -> Int {
        typeIndex[type]?.count ?? 0
    }

    /// Get total size by type - O(k) where k is files of that type
    func totalSize(ofType type: FileType) -> Int64 {
        (typeIndex[type] ?? []).reduce(0) { $0 + $1.totalSize }
    }

    // MARK: - Checks

    /// Check if path exists in tree - O(1)
    func contains(path: URL) -> Bool {
        pathIndex[path] != nil
    }

    /// Get total node count - O(1)
    var totalNodes: Int {
        pathIndex.count
    }
}

// MARK: - Size Bucket Index

/// Size-based bucketing for fast range queries
private struct SizeBucketIndex: Sendable {
    // Size buckets (logarithmic scale)
    // Bucket 0: 0 bytes
    // Bucket 1: 1-1KB
    // Bucket 2: 1KB-10KB
    // Bucket 3: 10KB-100KB
    // Bucket 4: 100KB-1MB
    // Bucket 5: 1MB-10MB
    // Bucket 6: 10MB-100MB
    // Bucket 7: 100MB-1GB
    // Bucket 8: 1GB-10GB
    // Bucket 9: 10GB+

    private let buckets: [Int: [FileNode]]

    init(buckets: [Int: [FileNode]]) {
        self.buckets = buckets
    }

    /// Determine which bucket a size belongs to
    static func bucket(for size: Int64) -> Int {
        if size == 0 { return 0 }
        if size < 1024 { return 1 }
        if size < 10 * 1024 { return 2 }
        if size < 100 * 1024 { return 3 }
        if size < 1024 * 1024 { return 4 }
        if size < 10 * 1024 * 1024 { return 5 }
        if size < 100 * 1024 * 1024 { return 6 }
        if size < 1024 * 1024 * 1024 { return 7 }
        if size < 10 * 1024 * 1024 * 1024 { return 8 }
        return 9
    }

    /// Get nodes in size range
    func nodes(in range: ClosedRange<Int64>) -> [FileNode] {
        let minBucket = Self.bucket(for: range.lowerBound)
        let maxBucket = Self.bucket(for: range.upperBound)

        var results: [FileNode] = []

        for bucket in minBucket...maxBucket {
            if let nodes = buckets[bucket] {
                results.append(contentsOf: nodes.filter { range.contains($0.totalSize) })
            }
        }

        return results
    }
}

// MARK: - Extension for FileNode

extension FileNode {
    /// Create an index for this tree (for fast lookups)
    func createIndex() -> FileTreeIndex {
        FileTreeIndex(root: self)
    }
}

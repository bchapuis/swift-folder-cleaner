import Foundation

/// File size filters for identifying large files
enum FileSizeFilter: String, CaseIterable, Identifiable {
    case large100MB = ">100 MB"
    case large1GB = ">1 GB"
    case large10GB = ">10 GB"

    var id: String { rawValue }

    var threshold: Int64 {
        switch self {
        case .large100MB: return 100 * 1024 * 1024
        case .large1GB: return 1024 * 1024 * 1024
        case .large10GB: return 10 * 1024 * 1024 * 1024
        }
    }

    var systemImage: String {
        switch self {
        case .large100MB: return "doc.fill"
        case .large1GB: return "doc.badge.gearshape.fill"
        case .large10GB: return "externaldrive.fill"
        }
    }
}

/// Utility for filtering and analyzing files
struct FileFilters {

    /// Find all files matching the size filter
    static func findLargeFiles(in node: FileNode, matching filter: FileSizeFilter) -> [FileNode] {
        var results: [FileNode] = []
        collectLargeFiles(node: node, threshold: filter.threshold, results: &results)
        return results.sorted { $0.totalSize > $1.totalSize }
    }

    private static func collectLargeFiles(node: FileNode, threshold: Int64, results: inout [FileNode]) {
        // Add this file if it matches
        if !node.isDirectory && node.totalSize >= threshold {
            results.append(node)
        }

        // Recursively check children
        for child in node.children {
            collectLargeFiles(node: child, threshold: threshold, results: &results)
        }
    }

    /// Get top N largest files/folders
    static func topLargest(in node: FileNode, count: Int = 10) -> [FileNode] {
        var all: [FileNode] = []
        collectAll(node: node, results: &all)
        return Array(all.sorted { $0.totalSize > $1.totalSize }.prefix(count))
    }

    private static func collectAll(node: FileNode, results: inout [FileNode]) {
        results.append(node)
        for child in node.children {
            collectAll(node: child, results: &results)
        }
    }

    /// Calculate total size of selected nodes
    static func totalSize(of nodes: Set<FileNode>) -> Int64 {
        nodes.reduce(0) { $0 + $1.totalSize }
    }

    /// Count total files in selection
    static func totalFiles(of nodes: Set<FileNode>) -> Int {
        nodes.reduce(0) { count, node in
            count + (node.isDirectory ? countFiles(in: node) : 1)
        }
    }

    private static func countFiles(in node: FileNode) -> Int {
        var count = node.isDirectory ? 0 : 1
        for child in node.children {
            count += countFiles(in: child)
        }
        return count
    }
}

/// Selection formatting helpers
extension FileFilters {
    /// Format selection summary: "5 files (2.3 GB)"
    static func selectionSummary(for nodes: Set<FileNode>) -> String {
        guard !nodes.isEmpty else { return "No selection" }

        let count = nodes.count
        let size = ByteCountFormatter.string(fromByteCount: totalSize(of: nodes), countStyle: .file)
        let itemWord = count == 1 ? "item" : "items"

        return "\(count) \(itemWord) (\(size))"
    }
}

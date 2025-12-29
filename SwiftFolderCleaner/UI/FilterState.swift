import SwiftUI
import Observation

/// Deep module for filter state management
/// Encapsulates file type and size filtering and filtered tree generation
/// Hides complexity of tree filtering and cache invalidation
@MainActor
@Observable
final class FilterState {
    // MARK: - Private State

    /// Active file type filters
    private(set) var activeTypes: Set<FileType>

    /// Active size filter (single selection only)
    private(set) var activeSize: FileSizeFilter

    /// Filename filter pattern (supports wildcards like "*.ts" or exact names like "node_modules")
    private(set) var filenamePattern: String = ""

    /// Cache for filtered trees
    private var cachedFilteredTree: FileNode?
    private var lastSourceNode: FileNode?
    private var lastActiveTypes: Set<FileType>?
    private var lastActiveSize: FileSizeFilter?
    private var lastFilenamePattern: String?

    // MARK: - Public API (Deep Module: 3 properties + 3 methods)

    /// Currently active filter types (read-only access)
    var types: Set<FileType> {
        activeTypes
    }

    /// Currently active size filter (read-only access)
    var size: FileSizeFilter {
        activeSize
    }

    /// Currently active filename pattern (read-only access)
    var filename: String {
        filenamePattern
    }

    // MARK: - Initialization

    init() {
        self.activeTypes = Set(FileType.allCases)
        self.activeSize = .all // Default to showing all sizes
    }

    // MARK: - Filtering

    /// Toggle a file type filter
    /// Prevents empty filter state (minimum 1 type always selected)
    func toggle(_ type: FileType) {
        if activeTypes.contains(type) {
            // Don't allow deselecting the last type
            guard activeTypes.count > 1 else { return }
            activeTypes.remove(type)
        } else {
            activeTypes.insert(type)
        }
    }

    /// Set the size filter (radio button behavior)
    /// Only one size filter can be active at a time
    func toggleSize(_ size: FileSizeFilter) {
        activeSize = size
    }

    /// Set the filename filter pattern
    /// Supports wildcards (*.ts) and exact names (node_modules)
    func setFilenamePattern(_ pattern: String) {
        filenamePattern = pattern.trimmingCharacters(in: .whitespaces)
    }

    /// Get filtered tree from source node
    /// Hides complexity of caching and tree filtering
    /// The source node itself (navigation root) always passes through, but its children are filtered
    func filteredTree(from source: FileNode) -> FileNode {
        // Return cache if unchanged
        if let cached = cachedFilteredTree,
           lastSourceNode?.path.standardized == source.path.standardized,
           lastActiveTypes == activeTypes,
           lastActiveSize == activeSize,
           lastFilenamePattern == filenamePattern {
            return cached
        }

        // Build filter list
        var filters: [FileTreeFilter] = [FileTypeFilter(activeTypes)]

        // Apply size filter if not showing all sizes
        if activeSize != .all {
            filters.append(SizeFilter.largerThan(activeSize.threshold))
        }

        // Apply filename filter if pattern is not empty
        if !filenamePattern.isEmpty {
            filters.append(FilenameFilter(pattern: filenamePattern))
        }

        // Apply filters to children (not the source node itself, which is the navigation context)
        let filterCombined = AndFilter(filters)
        let filteredChildren = source.children.compactMap { child in
            child.filtered(by: filterCombined)
        }

        // Create filtered version of source with filtered children
        let filteredTotalSize = filteredChildren.reduce(0) { $0 + $1.totalSize }
        let filteredFileCount = filteredChildren.isEmpty ? 0 : filteredChildren.reduce(0) { $0 + $1.fileCount }
        let filteredMaxDepth = filteredChildren.isEmpty ? 0 : (filteredChildren.map(\.maxDepth).max() ?? 0) + 1

        let filtered = FileNode(
            path: source.path,
            name: source.name,
            size: source.size,
            fileType: source.fileType,
            modifiedDate: source.modifiedDate,
            children: filteredChildren,
            isDirectory: source.isDirectory,
            totalSize: filteredTotalSize,
            fileCount: filteredFileCount,
            maxDepth: filteredMaxDepth
        )

        // Update cache
        cachedFilteredTree = filtered
        lastSourceNode = source
        lastActiveTypes = activeTypes
        lastActiveSize = activeSize
        lastFilenamePattern = filenamePattern

        return filtered
    }
}

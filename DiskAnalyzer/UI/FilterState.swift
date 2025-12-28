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

    /// Cache for filtered trees
    private var cachedFilteredTree: FileNode?
    private var lastSourceNode: FileNode?
    private var lastActiveTypes: Set<FileType>?
    private var lastActiveSize: FileSizeFilter?

    // MARK: - Public API (Deep Module: 2 properties + 2 methods)

    /// Currently active filter types (read-only access)
    var types: Set<FileType> {
        activeTypes
    }

    /// Currently active size filter (read-only access)
    var size: FileSizeFilter {
        activeSize
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

    /// Get filtered tree from source node
    /// Hides complexity of caching and tree filtering
    func filteredTree(from source: FileNode) -> FileNode {
        // Return cache if unchanged
        if let cached = cachedFilteredTree,
           lastSourceNode?.path.standardized == source.path.standardized,
           lastActiveTypes == activeTypes,
           lastActiveSize == activeSize {
            return cached
        }

        // Build filter list
        var filters: [FileTreeFilter] = [FileTypeFilter(activeTypes)]

        // Apply size filter if not showing all sizes
        if activeSize != .all {
            filters.append(SizeFilter.largerThan(activeSize.threshold))
        }

        // Apply filters
        let filtered = source.filtered(by: AndFilter(filters)) ?? source

        // Update cache
        cachedFilteredTree = filtered
        lastSourceNode = source
        lastActiveTypes = activeTypes
        lastActiveSize = activeSize

        return filtered
    }
}

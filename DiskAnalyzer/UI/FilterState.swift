import SwiftUI
import Observation

/// Deep module for filter state management
/// Encapsulates file type filtering and filtered tree generation
/// Hides complexity of tree filtering and cache invalidation
@MainActor
@Observable
final class FilterState {
    // MARK: - Private State

    /// Active file type filters
    private(set) var activeTypes: Set<FileType>

    /// Cache for filtered trees
    private var cachedFilteredTree: FileNode?
    private var lastSourceNode: FileNode?
    private var lastActiveTypes: Set<FileType>?

    // MARK: - Public API (Deep Module: 1 property + 1 method)

    /// Currently active filter types (read-only access)
    var types: Set<FileType> {
        activeTypes
    }

    // MARK: - Initialization

    init() {
        self.activeTypes = Set(FileType.allCases)
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

    /// Get filtered tree from source node
    /// Hides complexity of caching and tree filtering
    func filteredTree(from source: FileNode) -> FileNode {
        // Return cache if unchanged
        if let cached = cachedFilteredTree,
           lastSourceNode?.path.standardized == source.path.standardized,
           lastActiveTypes == activeTypes {
            return cached
        }

        // Apply filter
        let filtered = source.filtered(by: activeTypes) ?? source

        // Update cache
        cachedFilteredTree = filtered
        lastSourceNode = source
        lastActiveTypes = activeTypes

        return filtered
    }
}

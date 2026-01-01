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
    private var cachedFilteredTree: FileItem?
    private var lastSourceItem: FileItem?
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

    /// Get filtered tree from source item
    /// Hides complexity of caching and tree filtering
    /// The source item itself (navigation root) always passes through, but its children are filtered
    func filteredTree(from source: FileItem) -> FileItem {
        // Return cache if unchanged
        if let cached = cachedFilteredTree,
           lastSourceItem?.path.standardized == source.path.standardized,
           lastActiveTypes == activeTypes,
           lastActiveSize == activeSize,
           lastFilenamePattern == filenamePattern {
            return cached
        }

        // Apply type filter to children using existing filtered method
        let filteredChildren = source.children.compactMap { child in
            child.filtered(by: activeTypes)
        }

        // Further filter by size if needed
        let sizeFilteredChildren: [FileItem]
        if activeSize != .all {
            sizeFilteredChildren = filteredChildren.filter { child in
                !child.isDirectory && child.totalSize >= activeSize.threshold
            }
        } else {
            sizeFilteredChildren = filteredChildren
        }

        // Further filter by filename pattern if needed
        let finalChildren: [FileItem]
        if !filenamePattern.isEmpty {
            let filter = FilenameFilter(pattern: filenamePattern)
            finalChildren = sizeFilteredChildren.filter { child in
                filter.matches(child)
            }
        } else {
            finalChildren = sizeFilteredChildren
        }

        // Create filtered version of source with filtered children
        let filtered = FileItem.directory(
            path: source.path,
            name: source.name,
            modifiedDate: source.modifiedDate,
            children: finalChildren
        )

        // Update cache
        cachedFilteredTree = filtered
        lastSourceItem = source
        lastActiveTypes = activeTypes
        lastActiveSize = activeSize
        lastFilenamePattern = filenamePattern

        return filtered
    }
}

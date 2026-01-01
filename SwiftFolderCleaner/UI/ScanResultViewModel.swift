import SwiftUI
import Observation

/// Deep module coordinating scan result display
/// Delegates to specialized sub-modules for navigation, selection, and filtering
/// Hides complexity of state coordination and synchronization
@MainActor
@Observable
final class ScanResultViewModel {
    // MARK: - Core State (Immutable)

    /// The root file item (immutable) - single source of truth
    let rootItem: FileItem

    // MARK: - Sub-Modules (Deep modules handling specific concerns)

    /// Navigation state (path, breadcrumb, navigation actions)
    let navigation: NavigationState

    /// Selection state (current selection, validation)
    let selection: SelectionState

    /// Filter state (active types, filtered tree generation)
    let filter: FilterState

    /// Treemap layout engine (delegates layout calculations)
    let treemapViewModel = TreemapViewModel()

    /// File operations service (show in Finder, delete, etc.)
    private let fileOperations = FileOperationsService()

    /// Action feedback message
    private(set) var actionMessage: String?

    // MARK: - Performance Caches

    /// Cached filtered tree (invalidated when navigation or filter changes)
    private var cachedFilteredRoot: FileItem?
    private var lastNavigationPath: URL?
    private var lastFilterTypes: Set<FileType>?
    private var lastActiveSize: FileSizeFilter?
    private var lastFilenamePattern: String?

    /// Cached breadcrumb trail (invalidated when navigation changes)
    private var cachedBreadcrumb: [FileItem]?
    private var lastBreadcrumbPath: [URL]?

    /// Filter version to force view updates
    private(set) var filterVersion = 0

    // MARK: - Derived State (Computed from sub-modules)

    /// Current directory (from navigation)
    var currentRoot: FileItem {
        navigation.currentItem
    }

    /// Breadcrumb trail (from navigation) - cached for performance
    var breadcrumbTrail: [FileItem] {
        let currentPath = navigation.currentPath

        // Return cache if path unchanged
        if let cached = cachedBreadcrumb,
           let lastPath = lastBreadcrumbPath,
           lastPath.count == currentPath.count,
           zip(lastPath, currentPath).allSatisfy({ $0.standardized == $1.standardized }) {
            return cached
        }

        // Recompute and cache
        let breadcrumb = navigation.breadcrumb
        cachedBreadcrumb = breadcrumb
        lastBreadcrumbPath = currentPath

        return breadcrumb
    }

    /// Selected node (from selection)
    var selectedNode: FileItem? {
        selection.selected
    }

    /// Selected path for table binding
    var selectedPath: URL? {
        get { selection.selected?.path }
        set {
            if let path = newValue {
                // Find node by path in displayFiles
                if let node = displayFiles.first(where: { $0.path == path }) {
                    selection.select(node)
                }
            } else {
                selection.select(nil)
            }
        }
    }

    /// Active file types (from filter)
    var selectedTypes: Set<FileType> {
        filter.types
    }

    /// Active size filter (from filter)
    var selectedSize: FileSizeFilter {
        filter.size
    }

    /// Flattened list of files for display
    /// This is the SINGLE SOURCE OF TRUTH for filtered data used by both TreemapView and FileListView
    var displayFiles: [FileItem] {
        let types = filter.types
        let sizeFilter = filter.size
        let filenamePattern = filter.filename
        let currentItem = navigation.currentItem

        let minSize: Int64? = sizeFilter == .all ? nil : sizeFilter.threshold

        // Get all descendants of current item
        var allItems: [FileItem] = []
        collectItems(from: currentItem, into: &allItems)

        // Apply filters
        return allItems.filter { item in
            // Type filter
            guard types.contains(item.fileType) else { return false }

            // Size filter
            if let minSize = minSize, !item.isDirectory {
                guard item.totalSize >= minSize else { return false }
            }

            // Filename filter
            if !filenamePattern.isEmpty {
                let filter = FilenameFilter(pattern: filenamePattern)
                guard filter.matches(item) else { return false }
            }

            return true
        }
    }

    /// Helper to collect all items from a tree
    private func collectItems(from item: FileItem, into array: inout [FileItem]) {
        for child in item.children {
            array.append(child)
            if child.isDirectory {
                collectItems(from: child, into: &array)
            }
        }
    }

    /// Filtered tree (coordinated: navigation + filter) - cached for performance
    /// Uses direct tree filtering (faster than rebuild from flat list)
    var filteredRoot: FileItem {
        let currentItem = navigation.currentItem
        let currentTypes = filter.types
        let currentSize = filter.size
        let currentFilename = filter.filename

        // Return cache if unchanged
        if let cached = cachedFilteredRoot,
           lastNavigationPath == currentItem.path,
           lastFilterTypes == currentTypes,
           lastActiveSize == currentSize,
           lastFilenamePattern == currentFilename {
            return cached
        }

        // Recompute using direct tree filtering (fast!)
        let filtered = filter.filteredTree(from: currentItem)

        // Cache result
        cachedFilteredRoot = filtered
        lastNavigationPath = currentItem.path
        lastFilterTypes = currentTypes
        lastActiveSize = currentSize
        lastFilenamePattern = currentFilename

        return filtered
    }

    // MARK: - Initialization

    init(rootItem: FileItem) {
        self.rootItem = rootItem

        // Initialize sub-modules
        self.navigation = NavigationState(rootItem: rootItem)
        self.filter = FilterState()
        self.selection = SelectionState(rootItem: rootItem)
    }

    // MARK: - Navigation Actions (Delegate to NavigationState)

    /// Navigate to a specific directory (e.g., double-click)
    func drillDown(to item: FileItem) {
        navigation.navigate(.drillDown(item))
        selection.select(nil) // Clear selection when drilling down
        treemapViewModel.invalidateLayout()
    }

    /// Navigate up one level (e.g., Escape key)
    func navigateUp() {
        navigation.navigate(.up)
        selection.select(nil)
        treemapViewModel.invalidateLayout()
    }

    /// Navigate to a specific node path in the breadcrumb trail
    func navigateToBreadcrumb(at index: Int) {
        navigation.navigate(.toBreadcrumb(index: index))
        selection.select(nil)
        treemapViewModel.invalidateLayout()
    }

    /// Navigate back to scan root
    func resetToRoot() {
        navigation.navigate(.toRoot)
        selection.select(nil)
        treemapViewModel.invalidateLayout()
    }

    /// Check if we can navigate up
    func canNavigateUp() -> Bool {
        navigation.canNavigateUp
    }

    // MARK: - Selection Actions (Delegate to SelectionState)

    /// Select an item (single click in treemap or list)
    func selectNode(_ item: FileItem?) {
        selection.select(item)
    }

    // MARK: - Filter Actions (Delegate to FilterState)

    /// Toggle a file type filter (click in legend)
    func toggleFileType(_ type: FileType) {
        filter.toggle(type)

        // Invalidate caches (displayFiles will change)
        cachedFilteredRoot = nil
        filterVersion += 1

        // Validate selection after filtering (using rebuilt tree)
        selection.clearInvalidSelections(in: filteredRoot)

        // Invalidate layout to trigger re-filtering
        treemapViewModel.invalidateLayout()
    }

    /// Toggle a size filter (click in size legend)
    func toggleSizeFilter(_ size: FileSizeFilter) {
        filter.toggleSize(size)

        // Invalidate caches (displayFiles will change)
        cachedFilteredRoot = nil
        filterVersion += 1

        // Validate selection after filtering (using rebuilt tree)
        selection.clearInvalidSelections(in: filteredRoot)

        // Invalidate layout to trigger re-filtering
        treemapViewModel.invalidateLayout()
    }

    /// Set filename filter pattern
    func setFilenameFilter(_ pattern: String) {
        filter.setFilenamePattern(pattern)

        // Invalidate caches (displayFiles will change)
        cachedFilteredRoot = nil
        filterVersion += 1

        // Validate selection after filtering (using rebuilt tree)
        selection.clearInvalidSelections(in: filteredRoot)

        // Invalidate layout to trigger re-filtering
        treemapViewModel.invalidateLayout()
    }

    // MARK: - File Actions (Delegate to FileOperationsService)

    /// Show selected node in Finder
    func showInFinder() {
        guard let node = selectedNode else { return }
        fileOperations.showInFinder(node)
    }

    /// Open selected node in Preview
    func showInPreview() {
        guard let node = selectedNode else { return }
        fileOperations.showInPreview(node)
    }

    /// Check if selected node can be previewed
    var canPreviewSelection: Bool {
        guard let node = selectedNode else { return false }
        return fileOperations.canPreview(node)
    }

    /// Delete selected node (move to trash)
    func deleteSelected() async {
        guard let node = selectedNode else { return }

        let result = await fileOperations.moveToTrash(node)
        actionMessage = fileOperations.formatResultMessage(result)

        // Clear selection after delete
        if case .success = result {
            selection.select(nil)
        }

        // Clear message after 3 seconds
        try? await Task.sleep(for: .seconds(3))
        actionMessage = nil
    }

}

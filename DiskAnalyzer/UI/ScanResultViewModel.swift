import SwiftUI
import Observation

/// Deep module coordinating scan result display
/// Delegates to specialized sub-modules for navigation, selection, and filtering
/// Hides complexity of state coordination and synchronization
@MainActor
@Observable
final class ScanResultViewModel {
    // MARK: - Core State (Immutable)

    /// The original scan result (immutable) - single source of truth
    let scanResult: ScanResult

    // MARK: - Sub-Modules (Deep modules handling specific concerns)

    /// Navigation state (path, breadcrumb, navigation actions)
    let navigation: NavigationState

    /// Selection state (current selection, validation)
    let selection: SelectionState

    /// Filter state (active types, filtered tree generation)
    let filter: FilterState

    // MARK: - Layout & Operations

    /// Treemap layout engine (delegates layout calculations)
    let treemapViewModel = TreemapViewModel()

    /// File operations service (show in Finder, delete, etc.)
    private let fileOperations = FileOperationsService()

    /// Query engine for search and statistics
    private let query: FileTreeQuery

    /// Action feedback message
    private(set) var actionMessage: String?

    // MARK: - Performance Caches

    /// Cached flattened files list (invalidated when tree changes)
    private var cachedDisplayFiles: [FileNode]?
    private var lastDisplayTree: FileNode?

    /// Cached filtered tree (invalidated when navigation or filter changes)
    private var cachedFilteredRoot: FileNode?
    private var lastNavigationPath: URL?
    private var lastFilterTypes: Set<FileType>?

    /// Cached breadcrumb trail (invalidated when navigation changes)
    private var cachedBreadcrumb: [FileNode]?
    private var lastBreadcrumbPath: [URL]?

    // MARK: - Derived State (Computed from sub-modules)

    /// Current directory (from navigation)
    var currentRoot: FileNode {
        navigation.currentNode
    }

    /// Breadcrumb trail (from navigation) - cached for performance
    var breadcrumbTrail: [FileNode] {
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
    var selectedNode: FileNode? {
        selection.selected
    }

    /// Active file types (from filter)
    var selectedTypes: Set<FileType> {
        filter.types
    }

    /// Filtered tree (coordinated: navigation + filter) - cached for performance
    var filteredRoot: FileNode {
        let currentPath = navigation.currentNode.path
        let currentTypes = filter.types

        // Return cache if unchanged
        if let cached = cachedFilteredRoot,
           lastNavigationPath == currentPath,
           lastFilterTypes == currentTypes {
            return cached
        }

        // Recompute and cache
        let filtered = filter.filteredTree(from: navigation.currentNode)
        cachedFilteredRoot = filtered
        lastNavigationPath = currentPath
        lastFilterTypes = currentTypes

        return filtered
    }

    /// Flattened list of files for display (cached)
    var displayFiles: [FileNode] {
        let currentTree = filteredRoot

        // Return cache if tree unchanged
        if let cached = cachedDisplayFiles,
           lastDisplayTree?.path.standardized == currentTree.path.standardized {
            return cached
        }

        // Recompute and cache
        let files = currentTree.flatten()
        cachedDisplayFiles = files
        lastDisplayTree = currentTree

        return files
    }

    // MARK: - Initialization

    init(scanResult: ScanResult) {
        self.scanResult = scanResult

        // Initialize sub-modules
        self.navigation = NavigationState(rootNode: scanResult.rootNode)
        self.filter = FilterState()
        self.query = FileTreeQuery(root: scanResult.rootNode)

        // Initialize index asynchronously for large trees
        var asyncIndex: FileTreeIndex?
        if scanResult.rootNode.fileCount > 10_000 {
            Task {
                let builtIndex = await Task.detached {
                    scanResult.rootNode.createIndex()
                }.value
                asyncIndex = builtIndex
            }
        }

        self.selection = SelectionState(rootNode: scanResult.rootNode, index: asyncIndex)
    }

    // MARK: - Navigation Actions (Delegate to NavigationState)

    /// Navigate to a specific directory (e.g., double-click)
    func drillDown(to node: FileNode) {
        navigation.navigate(.drillDown(node))
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

    /// Select a node (single click in treemap or list)
    func selectNode(_ node: FileNode?) {
        selection.select(node)
    }

    // MARK: - Filter Actions (Delegate to FilterState)

    /// Toggle a file type filter (click in legend)
    func toggleFileType(_ type: FileType) {
        filter.toggle(type)

        // Validate selection after filtering
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

    // MARK: - Query Methods (Delegate to FileTreeQuery)

    /// Search for files by name
    func search(name: String) -> [FileNode] {
        query.find(.name(name))
    }

    /// Get statistics for current tree
    func getStatistics() -> FileTreeStatistics {
        query.statistics()
    }

    /// Get top N largest files
    func topFiles(count: Int = 10) -> [FileNode] {
        query.top(count, by: .size(filesOnly: true))
    }
}

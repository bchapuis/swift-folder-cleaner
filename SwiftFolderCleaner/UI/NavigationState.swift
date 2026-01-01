import SwiftUI
import Observation

/// Navigation action types for unified navigation handling
enum NavigationAction {
    case drillDown(FileItem)
    case up
    case toBreadcrumb(index: Int)
    case toRoot
}

/// Deep module for navigation state management
/// Encapsulates navigation path, breadcrumb generation, and navigation actions
/// Hides complexity of path manipulation and validation behind simple API
@MainActor
@Observable
final class NavigationState {
    // MARK: - Private State

    /// Navigation path from root to current directory
    private(set) var currentPath: [URL]

    /// Root item of the tree
    private let rootItem: FileItem

    // MARK: - Public API (Deep Module: 3 properties + 2 methods)

    /// Current directory item (derived from path)
    var currentItem: FileItem {
        findItem(at: currentPath.last ?? rootItem.path) ?? rootItem
    }

    /// Breadcrumb trail from root to current (derived from path)
    var breadcrumb: [FileItem] {
        currentPath.compactMap { url in
            findItem(at: url)
        }
    }

    /// Check if we can navigate up
    var canNavigateUp: Bool {
        currentPath.count > 1
    }

    // MARK: - Initialization

    init(rootItem: FileItem) {
        self.rootItem = rootItem
        self.currentPath = [rootItem.path]
    }

    // MARK: - Navigation

    /// Unified navigation action handler
    /// Hides complexity of path manipulation and validation
    func navigate(_ action: NavigationAction) {
        switch action {
        case .drillDown(let item):
            guard item.isDirectory else {
                return
            }

            // Build complete path from root to target item
            currentPath = buildPathToItem(item)

        case .up:
            guard currentPath.count > 1 else { return }
            currentPath.removeLast()

        case .toBreadcrumb(let index):
            guard index >= 0 && index < currentPath.count else { return }
            currentPath = Array(currentPath.prefix(index + 1))

        case .toRoot:
            currentPath = [rootItem.path]
        }
    }

    /// Check if a navigation action is valid
    func canNavigate(_ action: NavigationAction) -> Bool {
        switch action {
        case .drillDown(let item):
            return item.isDirectory
        case .up:
            return currentPath.count > 1
        case .toBreadcrumb(let index):
            return index >= 0 && index < currentPath.count
        case .toRoot:
            return currentPath.count > 1
        }
    }

    // MARK: - Private Helpers

    /// Find an item by path in the tree
    private func findItem(at path: URL) -> FileItem? {
        rootItem.findItem(at: path)
    }

    /// Build complete path from root to target item
    /// Efficiently constructs path by parsing the URL structure
    private func buildPathToItem(_ targetItem: FileItem) -> [URL] {
        let rootPath = rootItem.path.standardized.path
        let targetPath = targetItem.path.standardized.path

        // If target is the root, return immediately
        if targetPath == rootPath {
            return [rootItem.path]
        }

        // Ensure target is a descendant of root
        guard targetPath.hasPrefix(rootPath) else {
            return [rootItem.path]
        }

        // Build path by traversing from root to target
        // Extract the relative path from root to target
        let relativePath = String(targetPath.dropFirst(rootPath.count))
        let components = relativePath.split(separator: "/").map(String.init)

        // Start with root
        var path: [URL] = [rootItem.path]
        var currentItem = rootItem

        // Traverse down the tree following the path components
        for component in components {
            guard let child = currentItem.children.first(where: { $0.name == component }) else {
                return [rootItem.path]
            }
            path.append(child.path)
            currentItem = child
        }

        return path
    }
}

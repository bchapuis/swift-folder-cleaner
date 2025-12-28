import SwiftUI
import Observation

/// Navigation action types for unified navigation handling
enum NavigationAction {
    case drillDown(FileNode)
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

    /// Navigator for path-based operations
    private let navigator: FileTreeNavigator

    /// Root node of the tree
    private let rootNode: FileNode

    // MARK: - Public API (Deep Module: 3 properties + 2 methods)

    /// Current directory node (derived from path)
    var currentNode: FileNode {
        navigator.node(at: currentPath) ?? rootNode
    }

    /// Breadcrumb trail from root to current (derived from path)
    var breadcrumb: [FileNode] {
        navigator.breadcrumb(from: currentPath)
    }

    /// Check if we can navigate up
    var canNavigateUp: Bool {
        currentPath.count > 1
    }

    // MARK: - Initialization

    init(rootNode: FileNode) {
        self.rootNode = rootNode
        self.currentPath = [rootNode.path]
        self.navigator = FileTreeNavigator(root: rootNode)
    }

    // MARK: - Navigation

    /// Unified navigation action handler
    /// Hides complexity of path manipulation and validation
    func navigate(_ action: NavigationAction) {
        switch action {
        case .drillDown(let node):
            guard node.isDirectory else {
                return
            }

            // Build complete path from root to target node
            currentPath = buildPathToNode(node)

        case .up:
            guard currentPath.count > 1 else { return }
            currentPath.removeLast()

        case .toBreadcrumb(let index):
            guard index >= 0 && index < currentPath.count else { return }
            currentPath = Array(currentPath.prefix(index + 1))

        case .toRoot:
            currentPath = [rootNode.path]
        }
    }

    /// Check if a navigation action is valid
    func canNavigate(_ action: NavigationAction) -> Bool {
        switch action {
        case .drillDown(let node):
            return node.isDirectory
        case .up:
            return currentPath.count > 1
        case .toBreadcrumb(let index):
            return index >= 0 && index < currentPath.count
        case .toRoot:
            return currentPath.count > 1
        }
    }

    // MARK: - Private Helpers

    /// Build complete path from root to target node
    /// Efficiently constructs path by parsing the URL structure
    private func buildPathToNode(_ targetNode: FileNode) -> [URL] {
        let rootPath = rootNode.path.standardized.path
        let targetPath = targetNode.path.standardized.path

        // If target is the root, return immediately
        if targetPath == rootPath {
            return [rootNode.path]
        }

        // Ensure target is a descendant of root
        guard targetPath.hasPrefix(rootPath) else {
            return [rootNode.path]
        }

        // Build path by traversing from root to target
        // Extract the relative path from root to target
        let relativePath = String(targetPath.dropFirst(rootPath.count))
        let components = relativePath.split(separator: "/").map(String.init)

        // Start with root
        var path: [URL] = [rootNode.path]
        var currentNode = rootNode

        // Traverse down the tree following the path components
        for component in components {
            guard let child = currentNode.children.first(where: { $0.name == component }) else {
                return [rootNode.path]
            }
            path.append(child.path)
            currentNode = child
        }

        return path
    }
}

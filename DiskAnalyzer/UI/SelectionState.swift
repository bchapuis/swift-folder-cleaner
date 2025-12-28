import SwiftUI
import Observation

/// Deep module for selection state management
/// Encapsulates selection tracking and validation
/// Hides complexity of path-based selection and filtered tree validation
@MainActor
@Observable
final class SelectionState {
    // MARK: - Private State

    /// Currently selected node (cached for performance)
    private var selectedNode: FileNode?

    /// Root node for lookups
    private let rootNode: FileNode

    /// Optional index for fast lookups
    private let index: FileTreeIndex?

    // MARK: - Public API (Deep Module: 1 property + 2 methods)

    /// Currently selected node (cached - no tree traversal on access)
    var selected: FileNode? {
        selectedNode
    }

    // MARK: - Initialization

    init(rootNode: FileNode, index: FileTreeIndex?) {
        self.rootNode = rootNode
        self.index = index
    }

    // MARK: - Selection

    /// Select a node (or clear selection with nil)
    func select(_ node: FileNode?) {
        selectedNode = node
    }

    /// Clear invalid selections after filtering
    /// Automatically validates selection exists in filtered tree
    func clearInvalidSelections(in filteredTree: FileNode) {
        guard let node = selectedNode else { return }

        // Check if selected node still exists in filtered tree
        let stillExists = filteredTree.findNode(at: node.path) != nil

        if !stillExists {
            self.selectedNode = nil
        }
    }
}

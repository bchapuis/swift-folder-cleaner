import SwiftUI
import Observation

/// Deep module for selection state management
/// Encapsulates selection tracking and validation
/// Hides complexity of path-based selection and filtered tree validation
@MainActor
@Observable
final class SelectionState {
    // MARK: - Private State

    /// Currently selected item (cached for performance)
    private var selectedItem: FileItem?

    /// Root item for lookups
    private let rootItem: FileItem

    // MARK: - Public API (Deep Module: 1 property + 2 methods)

    /// Currently selected item (cached - no tree traversal on access)
    var selected: FileItem? {
        selectedItem
    }

    // MARK: - Initialization

    init(rootItem: FileItem) {
        self.rootItem = rootItem
    }

    // MARK: - Selection

    /// Select an item (or clear selection with nil)
    func select(_ item: FileItem?) {
        selectedItem = item
    }

    /// Clear invalid selections after filtering
    /// Automatically validates selection exists in filtered tree
    func clearInvalidSelections(in filteredTree: FileItem) {
        guard let item = selectedItem else { return }

        // Check if selected item still exists in filtered tree
        let stillExists = filteredTree.findItem(at: item.path) != nil

        if !stillExists {
            self.selectedItem = nil
        }
    }
}

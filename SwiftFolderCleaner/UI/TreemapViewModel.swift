import SwiftUI
import Observation

/// Layout-only ViewModel for treemap visualization
/// All navigation/selection state managed by ScanResultViewModel
@MainActor
@Observable
final class TreemapViewModel {
    // MARK: - Layout State

    private(set) var rectangles: [TreemapRectangle] = []
    private(set) var hoveredItem: FileItem?
    private(set) var isLayoutValid = false

    // MARK: - Performance Caches

    private var cachedSize: CGSize = .zero
    private var cachedRootItem: FileItem?

    /// Fast lookup for which nodes have children laid out (avoids O(n²) search)
    private var itemPathsSet: Set<URL> = []

    /// Rectangles to actually draw (cached, filtered)
    private(set) var drawableRectangles: [TreemapRectangle] = []

    /// Fast lookup for rectangles by node path (avoids O(n) search for selection/hover)
    private var rectanglesByPath: [URL: TreemapRectangle] = [:]

    // MARK: - Layout Management

    func updateLayout(rootItem: FileItem, size: CGSize) {
        // Check if we need to recalculate
        guard shouldRecalculateLayout(rootItem: rootItem, size: size) else {
            return
        }

        // Calculate new layout with size-based threshold
        // Only recurse into directories >= 0.5% of current root size
        rectangles = TreemapLayout.layout(
            item: rootItem,
            in: CGRect(origin: .zero, size: size),
            minSizeThreshold: 0.005
        )

        // Build fast lookup structures (use standardized URLs for consistency)
        itemPathsSet = Set(rectangles.map { $0.item.path.standardized })
        rectanglesByPath = Dictionary(uniqueKeysWithValues: rectangles.map { ($0.item.path.standardized, $0) })

        // Pre-filter drawable rectangles to avoid O(n²) in draw loop
        drawableRectangles = rectangles.filter { rectangle in
            if !rectangle.item.isDirectory {
                return true // Always draw files
            } else if rectangle.item.children.isEmpty {
                return true // Always draw empty directories
            } else {
                // For directories with children: only draw if children are NOT laid out
                let hasLaidOutChildren = rectangle.item.children.contains {
                    itemPathsSet.contains($0.path.standardized)
                }
                return !hasLaidOutChildren
            }
        }

        // Update cache
        cachedSize = size
        cachedRootItem = rootItem
        isLayoutValid = true
    }

    /// Fast lookup for rectangle by node path (O(1) instead of O(n))
    func rectangle(for path: URL) -> TreemapRectangle? {
        rectanglesByPath[path.standardized]
    }

    func invalidateLayout() {
        isLayoutValid = false
    }

    // MARK: - Hit Testing

    func findNode(at location: CGPoint) -> FileItem? {
        // Find in rectangles (reverse order to hit top-most first)
        rectangles.reversed().first(where: { $0.rect.contains(location) })?.item
    }

    func updateHover(at location: CGPoint?) {
        if let location {
            hoveredItem = findNode(at: location)
        } else {
            hoveredItem = nil
        }
    }

    // MARK: - Helper Methods

    private func shouldRecalculateLayout(rootItem: FileItem, size: CGSize) -> Bool {
        // Size changed significantly (more than 1pt)
        if abs(size.width - cachedSize.width) > 1 || abs(size.height - cachedSize.height) > 1 {
            return true
        }

        // Root node changed
        if rootItem.path.standardized != cachedRootItem?.path.standardized {
            return true
        }

        // Layout was invalidated
        if !isLayoutValid {
            return true
        }

        return false
    }
}

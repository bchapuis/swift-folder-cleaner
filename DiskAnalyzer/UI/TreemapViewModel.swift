import SwiftUI
import Observation

/// ViewModel for treemap with caching and performance optimizations
@MainActor
@Observable
final class TreemapViewModel {
    // MARK: - State

    private(set) var rectangles: [TreemapRectangle] = []
    private(set) var hoveredNode: FileNode?
    private(set) var isLayoutValid = false

    // MARK: - Cache

    private var cachedSize: CGSize = .zero
    private var cachedRootNode: FileNode?
    private var cachedDisplayNode: FileNode?
    private var hitTestCache: [CGPoint: FileNode] = [:]

    // MARK: - Configuration

    private let hitTestCacheSize = 100 // Cache last 100 hit tests

    // MARK: - Layout Management

    func updateLayout(rootNode: FileNode, displayNode: FileNode, size: CGSize) {
        // Check if we need to recalculate
        guard shouldRecalculateLayout(rootNode: rootNode, displayNode: displayNode, size: size) else {
            return
        }

        // Invalidate caches
        hitTestCache.removeAll()

        // Calculate new layout
        rectangles = TreemapLayout.layout(
            node: displayNode,
            in: CGRect(origin: .zero, size: size)
        )

        // Update cache
        cachedSize = size
        cachedRootNode = rootNode
        cachedDisplayNode = displayNode
        isLayoutValid = true
    }

    func invalidateLayout() {
        isLayoutValid = false
        hitTestCache.removeAll()
    }

    // MARK: - Hit Testing

    func findNode(at location: CGPoint) -> FileNode? {
        // Check cache first
        if let cached = hitTestCache[location] {
            return cached
        }

        // Find in rectangles
        guard let rect = rectangles.first(where: { $0.rect.contains(location) }) else {
            return nil
        }

        // Cache result (with size limit)
        if hitTestCache.count >= hitTestCacheSize {
            // Remove oldest entry (simple FIFO)
            if let firstKey = hitTestCache.keys.first {
                hitTestCache.removeValue(forKey: firstKey)
            }
        }
        hitTestCache[location] = rect.node

        return rect.node
    }

    func updateHover(at location: CGPoint?) {
        if let location {
            hoveredNode = findNode(at: location)
        } else {
            hoveredNode = nil
        }
    }

    // MARK: - Helper Methods

    private func shouldRecalculateLayout(rootNode: FileNode, displayNode: FileNode, size: CGSize) -> Bool {
        // Size changed significantly (more than 1pt)
        if abs(size.width - cachedSize.width) > 1 || abs(size.height - cachedSize.height) > 1 {
            return true
        }

        // Display node changed
        if displayNode.path != cachedDisplayNode?.path {
            return true
        }

        // Root node changed
        if rootNode.path != cachedRootNode?.path {
            return true
        }

        // Layout was invalidated
        if !isLayoutValid {
            return true
        }

        return false
    }
}

// MARK: - Performance Monitoring

extension TreemapViewModel {
    func logPerformance() {
        print("TreemapViewModel Performance:")
        print("  - Rectangles: \(rectangles.count)")
        print("  - Hit test cache size: \(hitTestCache.count)")
        print("  - Layout valid: \(isLayoutValid)")
    }
}

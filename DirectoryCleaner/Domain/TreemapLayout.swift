import Foundation
import CoreGraphics

/// Treemap layout engine using squarified algorithm
struct TreemapLayout {
    /// Generates treemap rectangles from a file node tree
    /// - Parameters:
    ///   - node: Root node to layout
    ///   - bounds: Available rectangle to fill
    ///   - minSizeThreshold: Minimum size (as fraction of root, 0.0-1.0) to recurse into (default 0.005 = 0.5%)
    /// - Returns: Array of rectangles representing each file/folder
    static func layout(node: FileNode, in bounds: CGRect, minSizeThreshold: Double = 0.005) -> [TreemapRectangle] {
        var rectangles: [TreemapRectangle] = []

        // Only layout if the node has size
        guard node.totalSize > 0 else {
            return rectangles
        }

        // Calculate absolute minimum size from threshold
        let minSize = Int64(Double(node.totalSize) * minSizeThreshold)

        // Always add the node itself as a rectangle
        rectangles.append(TreemapRectangle(node: node, rect: bounds))

        // If it's a directory with children, layout children on top
        if node.isDirectory && !node.children.isEmpty {
            let children = node.children
                .filter { $0.totalSize > 0 }  // Filter out empty items
                .sorted { $0.totalSize > $1.totalSize }  // Sort by size (largest first)

            squarify(
                children: children,
                bounds: bounds,
                totalSize: node.totalSize,
                minSize: minSize,
                output: &rectangles
            )
        }

        return rectangles
    }

    // MARK: - Squarified Algorithm

    private static func squarify(
        children: [FileNode],
        bounds: CGRect,
        totalSize: Int64,
        minSize: Int64,
        output: inout [TreemapRectangle]
    ) {
        guard !children.isEmpty, bounds.width > 0, bounds.height > 0 else { return }

        var remaining = children
        var currentBounds = bounds
        var remainingSize = totalSize

        while !remaining.isEmpty && currentBounds.width > 0 && currentBounds.height > 0 {
            // Determine layout direction based on aspect ratio
            let width = currentBounds.width
            let height = currentBounds.height

            // Build a row of items
            var row: [FileNode] = []
            var rowSize: Int64 = 0

            // Try to add items to the row while improving aspect ratio
            for node in remaining {
                let newRow = row + [node]
                let newRowSize = rowSize + node.totalSize

                let currentWorst = worstAspectRatio(
                    row: row,
                    rowSize: rowSize,
                    bounds: currentBounds,
                    totalSize: remainingSize
                )
                let newWorst = worstAspectRatio(
                    row: newRow,
                    rowSize: newRowSize,
                    bounds: currentBounds,
                    totalSize: remainingSize
                )

                if row.isEmpty || newWorst <= currentWorst {
                    // Adding this item improves or maintains aspect ratio
                    row = newRow
                    rowSize = newRowSize
                } else {
                    // Stop adding items to this row
                    break
                }
            }

            // Layout the row
            if !row.isEmpty {
                let rowRects = layoutRow(
                    row: row,
                    rowSize: rowSize,
                    bounds: currentBounds,
                    totalSize: remainingSize
                )

                // Add rectangles for items in the row
                for (node, rect) in zip(row, rowRects) {
                    // Always add the node itself as a rectangle (directories and files)
                    output.append(TreemapRectangle(node: node, rect: rect))

                    // Only recurse if node is large enough (size-based threshold)
                    if node.isDirectory && !node.children.isEmpty && node.totalSize >= minSize {
                        // Recursively layout children (will be drawn on top)
                        let children = node.children
                            .filter { $0.totalSize > 0 }
                            .sorted { $0.totalSize > $1.totalSize }

                        squarify(
                            children: children,
                            bounds: rect,
                            totalSize: node.totalSize,
                            minSize: minSize,
                            output: &output
                        )
                    }
                }

                // Update remaining items and bounds
                remaining.removeFirst(row.count)
                remainingSize -= rowSize

                // Calculate how much space the row took
                let rowWidth: CGFloat
                let rowHeight: CGFloat

                if width >= height {
                    // Layout horizontally (across the width)
                    rowWidth = currentBounds.width
                    rowHeight = currentBounds.height * CGFloat(rowSize) / CGFloat(remainingSize + rowSize)
                    currentBounds.origin.y += rowHeight
                    currentBounds.size.height -= rowHeight
                } else {
                    // Layout vertically (down the height)
                    rowWidth = currentBounds.width * CGFloat(rowSize) / CGFloat(remainingSize + rowSize)
                    rowHeight = currentBounds.height
                    currentBounds.origin.x += rowWidth
                    currentBounds.size.width -= rowWidth
                }
            } else {
                // Safety: if we can't add any items, break to avoid infinite loop
                break
            }
        }
    }

    // MARK: - Helper Functions

    /// Calculates the worst aspect ratio in a row
    private static func worstAspectRatio(
        row: [FileNode],
        rowSize: Int64,
        bounds: CGRect,
        totalSize: Int64
    ) -> CGFloat {
        guard !row.isEmpty, rowSize > 0, totalSize > 0 else { return .infinity }

        let width = bounds.width
        let height = bounds.height

        let rowWidth: CGFloat
        let rowHeight: CGFloat

        if width >= height {
            // Laying out horizontally
            rowWidth = width
            rowHeight = height * CGFloat(rowSize) / CGFloat(totalSize)
        } else {
            // Laying out vertically
            rowWidth = width * CGFloat(rowSize) / CGFloat(totalSize)
            rowHeight = height
        }

        guard rowWidth > 0, rowHeight > 0 else { return .infinity }

        // Find worst aspect ratio among items in the row
        var maxAspect: CGFloat = 0
        for node in row {
            let itemArea = rowWidth * rowHeight * CGFloat(node.totalSize) / CGFloat(rowSize)
            let itemWidth: CGFloat
            let itemHeight: CGFloat

            if width >= height {
                // Items laid out horizontally across the row
                itemHeight = rowHeight
                itemWidth = itemArea / itemHeight
            } else {
                // Items laid out vertically down the row
                itemWidth = rowWidth
                itemHeight = itemArea / itemWidth
            }

            guard itemWidth > 0, itemHeight > 0 else { continue }

            let aspect = max(itemWidth / itemHeight, itemHeight / itemWidth)
            maxAspect = max(maxAspect, aspect)
        }

        return maxAspect
    }

    /// Layouts items in a row
    private static func layoutRow(
        row: [FileNode],
        rowSize: Int64,
        bounds: CGRect,
        totalSize: Int64
    ) -> [CGRect] {
        var rectangles: [CGRect] = []

        let width = bounds.width
        let height = bounds.height

        let rowWidth: CGFloat
        let rowHeight: CGFloat
        let isHorizontal = width >= height

        if isHorizontal {
            // Laying out horizontally across the width
            rowWidth = width
            rowHeight = height * CGFloat(rowSize) / CGFloat(totalSize)
        } else {
            // Laying out vertically down the height
            rowWidth = width * CGFloat(rowSize) / CGFloat(totalSize)
            rowHeight = height
        }

        var offset: CGFloat = 0

        for node in row {
            let itemFraction = CGFloat(node.totalSize) / CGFloat(rowSize)

            let rect: CGRect
            if isHorizontal {
                // Items go across horizontally
                let itemWidth = rowWidth * itemFraction
                rect = CGRect(
                    x: bounds.origin.x + offset,
                    y: bounds.origin.y,
                    width: itemWidth,
                    height: rowHeight
                )
                offset += itemWidth
            } else {
                // Items go down vertically
                let itemHeight = rowHeight * itemFraction
                rect = CGRect(
                    x: bounds.origin.x,
                    y: bounds.origin.y + offset,
                    width: rowWidth,
                    height: itemHeight
                )
                offset += itemHeight
            }

            rectangles.append(rect)
        }

        return rectangles
    }
}

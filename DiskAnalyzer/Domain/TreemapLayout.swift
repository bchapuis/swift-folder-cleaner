import Foundation
import CoreGraphics

/// Treemap layout engine using squarified algorithm
struct TreemapLayout {
    /// Generates treemap rectangles from a file node tree
    /// - Parameters:
    ///   - node: Root node to layout
    ///   - bounds: Available rectangle to fill
    /// - Returns: Array of rectangles representing each file/folder
    static func layout(node: FileNode, in bounds: CGRect) -> [TreemapRectangle] {
        var rectangles: [TreemapRectangle] = []

        // Only layout if the node has size
        guard node.totalSize > 0 else {
            return rectangles
        }

        // If it's a file (leaf node), create a single rectangle
        if !node.isDirectory || node.children.isEmpty {
            rectangles.append(TreemapRectangle(node: node, rect: bounds))
            return rectangles
        }

        // Layout children using squarified algorithm
        let children = node.children
            .filter { $0.totalSize > 0 }  // Filter out empty items
            .sorted { $0.totalSize > $1.totalSize }  // Sort by size (largest first)

        squarify(children: children, bounds: bounds, totalSize: node.totalSize, output: &rectangles)

        return rectangles
    }

    // MARK: - Squarified Algorithm

    private static func squarify(
        children: [FileNode],
        bounds: CGRect,
        totalSize: Int64,
        output: inout [TreemapRectangle]
    ) {
        guard !children.isEmpty else { return }

        var remaining = children
        var currentBounds = bounds

        while !remaining.isEmpty {
            // Get the shortest side of the current bounds
            let width = currentBounds.width
            let height = currentBounds.height
            let isHorizontal = width >= height
            let shortestSide = min(width, height)

            // Build a row of items
            var row: [FileNode] = []
            var rowSize: Int64 = 0

            // Try to add items to the row while improving aspect ratio
            for node in remaining {
                let newRow = row + [node]
                let newRowSize = rowSize + node.totalSize

                let currentWorst = worstAspectRatio(row: row, rowSize: rowSize, side: shortestSide, totalSize: totalSize)
                let newWorst = worstAspectRatio(row: newRow, rowSize: newRowSize, side: shortestSide, totalSize: totalSize)

                if row.isEmpty || newWorst < currentWorst {
                    // Adding this item improves aspect ratio
                    row = newRow
                    rowSize = newRowSize
                } else {
                    // Stop adding items to this row
                    break
                }
            }

            // Layout the row
            if !row.isEmpty {
                let rowRect = layoutRow(
                    row: row,
                    rowSize: rowSize,
                    bounds: currentBounds,
                    totalSize: totalSize,
                    isHorizontal: isHorizontal
                )

                // Add rectangles for items in the row
                for (node, rect) in zip(row, rowRect) {
                    if node.isDirectory && !node.children.isEmpty {
                        // Recursively layout children
                        let childRects = layout(node: node, in: rect)
                        output.append(contentsOf: childRects)
                    } else {
                        // Leaf node - add as rectangle
                        output.append(TreemapRectangle(node: node, rect: rect))
                    }
                }

                // Update remaining items and bounds
                remaining.removeFirst(row.count)

                // Calculate remaining bounds
                let rowLength = CGFloat(rowSize) * (isHorizontal ? currentBounds.width : currentBounds.height) / CGFloat(totalSize)
                if isHorizontal {
                    currentBounds.origin.y += rowLength
                    currentBounds.size.height -= rowLength
                } else {
                    currentBounds.origin.x += rowLength
                    currentBounds.size.width -= rowLength
                }
            } else {
                // Safety: if we can't add any items, break to avoid infinite loop
                break
            }
        }
    }

    // MARK: - Helper Functions

    /// Calculates the worst aspect ratio in a row
    private static func worstAspectRatio(row: [FileNode], rowSize: Int64, side: CGFloat, totalSize: Int64) -> CGFloat {
        guard !row.isEmpty, rowSize > 0 else { return .infinity }

        let rowLength = CGFloat(rowSize) / CGFloat(totalSize) * side

        var maxAspect: CGFloat = 0
        for node in row {
            let itemLength = CGFloat(node.totalSize) / CGFloat(rowSize) * rowLength
            let aspect = max(side / itemLength, itemLength / side)
            maxAspect = max(maxAspect, aspect)
        }

        return maxAspect
    }

    /// Layouts items in a row
    private static func layoutRow(
        row: [FileNode],
        rowSize: Int64,
        bounds: CGRect,
        totalSize: Int64,
        isHorizontal: Bool
    ) -> [CGRect] {
        var rectangles: [CGRect] = []

        let rowLength = CGFloat(rowSize) / CGFloat(totalSize) * (isHorizontal ? bounds.width : bounds.height)
        var offset: CGFloat = 0

        for node in row {
            let itemLength = CGFloat(node.totalSize) / CGFloat(rowSize) * rowLength

            let rect: CGRect
            if isHorizontal {
                rect = CGRect(
                    x: bounds.origin.x + offset,
                    y: bounds.origin.y,
                    width: itemLength,
                    height: rowLength
                )
            } else {
                rect = CGRect(
                    x: bounds.origin.x,
                    y: bounds.origin.y + offset,
                    width: rowLength,
                    height: itemLength
                )
            }

            rectangles.append(rect)
            offset += itemLength
        }

        return rectangles
    }
}

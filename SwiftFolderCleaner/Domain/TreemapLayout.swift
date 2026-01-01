import Foundation
import CoreGraphics
import SwiftData

/// Treemap layout engine using squarified algorithm
struct TreemapLayout {
    /// Generates treemap rectangles from a file item tree
    /// - Parameters:
    ///   - item: Root item to layout
    ///   - bounds: Available rectangle to fill
    ///   - minSizeThreshold: Minimum size (as fraction of root, 0.0-1.0) to recurse into (default 0.005 = 0.5%)
    /// - Returns: Array of rectangles representing each file/folder
    static func layout(item: FileItem, in bounds: CGRect, minSizeThreshold: Double = 0.005) -> [TreemapRectangle] {
        var rectangles: [TreemapRectangle] = []

        // Only layout if the item has size
        guard item.totalSize > 0 else {
            return rectangles
        }

        // Calculate absolute minimum size from threshold
        let minSize = Int64(Double(item.totalSize) * minSizeThreshold)

        // Always add the item itself as a rectangle
        rectangles.append(TreemapRectangle(item: item, rect: bounds))

        // If it's a directory with children, layout children on top
        if item.isDirectory && !item.children.isEmpty {
            let children = item.children
                .filter { $0.totalSize > 0 }  // Filter out empty items
                .sorted { $0.totalSize > $1.totalSize }  // Sort by size (largest first)

            squarify(
                children: children,
                bounds: bounds,
                totalSize: item.totalSize,
                minSize: minSize,
                output: &rectangles
            )
        }

        return rectangles
    }

    // MARK: - Squarified Algorithm

    // swiftlint:disable:next function_body_length
    private static func squarify(
        children: [FileItem],
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
            var row: [FileItem] = []
            var rowSize: Int64 = 0

            // Try to add items to the row while improving aspect ratio
            for item in remaining {
                let newRow = row + [item]
                let newRowSize = rowSize + item.totalSize

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
                for (item, rect) in zip(row, rowRects) {
                    // Always add the item itself as a rectangle (directories and files)
                    output.append(TreemapRectangle(item: item, rect: rect))

                    // Only recurse if item is large enough (size-based threshold)
                    if item.isDirectory && !item.children.isEmpty && item.totalSize >= minSize {
                        // Recursively layout children (will be drawn on top)
                        let children = item.children
                            .filter { $0.totalSize > 0 }
                            .sorted { $0.totalSize > $1.totalSize }

                        squarify(
                            children: children,
                            bounds: rect,
                            totalSize: item.totalSize,
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
        row: [FileItem],
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
        for item in row {
            let itemArea = rowWidth * rowHeight * CGFloat(item.totalSize) / CGFloat(rowSize)
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
        row: [FileItem],
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

        // Snap row bounds to pixels first
        let snappedY = floor(bounds.origin.y)
        let snappedX = floor(bounds.origin.x)
        let snappedRowHeight = ceil(bounds.origin.y + rowHeight) - snappedY
        let snappedRowWidth = ceil(bounds.origin.x + rowWidth) - snappedX

        var currentPixel: CGFloat = 0

        for (index, item) in row.enumerated() {
            let itemFraction = CGFloat(item.totalSize) / CGFloat(rowSize)

            let rect: CGRect
            if isHorizontal {
                // Items go across horizontally
                let nextPixel = (index == row.count - 1)
                    ? snappedRowWidth
                    : floor(currentPixel + snappedRowWidth * itemFraction)

                rect = CGRect(
                    x: snappedX + currentPixel,
                    y: snappedY,
                    width: nextPixel - currentPixel,
                    height: snappedRowHeight
                )
                currentPixel = nextPixel
            } else {
                // Items go down vertically
                let nextPixel = (index == row.count - 1)
                    ? snappedRowHeight
                    : floor(currentPixel + snappedRowHeight * itemFraction)

                rect = CGRect(
                    x: snappedX,
                    y: snappedY + currentPixel,
                    width: snappedRowWidth,
                    height: nextPixel - currentPixel
                )
                currentPixel = nextPixel
            }

            rectangles.append(rect)
        }

        return rectangles
    }
}

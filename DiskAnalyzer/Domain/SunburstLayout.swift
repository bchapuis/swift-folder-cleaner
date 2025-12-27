import Foundation
import CoreGraphics

/// Sunburst layout engine for hierarchical visualization
struct SunburstLayout {
    /// Generates sunburst rings from a file node tree
    /// - Parameters:
    ///   - node: Root node to layout
    ///   - centerRadius: Radius of the center circle
    ///   - maxRadius: Maximum outer radius
    /// - Returns: Array of rings representing each file/folder
    static func layout(
        node: FileNode,
        centerRadius: CGFloat = 60,
        maxRadius: CGFloat
    ) -> [SunburstRing] {
        var rings: [SunburstRing] = []

        guard node.totalSize > 0 else { return rings }

        // Calculate maximum depth to determine ring thickness
        let maxDepth = calculateMaxDepth(node: node)
        let availableRadius = maxRadius - centerRadius
        let ringThickness = maxDepth > 0 ? availableRadius / CGFloat(maxDepth) : availableRadius

        // Create center circle for root
        let rootRing = SunburstRing(
            node: node,
            startAngle: 0,
            endAngle: 2 * .pi,
            innerRadius: 0,
            outerRadius: centerRadius,
            level: 0
        )
        rings.append(rootRing)

        // Layout children recursively
        if !node.children.isEmpty {
            layoutChildren(
                children: node.children,
                parentStartAngle: 0,
                parentEndAngle: 2 * .pi,
                innerRadius: centerRadius,
                ringThickness: ringThickness,
                level: 1,
                output: &rings
            )
        }

        return rings
    }

    // MARK: - Private Methods

    private static func layoutChildren(
        children: [FileNode],
        parentStartAngle: CGFloat,
        parentEndAngle: CGFloat,
        innerRadius: CGFloat,
        ringThickness: CGFloat,
        level: Int,
        output: inout [SunburstRing]
    ) {
        guard !children.isEmpty else { return }

        // Filter out empty items and calculate total size
        let validChildren = children.filter { $0.totalSize > 0 }
        guard !validChildren.isEmpty else { return }

        let totalSize = validChildren.reduce(0) { $0 + $1.totalSize }
        guard totalSize > 0 else { return }

        // Calculate available arc
        let availableArc = parentEndAngle - parentStartAngle
        let outerRadius = innerRadius + ringThickness

        // Layout each child
        var currentAngle = parentStartAngle

        for child in validChildren {
            // Calculate arc size proportional to file size
            let proportion = CGFloat(child.totalSize) / CGFloat(totalSize)
            let arcSize = availableArc * proportion
            let endAngle = currentAngle + arcSize

            // Create ring for this child
            let ring = SunburstRing(
                node: child,
                startAngle: currentAngle,
                endAngle: endAngle,
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                level: level
            )
            output.append(ring)

            // Recursively layout grandchildren
            if child.isDirectory && !child.children.isEmpty {
                layoutChildren(
                    children: child.children,
                    parentStartAngle: currentAngle,
                    parentEndAngle: endAngle,
                    innerRadius: outerRadius,
                    ringThickness: ringThickness,
                    level: level + 1,
                    output: &output
                )
            }

            currentAngle = endAngle
        }
    }

    private static func calculateMaxDepth(node: FileNode, currentDepth: Int = 0) -> Int {
        guard !node.children.isEmpty else {
            return currentDepth
        }

        let childDepths = node.children.map { calculateMaxDepth(node: $0, currentDepth: currentDepth + 1) }
        return childDepths.max() ?? currentDepth
    }
}

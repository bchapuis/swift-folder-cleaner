import Foundation
import CoreGraphics

/// Represents a segment in the sunburst visualization
struct SunburstRing: Identifiable {
    let id: UUID = UUID()
    let node: FileNode

    /// Starting angle in radians (0 = right, π/2 = top, π = left, 3π/2 = bottom)
    let startAngle: CGFloat

    /// Ending angle in radians
    let endAngle: CGFloat

    /// Inner radius (distance from center)
    let innerRadius: CGFloat

    /// Outer radius
    let outerRadius: CGFloat

    /// Depth level in the hierarchy (0 = root)
    let level: Int

    /// The color for this ring based on file type
    var color: Color {
        node.fileType.color
    }

    /// Whether this ring is large enough to show a label
    var canShowLabel: Bool {
        let arcLength = (endAngle - startAngle) * outerRadius
        let ringHeight = outerRadius - innerRadius
        return arcLength > 40 && ringHeight > 20
    }

    /// Mid-point angle for label positioning
    var midAngle: CGFloat {
        (startAngle + endAngle) / 2
    }

    /// Mid-point radius for label positioning
    var midRadius: CGFloat {
        (innerRadius + outerRadius) / 2
    }
}

extension SunburstRing: Equatable {
    static func == (lhs: SunburstRing, rhs: SunburstRing) -> Bool {
        lhs.node.path == rhs.node.path &&
        lhs.startAngle == rhs.startAngle &&
        lhs.endAngle == rhs.endAngle &&
        lhs.innerRadius == rhs.innerRadius &&
        lhs.outerRadius == rhs.outerRadius
    }
}

extension SunburstRing: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(node.path)
        hasher.combine(startAngle)
        hasher.combine(endAngle)
        hasher.combine(innerRadius)
        hasher.combine(outerRadius)
    }
}

import SwiftUI

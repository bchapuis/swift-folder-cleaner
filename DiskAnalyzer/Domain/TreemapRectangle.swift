import Foundation
import SwiftUI

/// Represents a rectangle in the treemap layout
struct TreemapRectangle: Identifiable {
    let id: UUID = UUID()
    let node: FileNode
    let rect: CGRect

    /// The color for this rectangle based on file type
    var color: Color {
        node.fileType.color
    }

    /// Whether this rectangle is large enough to show a label
    var canShowLabel: Bool {
        rect.width > 80 && rect.height > 40
    }

    /// Whether this rectangle is large enough to show size
    var canShowSize: Bool {
        rect.width > 120 && rect.height > 60
    }

    /// Optimal font size for this rectangle
    var labelFontSize: CGFloat {
        let area = rect.width * rect.height
        if area > 20000 {
            return 13
        } else if area > 10000 {
            return 11
        } else {
            return 10
        }
    }
}

extension TreemapRectangle: Equatable {
    static func == (lhs: TreemapRectangle, rhs: TreemapRectangle) -> Bool {
        lhs.node.path == rhs.node.path && lhs.rect == rhs.rect
    }
}

extension TreemapRectangle: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(node.path)
        hasher.combine(rect.origin.x)
        hasher.combine(rect.origin.y)
        hasher.combine(rect.size.width)
        hasher.combine(rect.size.height)
    }
}

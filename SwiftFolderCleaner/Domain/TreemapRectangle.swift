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

    /// Whether this rectangle is large enough to show a label (progressive disclosure)
    var canShowLabel: Bool {
        let area = rect.width * rect.height
        return area > 3200 && rect.width > 60 && rect.height > 30
    }

    /// Whether this rectangle is large enough to show size (progressive disclosure)
    var canShowSize: Bool {
        let area = rect.width * rect.height
        return area > 9000 && rect.width > 100 && rect.height > 50
    }

    /// Optimal font size for this rectangle (progressive scaling)
    var labelFontSize: CGFloat {
        let area = rect.width * rect.height
        if area > 40000 {
            return 14
        } else if area > 20000 {
            return 13
        } else if area > 10000 {
            return 11
        } else if area > 5000 {
            return 10
        } else {
            return 9
        }
    }

    /// Label opacity based on rectangle size (fade for smaller items)
    var labelOpacity: Double {
        let area = rect.width * rect.height
        if area > 10000 {
            return 1.0
        } else if area > 5000 {
            return 0.95
        } else if area > 3200 {
            return 0.85
        } else {
            return 0.0
        }
    }

    /// No corner radius to avoid gaps between rectangles
    var cornerRadius: CGFloat {
        return 0
    }
}

extension TreemapRectangle: Equatable {
    static func == (lhs: TreemapRectangle, rhs: TreemapRectangle) -> Bool {
        lhs.node.path.standardized == rhs.node.path.standardized && lhs.rect == rhs.rect
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

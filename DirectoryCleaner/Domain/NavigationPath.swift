import Foundation

/// Type-safe navigation path that maintains hierarchy invariants
/// Ensures that all path segments form a valid parent-child relationship
struct NavigationPath: Equatable {
    // MARK: - Properties

    /// Path segments from root to current location
    private(set) var segments: [URL]

    /// The root URL (first segment, always present)
    var root: URL {
        segments[0]
    }

    /// Current location (last segment)
    var current: URL {
        segments[segments.count - 1]
    }

    /// Number of levels from root
    var depth: Int {
        segments.count - 1
    }

    /// Whether we're at the root (can't navigate up)
    var isAtRoot: Bool {
        segments.count == 1
    }

    // MARK: - Initialization

    /// Create a navigation path starting at the given root
    init(root: URL) {
        self.segments = [root]
    }

    /// Internal initializer with validated segments
    private init(segments: [URL]) {
        precondition(!segments.isEmpty, "NavigationPath must have at least one segment")
        self.segments = segments
    }

    // MARK: - Navigation

    /// Navigate down into a child directory
    /// - Parameter child: The child URL to navigate to
    /// - Returns: true if navigation succeeded, false if child is not under current path
    @discardableResult
    mutating func drillDown(to child: URL) -> Bool {
        // Validate that child is actually under current path
        let currentPath = current.path
        let childPath = child.path

        // Child must start with current path + "/"
        guard childPath.hasPrefix(currentPath),
              childPath.count > currentPath.count else {
            return false
        }

        // Ensure there's a path separator (avoid false positives like /foo matching /foobar)
        let afterCurrent = childPath.dropFirst(currentPath.count)
        guard afterCurrent.first == "/" || currentPath == "/" else {
            return false
        }

        segments.append(child)
        return true
    }

    /// Navigate up one level
    /// - Returns: true if navigation succeeded, false if already at root
    @discardableResult
    mutating func navigateUp() -> Bool {
        guard segments.count > 1 else { return false }
        segments.removeLast()
        return true
    }

    /// Navigate to a specific depth (0 = root)
    /// - Parameter depth: The depth to navigate to
    /// - Returns: true if navigation succeeded, false if depth is invalid
    @discardableResult
    mutating func navigateTo(depth: Int) -> Bool {
        guard depth >= 0, depth < segments.count else { return false }
        segments = Array(segments.prefix(depth + 1))
        return true
    }

    /// Reset to root
    mutating func resetToRoot() {
        segments = [segments[0]]
    }

    // MARK: - Query

    /// Get segment at specific depth (0 = root)
    func segment(at depth: Int) -> URL? {
        guard depth >= 0, depth < segments.count else { return nil }
        return segments[depth]
    }

    /// Get all segments as array
    func allSegments() -> [URL] {
        segments
    }

    /// Check if this path is under another path
    func isUnder(_ other: NavigationPath) -> Bool {
        guard segments.count > other.segments.count else { return false }
        return segments.prefix(other.segments.count).elementsEqual(other.segments)
    }

    /// Get the parent path (one level up), or nil if at root
    func parent() -> NavigationPath? {
        guard segments.count > 1 else { return nil }
        return NavigationPath(segments: Array(segments.dropLast()))
    }

    // MARK: - Equatable

    static func == (lhs: NavigationPath, rhs: NavigationPath) -> Bool {
        lhs.segments == rhs.segments
    }
}

// MARK: - CustomStringConvertible

extension NavigationPath: CustomStringConvertible {
    var description: String {
        segments.map(\.path).joined(separator: " > ")
    }
}

// MARK: - Collection-like Operations

extension NavigationPath {
    /// Number of segments
    var count: Int {
        segments.count
    }

    /// Get segment at index using subscript
    subscript(index: Int) -> URL {
        segments[index]
    }
}

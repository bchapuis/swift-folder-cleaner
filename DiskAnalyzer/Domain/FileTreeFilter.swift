import Foundation

// MARK: - Filter Protocol

/// Protocol for filtering FileNode trees
protocol FileTreeFilter: Sendable {
    /// Check if a node matches this filter
    func matches(_ node: FileNode) -> Bool
}

// MARK: - Basic Filters

/// Filter by file type
struct FileTypeFilter: FileTreeFilter {
    let types: Set<FileType>

    init(_ types: Set<FileType>) {
        self.types = types
    }

    init(_ type: FileType) {
        self.types = [type]
    }

    func matches(_ node: FileNode) -> Bool {
        types.contains(node.fileType)
    }
}

/// Filter by size range
struct SizeFilter: FileTreeFilter {
    let min: Int64?
    let max: Int64?

    init(min: Int64? = nil, max: Int64? = nil) {
        self.min = min
        self.max = max
    }

    func matches(_ node: FileNode) -> Bool {
        if let min, node.totalSize < min {
            return false
        }
        if let max, node.totalSize > max {
            return false
        }
        return true
    }

    /// Filter for files larger than size
    static func largerThan(_ size: Int64) -> SizeFilter {
        SizeFilter(min: size)
    }

    /// Filter for files smaller than size
    static func smallerThan(_ size: Int64) -> SizeFilter {
        SizeFilter(max: size)
    }

    /// Common size thresholds
    static let large100MB = SizeFilter(min: 100 * 1024 * 1024)
    static let large1GB = SizeFilter(min: 1024 * 1024 * 1024)
    static let large10GB = SizeFilter(min: 10 * 1024 * 1024 * 1024)
}

/// Filter by modification date
struct DateFilter: FileTreeFilter {
    let after: Date?
    let before: Date?

    init(after: Date? = nil, before: Date? = nil) {
        self.after = after
        self.before = before
    }

    func matches(_ node: FileNode) -> Bool {
        if let after, node.modifiedDate < after {
            return false
        }
        if let before, node.modifiedDate > before {
            return false
        }
        return true
    }

    /// Filter for files modified after date
    static func modifiedAfter(_ date: Date) -> DateFilter {
        DateFilter(after: date)
    }

    /// Filter for files modified before date
    static func modifiedBefore(_ date: Date) -> DateFilter {
        DateFilter(before: date)
    }

    /// Common date ranges
    static var lastWeek: DateFilter {
        DateFilter(after: Calendar.current.date(byAdding: .day, value: -7, to: Date()))
    }

    static var lastMonth: DateFilter {
        DateFilter(after: Calendar.current.date(byAdding: .month, value: -1, to: Date()))
    }

    static var lastYear: DateFilter {
        DateFilter(after: Calendar.current.date(byAdding: .year, value: -1, to: Date()))
    }
}

/// Filter by name pattern
struct NameFilter: FileTreeFilter {
    enum Pattern {
        case contains(String, caseSensitive: Bool)
        case prefix(String, caseSensitive: Bool)
        case suffix(String, caseSensitive: Bool)
        case regex(String)
    }

    let pattern: Pattern

    init(pattern: Pattern) {
        self.pattern = pattern
    }

    func matches(_ node: FileNode) -> Bool {
        switch pattern {
        case .contains(let text, let caseSensitive):
            if caseSensitive {
                return node.name.contains(text)
            } else {
                return node.name.localizedCaseInsensitiveContains(text)
            }

        case .prefix(let text, let caseSensitive):
            if caseSensitive {
                return node.name.hasPrefix(text)
            } else {
                return node.name.lowercased().hasPrefix(text.lowercased())
            }

        case .suffix(let text, let caseSensitive):
            if caseSensitive {
                return node.name.hasSuffix(text)
            } else {
                return node.name.lowercased().hasSuffix(text.lowercased())
            }

        case .regex(let pattern):
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return false
            }
            let range = NSRange(node.name.startIndex..., in: node.name)
            return regex.firstMatch(in: node.name, range: range) != nil
        }
    }

    /// Convenience: contains text (case insensitive)
    static func contains(_ text: String) -> NameFilter {
        NameFilter(pattern: .contains(text, caseSensitive: false))
    }

    /// Convenience: starts with text (case insensitive)
    static func startsWith(_ text: String) -> NameFilter {
        NameFilter(pattern: .prefix(text, caseSensitive: false))
    }

    /// Convenience: ends with text (case insensitive)
    static func endsWith(_ text: String) -> NameFilter {
        NameFilter(pattern: .suffix(text, caseSensitive: false))
    }
}

/// Filter by file extension
struct ExtensionFilter: FileTreeFilter {
    let extensions: Set<String>

    init(_ extensions: Set<String>) {
        // Normalize to lowercase
        self.extensions = Set(extensions.map { $0.lowercased() })
    }

    init(_ ext: String) {
        self.extensions = Set([ext.lowercased()])
    }

    func matches(_ node: FileNode) -> Bool {
        guard !node.isDirectory else { return false }
        let ext = node.path.pathExtension.lowercased()
        return extensions.contains(ext)
    }

    /// Common extension groups
    static let images = ExtensionFilter(Set(["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic"]))
    static let videos = ExtensionFilter(Set(["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"]))
    static let audio = ExtensionFilter(Set(["mp3", "wav", "aac", "flac", "m4a", "ogg", "wma"]))
    static let documents = ExtensionFilter(Set(["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt"]))
    static let code = ExtensionFilter(Set(["swift", "m", "h", "c", "cpp", "java", "py", "js", "ts", "go", "rs"]))
}

/// Filter by path pattern
struct PathFilter: FileTreeFilter {
    let pattern: String
    let regex: NSRegularExpression?

    init(pattern: String) {
        self.pattern = pattern
        self.regex = try? NSRegularExpression(pattern: pattern)
    }

    func matches(_ node: FileNode) -> Bool {
        guard let regex else { return false }
        let pathString = node.path.path
        let range = NSRange(pathString.startIndex..., in: pathString)
        return regex.firstMatch(in: pathString, range: range) != nil
    }
}

// MARK: - Compound Filters

/// AND filter - all filters must match
struct AndFilter: FileTreeFilter {
    let filters: [FileTreeFilter]

    init(_ filters: [FileTreeFilter]) {
        self.filters = filters
    }

    init(_ filters: FileTreeFilter...) {
        self.filters = filters
    }

    func matches(_ node: FileNode) -> Bool {
        filters.allSatisfy { $0.matches(node) }
    }
}

/// OR filter - any filter must match
struct OrFilter: FileTreeFilter {
    let filters: [FileTreeFilter]

    init(_ filters: [FileTreeFilter]) {
        self.filters = filters
    }

    init(_ filters: FileTreeFilter...) {
        self.filters = filters
    }

    func matches(_ node: FileNode) -> Bool {
        filters.contains(where: { $0.matches(node) })
    }
}

/// NOT filter - inverse of filter
struct NotFilter: FileTreeFilter {
    let filter: FileTreeFilter

    init(_ filter: FileTreeFilter) {
        self.filter = filter
    }

    func matches(_ node: FileNode) -> Bool {
        !filter.matches(node)
    }
}

// MARK: - FileNode Filtering Extensions

extension FileNode {
    /// Filter tree using a FileTreeFilter
    func filtered(by filter: FileTreeFilter) -> FileNode? {
        // For files: include only if filter matches
        if !isDirectory {
            return filter.matches(self) ? self : nil
        }

        // For directories: recursively filter children
        let filteredChildren = children.compactMap { child in
            child.filtered(by: filter)
        }

        // Include directory if it has matching children or matches itself
        if !filteredChildren.isEmpty || filter.matches(self) {
            let filteredTotalSize = filteredChildren.reduce(0) { $0 + $1.totalSize }
            let filteredFileCount = 1 + filteredChildren.reduce(0) { $0 + $1.fileCount }
            let filteredMaxDepth = filteredChildren.isEmpty ? 0 : (filteredChildren.map(\.maxDepth).max() ?? 0) + 1

            return FileNode(
                path: path,
                name: name,
                size: size,
                fileType: fileType,
                modifiedDate: modifiedDate,
                children: filteredChildren,
                isDirectory: isDirectory,
                totalSize: filteredTotalSize,
                fileCount: filteredFileCount,
                maxDepth: filteredMaxDepth
            )
        }

        return nil
    }

    /// Filter tree using multiple filters (AND logic)
    func filtered(by filters: [FileTreeFilter]) -> FileNode? {
        filtered(by: AndFilter(filters))
    }
}

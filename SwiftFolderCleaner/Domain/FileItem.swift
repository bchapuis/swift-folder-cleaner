import Foundation
import SwiftData

/// SwiftData model representing a file or directory in the file tree
@Model
final class FileItem {
    // MARK: - Stored Properties

    /// File path as string (SwiftData doesn't support URL directly)
    var pathString: String
    var name: String
    var size: Int64
    var fileTypeRawValue: String
    var modifiedDate: Date
    var isDirectory: Bool

    /// Cached computed values for performance
    var totalSize: Int64
    var fileCount: Int
    var maxDepth: Int

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \FileItem.parent)
    var children: [FileItem]

    var parent: FileItem?

    // MARK: - Computed Properties

    /// URL representation of path
    var path: URL {
        URL(fileURLWithPath: pathString)
    }

    /// File type enum
    var fileType: FileType {
        get { FileType(rawValue: fileTypeRawValue) ?? .other }
        set { fileTypeRawValue = newValue.rawValue }
    }

    /// Human-readable size string
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    // MARK: - Initialization

    init(
        path: URL,
        name: String,
        size: Int64,
        fileType: FileType,
        modifiedDate: Date,
        isDirectory: Bool,
        totalSize: Int64,
        fileCount: Int,
        maxDepth: Int
    ) {
        self.pathString = path.path
        self.name = name
        self.size = size
        self.fileTypeRawValue = fileType.rawValue
        self.modifiedDate = modifiedDate
        self.isDirectory = isDirectory
        self.totalSize = totalSize
        self.fileCount = fileCount
        self.maxDepth = maxDepth
        self.children = []
        self.parent = nil
    }

    // MARK: - Factory Methods

    /// Creates a file item for a directory
    static func directory(
        path: URL,
        name: String,
        modifiedDate: Date,
        children: [FileItem] = []
    ) -> FileItem {
        let totalSize = children.reduce(0) { $0 + $1.totalSize }
        let fileCount = 1 + children.reduce(0) { $0 + $1.fileCount }
        let maxDepth = children.isEmpty ? 0 : (children.map(\.maxDepth).max() ?? 0) + 1

        let item = FileItem(
            path: path,
            name: name,
            size: 0,
            fileType: .directory,
            modifiedDate: modifiedDate,
            isDirectory: true,
            totalSize: totalSize,
            fileCount: fileCount,
            maxDepth: maxDepth
        )

        item.children = children
        for child in children {
            child.parent = item
        }

        return item
    }

    /// Creates a file item for a regular file
    static func file(
        path: URL,
        name: String,
        size: Int64,
        fileType: FileType,
        modifiedDate: Date
    ) -> FileItem {
        FileItem(
            path: path,
            name: name,
            size: size,
            fileType: fileType,
            modifiedDate: modifiedDate,
            isDirectory: false,
            totalSize: size,
            fileCount: 1,
            maxDepth: 0
        )
    }
}

// MARK: - Identifiable

extension FileItem: Identifiable {
    var id: String { pathString }
}

// MARK: - Filtering

extension FileItem {
    /// Creates a filtered copy of this item tree containing only items of specified types
    /// - Parameter selectedTypes: Set of file types to include
    /// - Returns: Filtered item, or nil if no matching items found
    func filtered(by selectedTypes: Set<FileType>) -> FileItem? {
        // For files: include only if type is selected
        if !isDirectory {
            return selectedTypes.contains(fileType) ? self : nil
        }

        // For directories: recursively filter children
        let filteredChildren = children.compactMap { child in
            child.filtered(by: selectedTypes)
        }

        // Include directory only if it has matching children or is explicitly selected
        if !filteredChildren.isEmpty {
            let item = FileItem.directory(
                path: path,
                name: name,
                modifiedDate: modifiedDate,
                children: filteredChildren
            )
            return item
        } else if selectedTypes.contains(.directory) && children.isEmpty {
            return self
        }

        return nil
    }
}

// MARK: - Query

extension FileItem {
    /// Find all items matching a predicate
    func find(where predicate: (FileItem) -> Bool) -> [FileItem] {
        var results: [FileItem] = []

        if predicate(self) {
            results.append(self)
        }

        for child in children {
            results.append(contentsOf: child.find(where: predicate))
        }

        return results
    }

    /// Find first item matching a predicate (depth-first search)
    func findFirst(where predicate: (FileItem) -> Bool) -> FileItem? {
        if predicate(self) {
            return self
        }

        for child in children {
            if let found = child.findFirst(where: predicate) {
                return found
            }
        }

        return nil
    }

    /// Find an item by exact path
    func findItem(at path: URL) -> FileItem? {
        let standardizedPath = path.standardized
        return findFirst(where: { $0.path.standardized == standardizedPath })
    }
}

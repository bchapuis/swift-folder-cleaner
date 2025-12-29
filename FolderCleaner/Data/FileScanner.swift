import Foundation

/// Synchronous file scanner for recursive directory traversal
final class FileScanner {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Scans a directory recursively and builds a file tree
    /// - Parameter url: The root directory to scan
    /// - Returns: A FileNode representing the scanned directory tree
    /// - Throws: ScanError if the scan fails
    func scan(url: URL) throws -> FileNode {
        // Validate the path exists
        guard fileManager.fileExists(atPath: url.path) else {
            throw ScanError.pathNotFound(path: url.path)
        }

        // Check if it's a directory
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        guard isDirectory.boolValue else {
            throw ScanError.notADirectory(path: url.path)
        }

        // Start scanning from the root
        return try scanDirectory(at: url)
    }

    /// Recursively scans a directory and its contents
    private func scanDirectory(at url: URL) throws -> FileNode {
        // Get directory attributes
        let attributes = try getAttributes(for: url)
        let modifiedDate = attributes.modifiedDate

        // Get directory contents
        let contents = try getDirectoryContents(at: url)

        // Scan each child item
        var children: [FileNode] = []
        for childURL in contents {
            do {
                let childNode = try scanItem(at: childURL)
                children.append(childNode)
            } catch {
                // Skip items we can't access (permission denied, etc.)
                // In a production app, we might want to collect these errors
                continue
            }
        }

        // Sort children by size (largest first)
        children.sort { $0.totalSize > $1.totalSize }

        return FileNode.directory(
            path: url,
            name: url.lastPathComponent,
            modifiedDate: modifiedDate,
            children: children
        )
    }

    /// Scans a single file or directory
    private func scanItem(at url: URL) throws -> FileNode {
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            return try scanDirectory(at: url)
        } else {
            return try scanFile(at: url)
        }
    }

    /// Scans a single file
    private func scanFile(at url: URL) throws -> FileNode {
        let attributes = try getAttributes(for: url)

        return FileNode.file(
            path: url,
            name: url.lastPathComponent,
            size: attributes.size,
            fileType: FileTypeDetector.detectType(for: url),
            modifiedDate: attributes.modifiedDate
        )
    }

    /// Gets file attributes for a URL
    private func getAttributes(for url: URL) throws -> FileAttributes {
        do {
            let attrs = try fileManager.attributesOfItem(atPath: url.path)

            let size = attrs[.size] as? Int64 ?? 0
            let modifiedDate = attrs[.modificationDate] as? Date ?? Date()

            return FileAttributes(size: size, modifiedDate: modifiedDate)
        } catch {
            // Check if it's a permission error
            if (error as NSError).code == NSFileReadNoPermissionError {
                throw ScanError.permissionDenied(path: url.path)
            }
            throw ScanError.unknown(underlying: error.localizedDescription)
        }
    }

    /// Gets the contents of a directory
    private func getDirectoryContents(at url: URL) throws -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]  // Skip hidden files by default
            )
        } catch {
            // Check if it's a permission error
            if (error as NSError).code == NSFileReadNoPermissionError {
                throw ScanError.permissionDenied(path: url.path)
            }
            throw ScanError.unknown(underlying: error.localizedDescription)
        }
    }
}

/// Helper struct to hold file attributes
private struct FileAttributes {
    let size: Int64
    let modifiedDate: Date
}

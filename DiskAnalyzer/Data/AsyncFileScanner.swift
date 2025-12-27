import Foundation

/// Async file scanner with progress tracking and cancellation support
actor AsyncFileScanner {
    private let fileManager: FileManager
    private var currentProgress: ScanProgress
    private let startTime: Date

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.startTime = Date()
        self.currentProgress = .initial()
    }

    /// Scans a directory asynchronously with AsyncStream progress updates
    /// - Parameter url: The root directory to scan
    /// - Returns: An AsyncStream of progress updates and the final result
    func scanWithStream(url: URL) -> (stream: AsyncStream<ScanProgress>, result: Task<ScanResult, Error>) {
        let (stream, continuation) = AsyncStream.makeStream(of: ScanProgress.self)

        let task = Task<ScanResult, Error> {
            defer { continuation.finish() }

            let result = try await scan(url: url) { progress in
                continuation.yield(progress)
            }

            return result
        }

        return (stream, task)
    }

    /// Scans a directory asynchronously with progress updates
    /// - Parameters:
    ///   - url: The root directory to scan
    ///   - progressHandler: Optional closure called with progress updates
    /// - Returns: A ScanResult containing the scanned tree
    /// - Throws: ScanError if the scan fails or is cancelled
    func scan(
        url: URL,
        progressHandler: ((ScanProgress) -> Void)? = nil
    ) async throws -> ScanResult {
        // Reset progress
        currentProgress = ScanProgress(
            filesScanned: 0,
            currentPath: url.path,
            totalBytes: 0,
            startTime: startTime
        )

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

        // Scan the directory tree
        let rootNode = try await scanDirectory(at: url, progressHandler: progressHandler)

        // Create scan result
        return ScanResult.from(rootNode: rootNode, startTime: startTime)
    }

    /// Recursively scans a directory and its contents
    private func scanDirectory(
        at url: URL,
        progressHandler: ((ScanProgress) -> Void)?
    ) async throws -> FileNode {
        // Check for cancellation
        try Task.checkCancellation()

        // Get directory attributes
        let attributes = try await getAttributes(for: url)
        let modifiedDate = attributes.modifiedDate

        // Update progress
        updateProgress(path: url.path, size: 0)
        progressHandler?(currentProgress)

        // Get directory contents
        let contents = try await getDirectoryContents(at: url)

        // Scan each child item concurrently (but with limited concurrency)
        var children: [FileNode] = []
        for childURL in contents {
            do {
                let childNode = try await scanItem(at: childURL, progressHandler: progressHandler)
                children.append(childNode)
            } catch is CancellationError {
                throw ScanError.cancelled
            } catch {
                // Skip items we can't access
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
    private func scanItem(
        at url: URL,
        progressHandler: ((ScanProgress) -> Void)?
    ) async throws -> FileNode {
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            return try await scanDirectory(at: url, progressHandler: progressHandler)
        } else {
            return try await scanFile(at: url, progressHandler: progressHandler)
        }
    }

    /// Scans a single file
    private func scanFile(
        at url: URL,
        progressHandler: ((ScanProgress) -> Void)?
    ) async throws -> FileNode {
        // Check for cancellation
        try Task.checkCancellation()

        let attributes = try await getAttributes(for: url)

        // Update progress
        updateProgress(path: url.path, size: attributes.size)
        progressHandler?(currentProgress)

        return FileNode.file(
            path: url,
            name: url.lastPathComponent,
            size: attributes.size,
            fileType: FileTypeDetector.detectType(for: url),
            modifiedDate: attributes.modifiedDate
        )
    }

    /// Gets file attributes for a URL (async wrapper)
    private func getAttributes(for url: URL) async throws -> FileAttributes {
        try await Task {
            do {
                let attrs = try fileManager.attributesOfItem(atPath: url.path)

                let size = attrs[.size] as? Int64 ?? 0
                let modifiedDate = attrs[.modificationDate] as? Date ?? Date()

                return FileAttributes(size: size, modifiedDate: modifiedDate)
            } catch {
                if (error as NSError).code == NSFileReadNoPermissionError {
                    throw ScanError.permissionDenied(path: url.path)
                }
                throw ScanError.unknown(underlying: error.localizedDescription)
            }
        }.value
    }

    /// Gets the contents of a directory (async wrapper)
    private func getDirectoryContents(at url: URL) async throws -> [URL] {
        try await Task {
            do {
                return try fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                if (error as NSError).code == NSFileReadNoPermissionError {
                    throw ScanError.permissionDenied(path: url.path)
                }
                throw ScanError.unknown(underlying: error.localizedDescription)
            }
        }.value
    }

    /// Updates the current progress (actor-isolated)
    private func updateProgress(path: String, size: Int64) {
        currentProgress = currentProgress.update(path: path, fileSize: size)
    }

    /// Gets the current progress (actor-isolated)
    func getProgress() -> ScanProgress {
        currentProgress
    }
}

/// Helper struct to hold file attributes
private struct FileAttributes {
    let size: Int64
    let modifiedDate: Date
}

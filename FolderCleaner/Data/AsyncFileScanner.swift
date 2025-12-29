import Foundation

/// Async file scanner with progress tracking and cancellation support
actor AsyncFileScanner {
    private let fileManager: FileManager
    private var currentProgress: ScanProgress
    private let startTime: Date
    private var lastProgressUpdate: Date = .distantPast
    private let progressUpdateInterval: TimeInterval = 0.2 // 200ms throttle

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

        // Update progress (throttled)
        updateProgressThrottled(path: url.path, size: 0, handler: progressHandler)

        // Get directory contents
        let contents = try await getDirectoryContents(at: url)

        // Scan children concurrently using TaskGroup (all cores)
        let children = try await withThrowingTaskGroup(of: FileNode?.self) { group in
            // Add tasks for each child
            for childURL in contents {
                group.addTask {
                    do {
                        return try await self.scanItem(at: childURL, progressHandler: progressHandler)
                    } catch is CancellationError {
                        throw ScanError.cancelled
                    } catch {
                        // Skip items we can't access
                        return nil
                    }
                }
            }

            // Collect results
            var results: [FileNode] = []
            for try await child in group {
                if let child {
                    results.append(child)
                }
            }

            // Sort children by size (largest first)
            results.sort { $0.totalSize > $1.totalSize }
            return results
        }

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

        // Update progress (throttled)
        updateProgressThrottled(path: url.path, size: attributes.size, handler: progressHandler)

        return FileNode.file(
            path: url,
            name: url.lastPathComponent,
            size: attributes.size,
            fileType: FileTypeDetector.detectType(for: url),
            modifiedDate: attributes.modifiedDate
        )
    }

    /// Gets file attributes for a URL (nonisolated for true parallelism)
    nonisolated private func getAttributes(for url: URL) async throws -> FileAttributes {
        try await Task {
            do {
                // Try cached resource values first (much faster)
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])

                let size = Int64(resourceValues.fileSize ?? 0)
                let modifiedDate = resourceValues.contentModificationDate ?? Date()

                return FileAttributes(size: size, modifiedDate: modifiedDate)
            } catch {
                if (error as NSError).code == NSFileReadNoPermissionError {
                    throw ScanError.permissionDenied(path: url.path)
                }
                throw ScanError.unknown(underlying: error.localizedDescription)
            }
        }.value
    }

    /// Gets the contents of a directory (nonisolated for true parallelism)
    nonisolated private func getDirectoryContents(at url: URL) async throws -> [URL] {
        try await Task {
            do {
                return try FileManager.default.contentsOfDirectory(
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

    /// Updates progress with throttling to avoid UI flooding
    private func updateProgressThrottled(
        path: String,
        size: Int64,
        handler: ((ScanProgress) -> Void)?
    ) {
        // Always update internal state
        updateProgress(path: path, size: size)

        // Only notify handler if enough time has passed
        let now = Date()
        if now.timeIntervalSince(lastProgressUpdate) >= progressUpdateInterval {
            handler?(currentProgress)
            lastProgressUpdate = now
        }
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

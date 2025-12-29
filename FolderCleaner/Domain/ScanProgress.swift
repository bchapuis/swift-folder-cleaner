import Foundation

/// Progress information during file scanning
struct ScanProgress: Sendable {
    let filesScanned: Int
    let currentPath: String
    let totalBytes: Int64
    let startTime: Date

    /// Progress percentage (0.0 to 1.0)
    /// Note: For unknown total size, this returns -1.0 to indicate indeterminate progress
    var percentage: Double {
        -1.0  // Indeterminate progress for file system scanning
    }

    /// Estimated time remaining (nil if cannot be estimated)
    /// For file system scanning, we can't estimate completion time
    /// as we don't know total file count ahead of time
    var estimatedTimeRemaining: TimeInterval? {
        nil
    }

    /// Scanning speed in files per second
    var filesPerSecond: Double {
        let elapsed = Date().timeIntervalSince(startTime)
        guard elapsed > 0 else { return 0 }
        return Double(filesScanned) / elapsed
    }

    /// Human-readable speed string (e.g., "150 files/s")
    var formattedSpeed: String {
        String(format: "%.0f files/s", filesPerSecond)
    }

    /// Human-readable bytes scanned (e.g., "1.5 GB")
    var formattedBytesScanned: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
}

extension ScanProgress {
    /// Creates initial progress state
    static func initial() -> ScanProgress {
        ScanProgress(
            filesScanned: 0,
            currentPath: "",
            totalBytes: 0,
            startTime: Date()
        )
    }

    /// Updates progress with new file information
    func update(path: String, fileSize: Int64) -> ScanProgress {
        ScanProgress(
            filesScanned: filesScanned + 1,
            currentPath: path,
            totalBytes: totalBytes + fileSize,
            startTime: startTime
        )
    }
}

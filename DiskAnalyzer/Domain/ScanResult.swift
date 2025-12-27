import Foundation

/// Result of a completed file scan
struct ScanResult: Sendable {
    let rootNode: FileNode
    let scanDuration: TimeInterval
    let totalFilesScanned: Int
    let errors: [ScanError]

    /// Total size of all scanned files
    var totalSize: Int64 {
        rootNode.totalSize
    }

    /// Human-readable scan duration
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: scanDuration) ?? "\(scanDuration)s"
    }

    /// Average scanning speed in files per second
    var averageSpeed: Double {
        guard scanDuration > 0 else { return 0 }
        return Double(totalFilesScanned) / scanDuration
    }

    /// Whether the scan completed without errors
    var hasErrors: Bool {
        !errors.isEmpty
    }

    /// Summary statistics
    var summary: String {
        """
        Scanned \(totalFilesScanned) files (\(rootNode.formattedSize)) in \(formattedDuration)
        """
    }
}

extension ScanResult {
    /// Creates a result from a root node
    static func from(
        rootNode: FileNode,
        startTime: Date,
        errors: [ScanError] = []
    ) -> ScanResult {
        ScanResult(
            rootNode: rootNode,
            scanDuration: Date().timeIntervalSince(startTime),
            totalFilesScanned: rootNode.fileCount,
            errors: errors
        )
    }
}

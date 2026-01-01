import Foundation

/// Represents the current state of a file scan operation
enum ScanState {
    case idle
    case scanning(progress: ScanProgress)
    case complete(rootItem: FileItem)
    case failed(error: ScanError)

    /// Whether the scan is currently in progress
    var isScanning: Bool {
        if case .scanning = self {
            return true
        }
        return false
    }

    /// Whether the scan has completed successfully
    var isComplete: Bool {
        if case .complete = self {
            return true
        }
        return false
    }

    /// Whether the scan has failed
    var hasFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    /// The current progress, if scanning
    var progress: ScanProgress? {
        if case .scanning(let progress) = self {
            return progress
        }
        return nil
    }

    /// The root item, if complete
    var rootItem: FileItem? {
        if case .complete(let rootItem) = self {
            return rootItem
        }
        return nil
    }

    /// The error, if failed
    var error: ScanError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

extension ScanState: Equatable {
    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.scanning(p1), .scanning(p2)):
            return p1.filesScanned == p2.filesScanned && p1.totalBytes == p2.totalBytes
        case let (.complete(r1), .complete(r2)):
            return r1.path.standardized == r2.path.standardized
        case let (.failed(e1), .failed(e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

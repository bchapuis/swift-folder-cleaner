import Foundation
import SwiftUI

/// ViewModel for managing file scan operations
@MainActor
@Observable
final class ScanViewModel {
    private(set) var state: ScanState = .idle
    private var currentTask: Task<Void, Never>?
    private let scanner: AsyncFileScanner

    init(scanner: AsyncFileScanner = AsyncFileScanner()) {
        self.scanner = scanner
    }

    /// Starts scanning a directory
    /// - Parameter url: The directory to scan
    func startScan(url: URL) {
        // Cancel any existing scan
        cancelScan()

        // Reset state
        state = .scanning(progress: .initial())

        // Start new scan task
        currentTask = Task {
            do {
                let result = try await scanner.scan(url: url) { [weak self] progress in
                    Task { @MainActor in
                        guard let self else { return }
                        // Only update if still scanning
                        if self.state.isScanning {
                            self.state = .scanning(progress: progress)
                        }
                    }
                }

                // Update state with result
                state = .complete(result: result)

            } catch is CancellationError {
                // Scan was cancelled - return to idle
                state = .idle
            } catch let error as ScanError {
                state = .failed(error: error)
            } catch {
                state = .failed(error: .unknown(underlying: error.localizedDescription))
            }

            currentTask = nil
        }
    }

    /// Cancels the current scan operation
    func cancelScan() {
        currentTask?.cancel()
        currentTask = nil

        if state.isScanning {
            state = .idle
        }
    }

    /// Resets the state to idle
    func reset() {
        cancelScan()
        state = .idle
    }

    // Note: deinit cannot be @MainActor isolated, so we don't cancel here
    // The task will be automatically cleaned up when the instance is deallocated
}

import Foundation
import SwiftUI
import SwiftData

/// ViewModel for managing file scan operations
@MainActor
@Observable
final class ScanViewModel {
    private(set) var state: ScanState = .idle
    private var currentTask: Task<Void, Never>?
    private var modelContext: ModelContext?

    init() {
        // Model context will be injected from environment
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    /// Starts scanning a directory
    /// - Parameter url: The directory to scan
    func startScan(url: URL) {
        guard let modelContext = modelContext else {
            state = .failed(error: .unknown(underlying: "Model context not available"))
            return
        }

        // Cancel any existing scan
        cancelScan()

        // Reset state
        state = .scanning(progress: .initial())

        // Start new scan task
        currentTask = Task {
            do {
                // Create scanner with model context
                let scanner = await AsyncFileScanner(modelContext: modelContext)

                let rootItem = try await scanner.scan(url: url) { [weak self] progress in
                    Task { @MainActor in
                        guard let self else { return }
                        // Only update if still scanning
                        if self.state.isScanning {
                            self.state = .scanning(progress: progress)
                        }
                    }
                }

                // Update state with result
                state = .complete(rootItem: rootItem)

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

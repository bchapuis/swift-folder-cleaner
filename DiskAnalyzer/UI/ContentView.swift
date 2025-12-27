import SwiftUI

struct ContentView: View {
    @State private var viewModel = ScanViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Disk Analyzer")
                .font(.largeTitle)

            // State-based UI rendering
            switch viewModel.state {
            case .idle:
                idleView
            case .scanning(let progress):
                scanningView(progress: progress)
            case .complete(let result):
                resultView(result: result)
            case .failed(let error):
                errorView(error: error)
            }

            Button(viewModel.state.isScanning ? "Cancel Scan" : "Test Scan (Documents)") {
                if viewModel.state.isScanning {
                    viewModel.cancelScan()
                } else {
                    startTestScan()
                }
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }

    // MARK: - Subviews

    private var idleView: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Ready to scan")
                .foregroundStyle(.secondary)
        }
    }

    private func scanningView(progress: ScanProgress) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Scanning...")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(progress.filesScanned) files")
                Text(progress.formattedBytesScanned)
                Text(progress.formattedSpeed)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .background(.quaternary)
            .cornerRadius(8)
        }
    }

    private func resultView(result: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Scan Complete!")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("\(result.totalFilesScanned) files", systemImage: "doc.fill")
                Label(result.rootNode.formattedSize, systemImage: "internaldrive.fill")
                Label(result.formattedDuration, systemImage: "clock.fill")
                Label(String(format: "%.0f files/s", result.averageSpeed), systemImage: "gauge.with.dots.needle.bottom.50percent")
            }
            .font(.body)

            Button("New Scan") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(12)
    }

    private func errorView(error: ScanError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Scan Failed")
                .font(.headline)

            Text(error.localizedDescription)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Try Again") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Actions

    private func startTestScan() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let docsDir = homeDir.appendingPathComponent("Documents")
        viewModel.startScan(url: docsDir)
    }
}

#Preview {
    ContentView()
}

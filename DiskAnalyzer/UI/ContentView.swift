import SwiftUI

/// Main app view: scan → treemap
struct ContentView: View {
    @State private var viewModel = ScanViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // State-based content
            switch viewModel.state {
            case .idle:
                idleView
            case .scanning(let progress):
                scanningView(progress: progress)
            case .complete(let result):
                ScanResultView(result: result)
            case .failed(let error):
                errorView(error: error)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Disk Analyzer")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            if case .complete = viewModel.state {
                Button("New Scan") {
                    viewModel.reset()
                }
                .buttonStyle(.borderedProminent)
            } else if !viewModel.state.isScanning {
                Button("Scan Folder") {
                    startScan()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Cancel") {
                    viewModel.cancelScan()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.quaternary)
    }

    // MARK: - States

    private var idleView: some View {
        ContentUnavailableView {
            Label("Ready to Scan", systemImage: "folder.badge.gearshape")
        } description: {
            Text("Click \"Scan Folder\" to analyze disk usage")
        }
    }

    private func scanningView(progress: ScanProgress) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            VStack(spacing: 8) {
                Text("Scanning...")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(progress.filesScanned) files")
                    Text(progress.formattedBytesScanned)
                    Text(progress.formattedSpeed)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(error: ScanError) -> some View {
        ContentUnavailableView {
            Label("Scan Failed", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                viewModel.reset()
            }
        }
    }

    // MARK: - Actions

    private func startScan() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan"
        panel.message = "Select a folder to analyze"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            viewModel.startScan(url: url)
        }
    }
}

#Preview {
    ContentView()
}

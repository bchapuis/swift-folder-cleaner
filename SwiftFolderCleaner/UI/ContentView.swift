import SwiftUI
import SwiftData

/// Main app view: scan → treemap
struct ContentView: View {
    @State private var viewModel = ScanViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            // State-based content
            switch viewModel.state {
            case .idle:
                idleView
            case .scanning(let progress):
                scanningView(progress: progress)
            case .complete(let rootItem):
                ScanResultView(rootItem: rootItem)
            case .failed(let error):
                errorView(error: error)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                toolbarButton
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarButton: some View {
        if viewModel.state.isScanning {
            // Hide scan button during scanning - show cancel in scanning view instead
            EmptyView()
        } else {
            Button {
                startScan()
            } label: {
                Label("Scan Folder", systemImage: "folder.badge.gearshape")
            }
            .accessibilityLabel(String(localized: "Scan folder"))
            .accessibilityHint(String(localized: "Opens a folder picker to select a folder to analyze"))
            .keyboardShortcut("o", modifiers: .command)
        }
    }

    // MARK: - States

    private var idleView: some View {
        ContentUnavailableView {
            Label("Ready to Scan", systemImage: "folder.badge.gearshape")
        } description: {
            Text("Click \"Scan Folder\" to analyze disk usage")
        } actions: {
            Button {
                startScan()
            } label: {
                Label("Scan Folder", systemImage: "folder.badge.gearshape")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel(String(localized: "Scan folder"))
            .accessibilityHint(String(localized: "Opens a folder picker to select a folder to analyze"))
        }
    }

    private func scanningView(progress: ScanProgress) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .accessibilityLabel(String(localized: "Scanning in progress"))

            VStack(spacing: 8) {
                Text("Scanning...")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(progress.filesScanned.formatted(.number)) files")
                    Text(progress.formattedBytesScanned)
                    Text(progress.formattedSpeed)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("""
                Scan progress: \(progress.filesScanned.formatted(.number)) files scanned, \
                \(progress.formattedBytesScanned), \(progress.formattedSpeed)
                """)

            Button {
                viewModel.cancelScan()
            } label: {
                Label("Cancel", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(String(localized: "Cancel scan"))
            .accessibilityHint(String(localized: "Stops the current folder scan"))
            .keyboardShortcut(.escape)
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
            .accessibilityLabel(String(localized: "Try scanning again"))
            .accessibilityHint(String(localized: "Resets the scan state so you can select a new folder"))
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

import SwiftUI

/// Main window view with toolbar, content area, and status bar
struct MainWindow: View {
    @State private var viewModel = ScanViewModel()
    @State private var selectedFolder: URL?

    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            contentArea

            // Status bar
            statusBar
        }
        .frame(minWidth: 900, minHeight: 700)
        .toolbar {
            toolbarContent
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if selectedFolder == nil {
            // Welcome screen when no folder selected
            WelcomeView(onSelectFolder: selectFolder)
        } else {
            // Show scan state when folder is selected
            scanContentView
        }
    }

    @ViewBuilder
    private var scanContentView: some View {
        switch viewModel.state {
        case .idle:
            emptyStateView
        case .scanning(let progress):
            ScanningView(progress: progress)
        case .complete(let result):
            ScanResultView(result: result)
        case .failed(let error):
            ErrorView(error: error, onRetry: {
                if let folder = selectedFolder {
                    viewModel.startScan(url: folder)
                }
            })
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Ready to Scan", systemImage: "folder.badge.gearshape")
        } description: {
            Text("Click the scan button to analyze \(selectedFolder?.lastPathComponent ?? "this folder")")
        } actions: {
            Button("Start Scan") {
                if let folder = selectedFolder {
                    viewModel.startScan(url: folder)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                selectFolder()
            } label: {
                Label("Select Folder", systemImage: "folder.badge.plus")
            }
            .help("Choose a folder to scan")
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.state.isScanning {
                Button {
                    viewModel.cancelScan()
                } label: {
                    Label("Cancel", systemImage: "stop.circle")
                }
                .help("Cancel the current scan")
            } else if selectedFolder != nil && !viewModel.state.isComplete {
                Button {
                    if let folder = selectedFolder {
                        viewModel.startScan(url: folder)
                    }
                } label: {
                    Label("Scan", systemImage: "play.circle.fill")
                }
                .help("Start scanning the selected folder")
                .disabled(viewModel.state.isScanning)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.state.isComplete {
                Button {
                    viewModel.reset()
                    selectedFolder = nil
                } label: {
                    Label("New Scan", systemImage: "arrow.clockwise")
                }
                .help("Start a new scan")
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            // Left side - current folder or status
            if let folder = selectedFolder {
                Label(folder.path, systemImage: "folder.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("No folder selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right side - scan statistics
            if let progress = viewModel.currentProgress {
                HStack(spacing: 12) {
                    Label("\(progress.filesScanned) files", systemImage: "doc.fill")
                    Label(progress.formattedBytesScanned, systemImage: "internaldrive.fill")
                    Label(progress.formattedSpeed, systemImage: "gauge.medium")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else if let result = viewModel.scanResult {
                HStack(spacing: 12) {
                    Label("\(result.totalFilesScanned) files", systemImage: "doc.fill")
                    Label(result.rootNode.formattedSize, systemImage: "internaldrive.fill")
                    Label(result.formattedDuration, systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.quaternary)
    }

    // MARK: - Actions

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.message = "Select a folder to analyze"
        panel.prompt = "Select"

        // Set initial directory to last selected folder if available
        if let recent = BookmarkManager.shared.loadRecentFolderURLs().first {
            panel.directoryURL = recent
        }

        if panel.runModal() == .OK, let url = panel.url {
            // Save bookmark and add to recent folders
            BookmarkManager.shared.saveBookmark(for: url)
            BookmarkManager.shared.addRecentFolder(url)

            selectedFolder = url
            viewModel.reset()
        }
    }

    private func selectSpecificFolder(_ url: URL) {
        // Try to load bookmark first
        if let bookmarkedURL = BookmarkManager.shared.loadBookmark(for: url) {
            selectedFolder = bookmarkedURL
            BookmarkManager.shared.addRecentFolder(bookmarkedURL)
            viewModel.reset()
        } else {
            // If no bookmark, try direct access
            selectedFolder = url
            BookmarkManager.shared.saveBookmark(for: url)
            BookmarkManager.shared.addRecentFolder(url)
            viewModel.reset()
        }
    }
}

#Preview {
    MainWindow()
}

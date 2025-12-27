import SwiftUI

/// View shown when scan is complete
struct ScanResultView: View {
    let result: ScanResult

    @State private var selectedNode: FileNode?
    @State private var showDetails = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with statistics
            headerSection

            Divider()

            // Main content: file browser + details panel
            HSplitView {
                // File browser
                fileBrowserSection

                // Details panel
                if showDetails, let node = selectedNode {
                    FileDetailsPanel(node: node, totalSize: result.rootNode.totalSize)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showDetails.toggle()
                } label: {
                    Label(
                        showDetails ? "Hide Details" : "Show Details",
                        systemImage: showDetails ? "sidebar.right" : "sidebar.left"
                    )
                }
                .help(showDetails ? "Hide details panel" : "Show details panel")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Complete!")
                        .font(.headline)

                    Text(result.rootNode.path.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                statisticsCompact
            }
        }
        .padding()
        .background(.quaternary)
    }

    // MARK: - Statistics

    private var statisticsCompact: some View {
        HStack(spacing: 16) {
            CompactStat(
                label: "Files",
                value: "\(result.totalFilesScanned)",
                icon: "doc.fill"
            )

            CompactStat(
                label: "Size",
                value: result.rootNode.formattedSize,
                icon: "internaldrive.fill"
            )

            CompactStat(
                label: "Time",
                value: result.formattedDuration,
                icon: "clock.fill"
            )
        }
    }

    // MARK: - File Browser

    private var fileBrowserSection: some View {
        VStack(spacing: 0) {
            if result.rootNode.children.isEmpty {
                emptyBrowserView
            } else {
                FileBrowserView(
                    rootNode: result.rootNode,
                    selectedNode: $selectedNode
                )
            }
        }
    }

    private var emptyBrowserView: some View {
        ContentUnavailableView {
            Label("Empty Folder", systemImage: "folder")
        } description: {
            Text("This folder contains no files")
        }
    }

}

/// Compact statistics display
private struct CompactStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ScanResultView(
        result: ScanResult(
            rootNode: FileNode.directory(
                path: URL(fileURLWithPath: "/Users/example/Documents"),
                name: "Documents",
                modifiedDate: Date(),
                children: []
            ),
            scanDuration: 12.5,
            totalFilesScanned: 5432,
            errors: []
        )
    )
}

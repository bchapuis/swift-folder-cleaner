import SwiftUI

/// Details panel showing information about selected file/folder
struct FileDetailsPanel: View {
    let node: FileNode
    let totalSize: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            Divider()

            // Details
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic info
                    basicInfoSection

                    Divider()

                    // Size info
                    sizeInfoSection

                    if node.isDirectory {
                        Divider()

                        // Directory stats
                        directoryStatsSection
                    }

                    Divider()

                    // Metadata
                    metadataSection

                    Divider()

                    // Actions
                    actionsSection
                }
                .padding()
            }
        }
        .frame(width: 300)
        .background(.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: node.fileType.icon)
                .font(.system(size: 32))
                .foregroundStyle(node.fileType.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(node.name)
                    .font(.headline)
                    .lineLimit(2)

                Text(node.isDirectory ? "Folder" : "File")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(node.path.path)
                .font(.caption)
                .lineLimit(3)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }

    // MARK: - Size Info

    private var sizeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Size")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Size:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(node.formattedSize)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                HStack {
                    Text("Percentage:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%%", node.percentage(of: totalSize)))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                if node.totalSize > 0 {
                    HStack {
                        Text("Bytes:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(node.totalSize)")
                            .font(.caption2)
                            .monospacedDigit()
                    }
                }
            }
            .font(.callout)
        }
    }

    // MARK: - Directory Stats

    private var directoryStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contents")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Items:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(node.fileCount)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                HStack {
                    Text("Direct Children:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(node.children.count)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                if !node.children.isEmpty {
                    HStack {
                        Text("Largest Item:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let largest = node.children.max(by: { $0.totalSize < $1.totalSize }) {
                            Text(largest.formattedSize)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .font(.callout)
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Type:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(node.fileType.rawValue.capitalized)
                }

                HStack {
                    Text("Modified:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(node.modifiedDate, style: .date)
                }

                HStack {
                    Text("Time:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(node.modifiedDate, style: .time)
                }
            }
            .font(.callout)
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 8) {
            Button {
                NSWorkspace.shared.selectFile(node.path.path, inFileViewerRootedAtPath: node.path.deletingLastPathComponent().path)
            } label: {
                Label("Show in Finder", systemImage: "folder.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if !node.isDirectory {
                Button {
                    NSWorkspace.shared.open(node.path)
                } label: {
                    Label("Open File", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button(role: .destructive) {
                moveToTrash()
            } label: {
                Label("Move to Trash", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Actions Implementation

    private func moveToTrash() {
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Move to Trash?"
        alert.informativeText = "Are you sure you want to move \"\(node.name)\" to the trash?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try FileManager.default.trashItem(at: node.path, resultingItemURL: nil)
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Failed to Move to Trash"
                errorAlert.informativeText = error.localizedDescription
                errorAlert.alertStyle = .critical
                errorAlert.runModal()
            }
        }
    }
}

#Preview {
    FileDetailsPanel(
        node: FileNode.directory(
            path: URL(fileURLWithPath: "/Users/example/Documents/Projects"),
            name: "Projects",
            modifiedDate: Date(),
            children: [
                FileNode.file(
                    path: URL(fileURLWithPath: "/Users/example/Documents/Projects/main.swift"),
                    name: "main.swift",
                    size: 2048,
                    fileType: .code,
                    modifiedDate: Date()
                ),
                FileNode.file(
                    path: URL(fileURLWithPath: "/Users/example/Documents/Projects/README.md"),
                    name: "README.md",
                    size: 512,
                    fileType: .document,
                    modifiedDate: Date()
                )
            ]
        ),
        totalSize: 1_000_000
    )
}

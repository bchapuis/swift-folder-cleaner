import SwiftUI

/// Dual-pane view: treemap (left) + file list (right)
/// All state managed by ScanResultViewModel for perfect synchronization
struct ScanResultView: View {
    let result: ScanResult

    @State private var viewModel: ScanResultViewModel

    init(result: ScanResult) {
        self.result = result
        self._viewModel = State(initialValue: ScanResultViewModel(scanResult: result))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb navigation
            BreadcrumbView(
                breadcrumbTrail: viewModel.breadcrumbTrail,
                onNavigate: { index in
                    viewModel.navigateToBreadcrumb(at: index)
                },
                onNavigateUp: {
                    viewModel.navigateUp()
                }
            )

            Divider()

            // Dual pane: treemap + file list (50/50 split)
            HSplitView {
                // Left: Treemap visualization
                TreemapView(
                    viewModel: viewModel
                )
                .frame(minWidth: 400)

                // Right: File list
                FileListView(
                    viewModel: viewModel
                )
                .frame(minWidth: 400)
            }

            Divider()

            // Filename filter (text input with wildcards)
            FilenameFilterView(
                viewModel: viewModel
            )

            Divider()

            // File type legend (clickable filters) - full width
            FileTypeLegend(
                viewModel: viewModel
            )

            Divider()

            // Size filter legend (clickable filters) - full width
            SizeFilterLegend(
                viewModel: viewModel
            )

            Divider()

            // Bottom: Action toolbar
            HStack(spacing: 16) {
                // Selection info
                if let selected = viewModel.selectedNode {
                    Text("\(selected.name) · \(ByteCountFormatter.string(fromByteCount: selected.totalSize, countStyle: .file))")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Selected: \(selected.name), \(ByteCountFormatter.string(fromByteCount: selected.totalSize, countStyle: .file))")
                } else {
                    Text("No selection")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(String(localized: "No file or folder selected"))
                }

                Spacer()

                // Actions
                if viewModel.canPreviewSelection {
                    Button("Open in Application") {
                        viewModel.showInPreview()
                    }
                    .accessibilityLabel(String(localized: "Open in Application"))
                    .accessibilityHint(String(localized: "Opens the selected file in its default application"))
                }

                Button("Show in Finder") {
                    viewModel.showInFinder()
                }
                .disabled(viewModel.selectedNode == nil)
                .accessibilityLabel(String(localized: "Show in Finder"))
                .accessibilityHint(String(localized: "Reveals the selected item in Finder"))
                .keyboardShortcut("i", modifiers: .command)

                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteSelected()
                    }
                }
                .disabled(viewModel.selectedNode == nil)
                .keyboardShortcut(.delete, modifiers: .command)
                .accessibilityLabel(String(localized: "Delete"))
                .accessibilityHint(String(localized: "Moves the selected item to trash. Requires confirmation."))
            }
            .padding()
            .background(.quaternary)

            // Action message
            if let message = viewModel.actionMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.tertiary)
            }
        }
        .onKeyPress(.escape) {
            if viewModel.canNavigateUp() {
                viewModel.navigateUp()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.return) {
            // Enter/Return: Drill down into selected directory
            if let selected = viewModel.selectedNode, selected.isDirectory {
                viewModel.drillDown(to: selected)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.space) {
            // Space: Drill down into selected directory
            if let selected = viewModel.selectedNode, selected.isDirectory {
                viewModel.drillDown(to: selected)
                return .handled
            }
            return .ignored
        }
    }
}

#Preview {
    let rootNode = FileNode.directory(
        path: URL(fileURLWithPath: "/Users/example/Documents"),
        name: "Documents",
        modifiedDate: Date(),
        children: []
    )

    let scanResult = ScanResult(
        rootNode: rootNode,
        scanDuration: 12.5,
        totalFilesScanned: 5432,
        errors: [],
        index: IndexedFileTree(root: rootNode)
    )

    return ScanResultView(result: scanResult)
}

import SwiftUI

/// Dual-pane view: treemap (left) + file list (right)
/// All state managed by ScanResultViewModel for perfect synchronization
struct ScanResultView: View {
    let rootItem: FileItem

    @State private var viewModel: ScanResultViewModel

    init(rootItem: FileItem) {
        self.rootItem = rootItem
        self._viewModel = State(initialValue: ScanResultViewModel(rootItem: rootItem))
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

            // Dual pane: treemap + file list
            HSplitView {
                // Left: Treemap visualization
                TreemapView(
                    viewModel: viewModel
                )
                .frame(minWidth: 400, idealWidth: 600)

                // Right: File list
                FileListView(
                    viewModel: viewModel
                )
                .frame(minWidth: 400, idealWidth: 600)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Filter panel
            VStack(spacing: 0) {
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
            }
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Bottom: Status bar with actions
            HStack(spacing: 12) {
                // Selection info
                if let selected = viewModel.selectedNode {
                    let sizeText = ByteCountFormatter.string(fromByteCount: selected.totalSize, countStyle: .file)
                    HStack(spacing: 8) {
                        Image(systemName: selected.fileType.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(selected.fileType.color)
                        Text(selected.name)
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(sizeText)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Selected: \(selected.name), \(sizeText)")
                } else {
                    Text("No selection")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(String(localized: "No file or folder selected"))
                }

                Spacer()

                // Actions
                if viewModel.canPreviewSelection {
                    Button("Open") {
                        viewModel.showInPreview()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .accessibilityLabel(String(localized: "Open in Application"))
                    .accessibilityHint(String(localized: "Opens the selected file in its default application"))
                }

                Button("Show in Finder") {
                    viewModel.showInFinder()
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .disabled(viewModel.selectedNode == nil)
                .accessibilityLabel(String(localized: "Show in Finder"))
                .accessibilityHint(String(localized: "Reveals the selected item in Finder"))
                .keyboardShortcut("i", modifiers: .command)

                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteSelected()
                    }
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .disabled(viewModel.selectedNode == nil)
                .keyboardShortcut(.delete, modifiers: .command)
                .accessibilityLabel(String(localized: "Delete"))
                .accessibilityHint(String(localized: "Moves the selected item to trash. Requires confirmation."))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))

            // Action message
            if let message = viewModel.actionMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .unemphasizedSelectedContentBackgroundColor))
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
    let rootItem = FileItem.directory(
        path: URL(fileURLWithPath: "/Users/example/Documents"),
        name: "Documents",
        modifiedDate: Date(),
        children: []
    )

    ScanResultView(rootItem: rootItem)
}

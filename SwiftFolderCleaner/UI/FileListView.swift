import SwiftUI

/// Sortable file list view - reads state from and sends actions to ScanResultViewModel
struct FileListView: View {
    let viewModel: ScanResultViewModel

    @State private var sortBy: SortColumn = .size
    @State private var sortAscending = false
    @State private var selection: URL?
    @State private var scrollPosition: URL?

    // Cache sorted files to prevent recomputation on selection changes
    @State private var cachedSortedFiles: [FileItem] = []
    @State private var lastDisplayFilesCount = 0
    @State private var lastSortBy: SortColumn = .size
    @State private var lastSortAscending = false

    var body: some View {
        tableView
    }

    private var tableView: some View {
        Table(cachedSortedFiles, selection: $selection) {
            TableColumn("Name") { file in
                HStack(spacing: 6) {
                    Image(systemName: file.fileType.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(file.fileType.color)
                        .frame(width: 16)

                    Text(file.name)
                        .font(.system(size: 13))
                        .lineLimit(1)
                }
            }
            .width(min: 150, ideal: 250)

            TableColumn("Path") { file in
                Text(file.path.deletingLastPathComponent().path)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .width(min: 250, ideal: 350)

            TableColumn("Type") { file in
                Text(file.fileType.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .width(80)

            TableColumn("Size") { file in
                Text(ByteCountFormatter.string(fromByteCount: file.totalSize, countStyle: .file))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .width(80)

            TableColumn("%") { file in
                let totalSize = viewModel.currentRoot.totalSize
                let percentage = totalSize > 0 ? Double(file.totalSize) / Double(totalSize) : 0
                Text(percentage.formatted(.percent.precision(.fractionLength(1))))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .width(80)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .background(Color(nsColor: .controlBackgroundColor))
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .onChange(of: selection) { _, newValue in
            if let path = newValue, let node = cachedSortedFiles.first(where: { $0.path == path }) {
                viewModel.selectNode(node)
            } else {
                viewModel.selectNode(nil)
            }
        }
        .onChange(of: viewModel.selectedNode?.path) { _, newPath in
            selection = newPath
            // Auto-scroll to selected item when selection changes from treemap
            if let path = newPath {
                scrollPosition = path
            }
        }
        .onChange(of: viewModel.currentRoot.path) { _, _ in
            updateCache()
        }
        .onChange(of: viewModel.filterVersion) { _, _ in
            updateCache()
        }
        .onChange(of: sortBy) { _, _ in
            updateCache()
        }
        .onChange(of: sortAscending) { _, _ in
            updateCache()
        }
        .onAppear {
            updateCache()
        }
        .onKeyPress(.return) {
            if let selected = viewModel.selectedNode, selected.isDirectory {
                viewModel.drillDown(to: selected)
                return .handled
            }
            return .ignored
        }
    }

    // Update cached sorted files
    private func updateCache() {
        let files = viewModel.displayFiles
        cachedSortedFiles = sortFiles(files)
        lastDisplayFilesCount = files.count
        lastSortBy = sortBy
        lastSortAscending = sortAscending
    }

    private func sortFiles(_ files: [FileItem]) -> [FileItem] {
        switch sortBy {
        case .name:
            return sortAscending
                ? files.sorted { $0.name < $1.name }
                : files.sorted { $0.name > $1.name }
        case .size:
            return sortAscending
                ? files.sorted { $0.totalSize < $1.totalSize }
                : files.sorted { $0.totalSize > $1.totalSize }
        case .percentage:
            return sortAscending
                ? files.sorted { percentage(for: $0) < percentage(for: $1) }
                : files.sorted { percentage(for: $0) > percentage(for: $1) }
        case .type:
            return sortAscending
                ? files.sorted { $0.fileType.rawValue < $1.fileType.rawValue }
                : files.sorted { $0.fileType.rawValue > $1.fileType.rawValue }
        case .path:
            return sortAscending
                ? files.sorted { $0.path.path < $1.path.path }
                : files.sorted { $0.path.path > $1.path.path }
        }
    }

    private func percentage(for file: FileItem) -> Double {
        let totalSize = viewModel.currentRoot.totalSize
        guard totalSize > 0 else { return 0 }
        return Double(file.totalSize) / Double(totalSize) * 100
    }

}

// MARK: - Sort Column

enum SortColumn {
    case name
    case size
    case percentage
    case type
    case path
}

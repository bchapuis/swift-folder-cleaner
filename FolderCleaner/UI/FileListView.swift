import SwiftUI

/// Sortable file list view - reads state from and sends actions to ScanResultViewModel
struct FileListView: View {
    let viewModel: ScanResultViewModel

    @State private var sortBy: SortColumn = .size
    @State private var sortAscending = false

    // Double-click tracking
    @State private var lastTapTime: Date = .distantPast
    @State private var lastTapNode: FileNode?

    // Cache sorted files to prevent recomputation on selection changes
    @State private var cachedSortedFiles: [FileNode] = []
    @State private var lastDisplayFilesCount = 0
    @State private var lastSortBy: SortColumn = .size
    @State private var lastSortAscending = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // File list with scroll-to-selection
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(cachedSortedFiles, id: \.path) { file in
                            fileRow(file)
                                .id(file.path)
                        }
                    }
                }
                .onChange(of: viewModel.selectedNode?.path) { _, newPath in
                    // Scroll to selected item (both files and directories are now in the list)
                    if let path = newPath {
                        proxy.scrollTo(path, anchor: .center)
                    }
                }
            }
        }
        .background(Color(.controlBackgroundColor))
        .onChange(of: viewModel.currentRoot.path) { _, _ in
            // Navigation changed - update file list
            updateCache()
        }
        .onChange(of: viewModel.filterVersion) { _, _ in
            // Any filter changed (type, size, filename, etc.) - update file list
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
    }

    // Update cached sorted files
    private func updateCache() {
        let files = viewModel.displayFiles
        cachedSortedFiles = sortFiles(files)
        lastDisplayFilesCount = files.count
        lastSortBy = sortBy
        lastSortAscending = sortAscending
    }

    private func sortFiles(_ files: [FileNode]) -> [FileNode] {
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

    private func percentage(for file: FileNode) -> Double {
        let totalSize = viewModel.currentRoot.totalSize
        guard totalSize > 0 else { return 0 }
        return Double(file.totalSize) / Double(totalSize) * 100
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 0) {
            // Name column (flexible)
            columnHeaderFlexible("Name", column: .name, minWidth: 150)

            // Path column (flexible)
            columnHeaderFlexible("Path", column: .path, minWidth: 250)

            // Type column (fixed)
            columnHeaderFixed("Type", column: .type, width: 80)

            // Size column (fixed)
            columnHeaderFixed("Size", column: .size, width: 80)

            // Percentage column (fixed)
            columnHeaderFixed("%", column: .percentage, width: 80)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private func columnHeaderFixed(_ title: String, column: SortColumn, width: CGFloat) -> some View {
        Button {
            if sortBy == column {
                sortAscending.toggle()
            } else {
                sortBy = column
                sortAscending = false
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                if sortBy == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .frame(width: width, alignment: .leading)
    }

    @ViewBuilder
    private func columnHeaderFlexible(_ title: String, column: SortColumn, minWidth: CGFloat) -> some View {
        Button {
            if sortBy == column {
                sortAscending.toggle()
            } else {
                sortBy = column
                sortAscending = false
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                if sortBy == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .frame(minWidth: minWidth, maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - File Row

    @ViewBuilder
    private func fileRow(_ file: FileNode) -> some View {
        let isSelected = file.path == viewModel.selectedNode?.path

        HStack(spacing: 0) {
            // Name (flexible)
            HStack(spacing: 6) {
                Image(systemName: file.fileType.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(file.fileType.color)
                    .frame(width: 16)

                Text(file.name)
                    .font(.system(size: 12))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                    .help(file.name)
            }
            .frame(minWidth: 150, maxWidth: .infinity, alignment: .leading)
            
            // Path (flexible)
            Text(file.path.deletingLastPathComponent().path)
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? .secondary : .tertiary)
                .lineLimit(1)
                .help(file.path.path)
                .frame(minWidth: 250, maxWidth: .infinity, alignment: .leading)
            
            // Type (fixed)
            Text(file.fileType.displayName)
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(width: 80, alignment: .leading)

            // Size (fixed)
            Text(ByteCountFormatter.string(fromByteCount: file.totalSize, countStyle: .file))
                .font(.system(size: 12))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(width: 80, alignment: .leading)

            // Percentage (fixed)
            Text(String(format: "%.1f%%", percentage(for: file)))
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(width: 80, alignment: .leading)

        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .overlay(
            Rectangle()
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 3)
                .padding(.leading, 0),
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(on: file)
        }
    }

    // MARK: - Interaction Handler

    private func handleTap(on file: FileNode) {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)

        // Check for double-tap (within 0.3s and same node)
        let isDoubleTap = timeSinceLastTap < 0.3 && lastTapNode?.path == file.path

        if isDoubleTap && file.isDirectory {
            viewModel.drillDown(to: file)
        } else {
            viewModel.selectNode(file)
        }

        lastTapTime = now
        lastTapNode = file
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

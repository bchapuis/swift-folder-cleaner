import SwiftUI

/// Sortable file list view - reads state from and sends actions to ScanResultViewModel
struct FileListView: View {
    let viewModel: ScanResultViewModel

    @State private var sortBy: SortColumn = .size
    @State private var sortAscending = false

    // Double-click tracking
    @State private var lastTapTime: Date = .distantPast
    @State private var lastTapNode: FileNode?

    /// Sorted files computed from ViewModel's filtered data
    private var sortedFiles: [FileNode] {
        let files = viewModel.displayFiles

        switch sortBy {
        case .name:
            return sortAscending
                ? files.sorted { $0.name < $1.name }
                : files.sorted { $0.name > $1.name }
        case .size:
            return sortAscending
                ? files.sorted { $0.totalSize < $1.totalSize }
                : files.sorted { $0.totalSize > $1.totalSize }
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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // File list with scroll-to-selection
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedFiles, id: \.path) { file in
                            fileRow(file)
                                .id(file.path)
                        }
                    }
                }
                .onChange(of: viewModel.selectedNode?.path) { _, newPath in
                    // Scroll to selected item when selection changes
                    if let path = newPath {
                        withAnimation {
                            proxy.scrollTo(path, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(Color(.controlBackgroundColor))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 0) {
            // Name column
            columnHeader("Name", column: .name, flex: 3)

            // Size column
            columnHeader("Size", column: .size, flex: 1.5)

            // Type column
            columnHeader("Type", column: .type, flex: 1)

            // Path column
            columnHeader("Path", column: .path, flex: 2)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private func columnHeader(_ title: String, column: SortColumn, flex: CGFloat) -> some View {
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
        .frame(maxWidth: .infinity * flex)
    }

    // MARK: - File Row

    @ViewBuilder
    private func fileRow(_ file: FileNode) -> some View {
        let isSelected = file.path.standardized == viewModel.selectedNode?.path.standardized

        HStack(spacing: 0) {
            // Name
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
            .frame(maxWidth: .infinity * 3, alignment: .leading)

            // Size
            Text(ByteCountFormatter.string(fromByteCount: file.totalSize, countStyle: .file))
                .font(.system(size: 12))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity * 1.5, alignment: .leading)

            // Type
            Text(file.fileType.displayName)
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity * 1, alignment: .leading)

            // Path
            Text(file.path.deletingLastPathComponent().path)
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? .secondary : .tertiary)
                .lineLimit(1)
                .help(file.path.path)
                .frame(maxWidth: .infinity * 2, alignment: .leading)
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
        let isDoubleTap = timeSinceLastTap < 0.3 && lastTapNode?.path.standardized == file.path.standardized

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
    case type
    case path
}

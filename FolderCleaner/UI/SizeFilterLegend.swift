import SwiftUI

/// Size filter legend showing clickable size threshold filters
struct SizeFilterLegend: View {
    let viewModel: ScanResultViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let sizeFilters: [FileSizeFilter] = FileSizeFilter.allCases

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Text("Size:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)

                ForEach(sizeFilters) { filter in
                    legendItem(for: filter)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(height: 36)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private func legendItem(for filter: FileSizeFilter) -> some View {
        let isSelected = viewModel.selectedSize == filter

        Button {
            viewModel.toggleSizeFilter(filter)
        } label: {
            HStack(spacing: 6) {
                // Size icon
                Image(systemName: filter.systemImage)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .primary : .tertiary)

                // Size threshold
                Text(filter.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.borderless)
        .help(filter == .all ? "Show all file sizes" : "Show only files \(filter.rawValue)")
        .accessibilityLabel("Size filter: \(filter.rawValue)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(filter == .all ? "Shows all file sizes" : "Shows only files \(filter.rawValue)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    let rootNode = FileNode.directory(
        path: URL(fileURLWithPath: "/Users/example/Documents"),
        name: "Documents",
        modifiedDate: Date(),
        children: []
    )

    let scanResult = ScanResult(
        rootNode: rootNode,
        scanDuration: 1.0,
        totalFilesScanned: 100,
        errors: [],
        index: IndexedFileTree(root: rootNode)
    )

    let viewModel = ScanResultViewModel(scanResult: scanResult)

    SizeFilterLegend(viewModel: viewModel)
        .frame(width: 600)
}

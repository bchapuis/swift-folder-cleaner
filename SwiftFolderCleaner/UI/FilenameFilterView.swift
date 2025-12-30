import SwiftUI

/// Filename filter text input with wildcard support
struct FilenameFilterView: View {
    let viewModel: ScanResultViewModel
    @State private var searchText: String = ""

    var body: some View {
        HStack(spacing: 12) {
            // Label
            Text("Name:")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            // Search field with subtle styling
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                TextField("Filter by name (*.ts, node_modules, etc.)", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onChange(of: searchText) { _, newValue in
                        viewModel.setFilenameFilter(newValue)
                    }
                    .accessibilityLabel(String(localized: "Filename filter"))
                    .accessibilityHint(String(
                        localized: "Enter text or wildcards to filter files by name. Use asterisk for any characters."
                    ))
                    .accessibilityValue(searchText.isEmpty ? String(localized: "No filter") : searchText)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.borderless)
                    .help("Clear filter")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            // Helper text
            if !searchText.isEmpty {
                Text("Wildcards: * (any)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 32)
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

    FilenameFilterView(viewModel: viewModel)
        .frame(width: 800)
}

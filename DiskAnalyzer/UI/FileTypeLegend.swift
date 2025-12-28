import SwiftUI

/// File type legend showing color coding for different file types - clickable for filtering
struct FileTypeLegend: View {
    let viewModel: ScanResultViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let fileTypes: [FileType] = [
        .directory,
        .code,
        .image,
        .video,
        .audio,
        .document,
        .archive,
        .executable,
        .system,
        .other
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(fileTypes, id: \.self) { type in
                    legendItem(for: type)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(height: 36)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private func legendItem(for type: FileType) -> some View {
        let isSelected = viewModel.selectedTypes.contains(type)

        Button {
            viewModel.toggleFileType(type)
        } label: {
            HStack(spacing: 6) {
                // Color indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(colorScheme == .dark ? type.darkModeColor : type.color)
                    .frame(width: 16, height: 16)
                    .opacity(isSelected ? 1.0 : 0.3)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(
                                isSelected ? Color.accentColor : Color.white.opacity(0.3),
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    }

                // Type name
                Text(type.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(isSelected ? "Hide \(type.displayName)" : "Show \(type.displayName)")
    }
}

// MARK: - FileType Extension

extension FileType {
    var displayName: String {
        switch self {
        case .directory: return "Folder"
        case .code: return "Code"
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        case .document: return "Document"
        case .archive: return "Archive"
        case .executable: return "Executable"
        case .system: return "System"
        case .other: return "Other"
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
        scanDuration: 1.0,
        totalFilesScanned: 100,
        errors: []
    )

    let viewModel = ScanResultViewModel(scanResult: scanResult)

    return FileTypeLegend(viewModel: viewModel)
        .frame(width: 800)
}

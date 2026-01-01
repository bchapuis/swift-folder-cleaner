import SwiftUI

/// File type legend showing color coding for different file types - clickable for filtering
struct FileTypeLegend: View {
    let viewModel: ScanResultViewModel

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
                Text("Type:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)

                ForEach(fileTypes, id: \.self) { type in
                    legendItem(for: type)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(height: 32)
    }

    @ViewBuilder
    private func legendItem(for type: FileType) -> some View {
        let isSelected = viewModel.selectedTypes.contains(type)

        Button {
            viewModel.toggleFileType(type)
        } label: {
            HStack(spacing: 6) {
                // Color indicator - automatically adapts to light/dark mode
                Circle()
                    .fill(type.color)
                    .frame(width: 12, height: 12)
                    .opacity(isSelected ? 1.0 : 0.3)

                // Type name
                Text(type.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color(nsColor: .controlAccentColor).opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.borderless)
        .help(isSelected ? "Hide \(type.displayName)" : "Show \(type.displayName)")
        .accessibilityLabel("\(type.displayName) filter")
        .accessibilityValue(isSelected ? String(localized: "Shown") : String(localized: "Hidden"))
        .accessibilityHint("Toggles visibility of \(type.displayName.lowercased()) files in the treemap")
        .accessibilityAddTraits(.isButton)
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
    let rootItem = FileItem.directory(
        path: URL(fileURLWithPath: "/Users/example/Documents"),
        name: "Documents",
        modifiedDate: Date(),
        children: []
    )

    let viewModel = ScanResultViewModel(rootItem: rootItem)

    FileTypeLegend(viewModel: viewModel)
        .frame(width: 800)
}

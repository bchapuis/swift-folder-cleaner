import SwiftUI

/// Color legend showing file type categories
struct FileTypeLegend: View {
    @Environment(\.colorScheme) private var colorScheme

    private let fileTypes: [FileType] = [
        .directory, .document, .image, .video, .audio,
        .code, .archive, .executable, .system, .other
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("File Types")
                .font(.headline)
                .padding(.bottom, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(fileTypes, id: \.self) { fileType in
                    legendItem(for: fileType)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func legendItem(for fileType: FileType) -> some View {
        HStack(spacing: 8) {
            // Color square
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    colorScheme == .dark
                        ? fileType.darkModeColor
                        : fileType.color
                )
                .frame(width: 16, height: 16)

            // Label
            Text(fileType.rawValue.capitalized)
                .font(.system(size: 11))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    FileTypeLegend()
        .frame(width: 300)
        .padding()
}

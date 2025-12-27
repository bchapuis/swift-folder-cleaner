import SwiftUI

/// Color legend showing file type categories
struct FileTypeLegend: View {
    @Environment(\.colorScheme) private var colorScheme

    private let fileTypes: [FileType] = [
        .directory, .document, .image, .video, .audio,
        .code, .archive, .executable, .system, .other
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("File Types")
                .font(.system(size: 11, weight: .semibold))
                .padding(.bottom, 2)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(fileTypes, id: \.self) { fileType in
                    legendItem(for: fileType)
                }
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
    }

    @ViewBuilder
    private func legendItem(for fileType: FileType) -> some View {
        HStack(spacing: 6) {
            // Color square
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    colorScheme == .dark
                        ? fileType.darkModeColor
                        : fileType.color
                )
                .frame(width: 12, height: 12)

            // Label
            Text(fileType.rawValue.capitalized)
                .font(.system(size: 10))
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

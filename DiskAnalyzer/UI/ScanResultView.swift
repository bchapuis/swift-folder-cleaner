import SwiftUI

/// View shown when scan is complete
struct ScanResultView: View {
    let result: ScanResult

    var body: some View {
        VStack(spacing: 24) {
            // Success header
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Complete!")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(result.rootNode.path.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Statistics grid
            statisticsGrid

            // Placeholder for future content
            placeholderContent
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Statistics Grid

    private var statisticsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Files",
                value: "\(result.totalFilesScanned)",
                icon: "doc.fill",
                color: .blue
            )

            StatCard(
                title: "Total Size",
                value: result.rootNode.formattedSize,
                icon: "internaldrive.fill",
                color: .purple
            )

            StatCard(
                title: "Scan Time",
                value: result.formattedDuration,
                icon: "clock.fill",
                color: .orange
            )

            StatCard(
                title: "Avg Speed",
                value: String(format: "%.0f files/s", result.averageSpeed),
                icon: "gauge.with.dots.needle.bottom.50percent",
                color: .green
            )
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(12)
    }

    // MARK: - Placeholder

    private var placeholderContent: some View {
        ContentUnavailableView {
            Label("File Browser Coming Soon", systemImage: "list.bullet.rectangle.portrait")
        } description: {
            Text("The file browser and treemap visualization will be added in the next phases")
        }
        .frame(maxHeight: .infinity)
    }
}

/// Statistics card component
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ScanResultView(
        result: ScanResult(
            rootNode: FileNode.directory(
                path: URL(fileURLWithPath: "/Users/example/Documents"),
                name: "Documents",
                modifiedDate: Date(),
                children: []
            ),
            scanDuration: 12.5,
            totalFilesScanned: 5432,
            errors: []
        )
    )
}

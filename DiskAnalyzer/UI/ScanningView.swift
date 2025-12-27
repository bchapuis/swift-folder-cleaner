import SwiftUI

/// View shown during active scanning
struct ScanningView: View {
    let progress: ScanProgress

    var body: some View {
        VStack(spacing: 24) {
            // Progress indicator
            ProgressView()
                .scaleEffect(2.0)
                .padding()

            // Status
            VStack(spacing: 8) {
                Text("Scanning...")
                    .font(.title2)
                    .fontWeight(.medium)

                if !progress.currentPath.isEmpty {
                    Text(progress.currentPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 600)
                }
            }

            // Statistics
            statisticsCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 32) {
                StatisticView(
                    title: "Files Scanned",
                    value: "\(progress.filesScanned)",
                    icon: "doc.fill"
                )

                Divider()
                    .frame(height: 40)

                StatisticView(
                    title: "Total Size",
                    value: progress.formattedBytesScanned,
                    icon: "internaldrive.fill"
                )

                Divider()
                    .frame(height: 40)

                StatisticView(
                    title: "Speed",
                    value: progress.formattedSpeed,
                    icon: "gauge.with.dots.needle.bottom.50percent"
                )
            }
        }
        .padding(24)
        .background(.quaternary)
        .cornerRadius(12)
    }
}

/// Individual statistic display
private struct StatisticView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 100)
    }
}

#Preview {
    ScanningView(
        progress: ScanProgress(
            filesScanned: 1234,
            currentPath: "/Users/example/Documents/Projects/MyApp/src/components/Button.swift",
            totalBytes: 524_288_000,
            startTime: Date().addingTimeInterval(-5)
        )
    )
}

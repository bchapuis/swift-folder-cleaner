import SwiftUI

/// Welcome screen shown when no folder is selected
struct WelcomeView: View {
    let onSelectFolder: () -> Void

    @State private var recentFolders: [URL] = []

    var body: some View {
        ContentUnavailableView {
            Label("Disk Analyzer", systemImage: "internaldrive.fill")
                .font(.largeTitle)
        } description: {
            VStack(spacing: 16) {
                Text("Visualize your disk space usage")
                    .font(.title3)

                Text("Select a folder to scan and see which files are taking up the most space")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        } actions: {
            VStack(spacing: 12) {
                Button {
                    onSelectFolder()
                } label: {
                    Label("Select Folder", systemImage: "folder.badge.plus")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                quickAccessButtons

                if !recentFolders.isEmpty {
                    Divider()
                        .padding(.vertical, 8)

                    recentFoldersSection
                }
            }
        }
        .onAppear {
            recentFolders = BookmarkManager.shared.loadRecentFolderURLs()
        }
    }

    // MARK: - Quick Access

    private var quickAccessButtons: some View {
        VStack(spacing: 8) {
            Text("Quick Access")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                QuickAccessButton(
                    title: "Home",
                    icon: "house.fill",
                    url: FileManager.default.homeDirectoryForCurrentUser
                )

                QuickAccessButton(
                    title: "Documents",
                    icon: "doc.fill",
                    url: FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Documents")
                )

                QuickAccessButton(
                    title: "Downloads",
                    icon: "arrow.down.circle.fill",
                    url: FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Downloads")
                )

                QuickAccessButton(
                    title: "Desktop",
                    icon: "desktopcomputer",
                    url: FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Desktop")
                )
            }
        }
    }

    // MARK: - Recent Folders

    private var recentFoldersSection: some View {
        VStack(spacing: 8) {
            Text("Recent Folders")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                ForEach(recentFolders.prefix(5), id: \.path) { url in
                    Button {
                        // This will be handled by parent view
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                            Spacer()
                            Text(url.deletingLastPathComponent().path)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .frame(maxWidth: 400)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Quick access button for common locations
private struct QuickAccessButton: View {
    let title: String
    let icon: String
    let url: URL

    var body: some View {
        Button {
            // This will be handled by parent view in full implementation
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80, height: 60)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    WelcomeView(onSelectFolder: {})
        .frame(width: 800, height: 600)
}

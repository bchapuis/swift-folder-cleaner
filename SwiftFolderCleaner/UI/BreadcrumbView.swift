import SwiftUI

/// Breadcrumb navigation bar - displays current directory path
struct BreadcrumbView: View {
    let breadcrumbTrail: [FileNode]
    let onNavigate: (Int) -> Void  // Navigate to breadcrumb at index
    let onNavigateUp: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Breadcrumb trail showing current path
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(breadcrumbTrail.enumerated()), id: \.element.path) { index, node in
                        HStack(spacing: 4) {
                            // Separator
                            if index > 0 {
                                Image(systemName: "chevron.compact.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.quaternary)
                            }

                            // Breadcrumb segment
                            breadcrumbSegment(
                                node: node,
                                index: index,
                                isLast: index == breadcrumbTrail.count - 1
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            Spacer()
        }
        .frame(height: 32)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func breadcrumbSegment(node: FileNode, index: Int, isLast: Bool) -> some View {
        if !isLast && node.isDirectory {
            // Clickable segment (can navigate to this directory)
            Button {
                onNavigate(index)
            } label: {
                segmentLabel(node: node, isLast: false, isHoverable: true)
            }
            .buttonStyle(BreadcrumbButtonStyle())
            .help("Click to navigate to \(node.name)")
            .accessibilityLabel("Navigate to \(node.name)")
            .accessibilityHint(String(localized: "Opens this folder in the treemap"))
            .accessibilityAddTraits(.isButton)
        } else {
            // Current directory (not clickable)
            let sizeText = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
            segmentLabel(node: node, isLast: isLast, isHoverable: false)
                .accessibilityLabel("Current folder: \(node.name), \(sizeText)")
                .accessibilityAddTraits(.isStaticText)
        }
    }

    @ViewBuilder
    private func segmentLabel(node: FileNode, isLast: Bool, isHoverable: Bool) -> some View {
        HStack(spacing: 6) {
            // Icon
            Image(systemName: node.fileType.icon)
                .font(.system(size: 11))
                .foregroundStyle(isLast ? node.fileType.color : .secondary)

            // Name
            Text(node.name)
                .font(.system(size: 12, weight: isLast ? .medium : .regular))
                .foregroundStyle(isLast ? .primary : .secondary)
                .lineLimit(1)

            // Size (only for current directory)
            if isLast {
                Text("·")
                    .foregroundStyle(.quaternary)
                    .font(.system(size: 11))
                Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(isLast ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Breadcrumb Button Style

struct BreadcrumbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(nsColor: .controlAccentColor).opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { isHovering in
                if isHovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

#Preview {
    let documentsNode = FileNode.directory(
        path: URL(fileURLWithPath: "/Users/example/Documents"),
        name: "Documents",
        modifiedDate: Date(),
        children: []
    )

    let photosNode = FileNode.directory(
        path: URL(fileURLWithPath: "/Users/example/Documents/Photos"),
        name: "Photos",
        modifiedDate: Date(),
        children: []
    )

    return VStack(spacing: 20) {
        BreadcrumbView(
            breadcrumbTrail: [documentsNode, photosNode],
            onNavigate: { _ in },
            onNavigateUp: {}
        )
    }
    .padding()
}

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
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
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
        .frame(height: 36)
        .background(.quaternary.opacity(0.5))
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
                .font(.system(size: 12))
                .foregroundStyle(node.fileType.color)

            // Name
            Text(node.name)
                .font(.system(size: 12, weight: isLast ? .semibold : .regular))
                .foregroundStyle(isLast ? .primary : (isHoverable ? .primary : .secondary))
                .lineLimit(1)
                .underline(isHoverable, color: .secondary.opacity(0.5))

            // Size
            Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isLast ? Color.accentColor.opacity(0.1) : (isHoverable ? Color.blue.opacity(0.05) : Color.clear))
        .cornerRadius(6)
    }
}

// MARK: - Breadcrumb Button Style

struct BreadcrumbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
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

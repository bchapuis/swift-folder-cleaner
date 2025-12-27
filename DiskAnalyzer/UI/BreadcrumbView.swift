import SwiftUI

/// Breadcrumb navigation showing the current path in the treemap
struct BreadcrumbView: View {
    let rootNode: FileNode
    let currentNode: FileNode?
    let onNavigate: (FileNode?) -> Void

    // Build path from root to current node
    private var breadcrumbPath: [FileNode] {
        guard let current = currentNode else {
            return [rootNode]
        }

        var path: [FileNode] = []
        var node: FileNode? = current

        // Build path backwards from current to root
        while let currentNode = node {
            path.insert(currentNode, at: 0)

            // Find parent
            if currentNode.path == rootNode.path {
                break
            }

            node = findParent(of: currentNode, in: rootNode)
        }

        // Ensure root is first if not already
        if path.first?.path != rootNode.path {
            path.insert(rootNode, at: 0)
        }

        return path
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(breadcrumbPath.enumerated()), id: \.element.path) { index, node in
                    Button {
                        // Navigate to this level (nil for root)
                        if node.path == rootNode.path {
                            onNavigate(nil)
                        } else {
                            onNavigate(node)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if index == 0 {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 12))
                            }

                            Text(index == 0 ? rootNode.name : node.name)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            if node.path == currentNode?.path {
                                Capsule()
                                    .fill(.quaternary)
                            }
                        }
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(node.path == currentNode?.path ? .primary : .secondary)

                    if index < breadcrumbPath.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(height: 36)
        .background(.bar)
    }

    // MARK: - Helper Methods

    /// Recursively finds the parent of a given node
    private func findParent(of targetNode: FileNode, in searchNode: FileNode) -> FileNode? {
        // Check if any of searchNode's children match the target
        for child in searchNode.children {
            if child.path == targetNode.path {
                return searchNode
            }

            // Recursively search in children
            if let parent = findParent(of: targetNode, in: child) {
                return parent
            }
        }

        return nil
    }
}

#Preview {
    let sampleNode = FileNode(
        path: URL(fileURLWithPath: "/Users/example/Documents"),
        name: "Documents",
        size: 0,
        fileType: .directory,
        modifiedDate: Date(),
        children: [
            FileNode(
                path: URL(fileURLWithPath: "/Users/example/Documents/Projects"),
                name: "Projects",
                size: 1_000_000_000,
                fileType: .directory,
                modifiedDate: Date(),
                children: [
                    FileNode(
                        path: URL(fileURLWithPath: "/Users/example/Documents/Projects/App"),
                        name: "App",
                        size: 500_000_000,
                        fileType: .directory,
                        modifiedDate: Date(),
                        children: [],
                        isDirectory: true
                    )
                ],
                isDirectory: true
            )
        ],
        isDirectory: true
    )

    return VStack {
        BreadcrumbView(
            rootNode: sampleNode,
            currentNode: sampleNode.children.first,
            onNavigate: { _ in }
        )

        Spacer()
    }
    .frame(width: 600, height: 400)
}

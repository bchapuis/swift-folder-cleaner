import SwiftUI

/// File browser with tree view display
struct FileBrowserView: View {
    let rootNode: FileNode
    @Binding var selectedNode: FileNode?

    @State private var expandedNodes: Set<URL> = []

    var body: some View {
        List(selection: $selectedNode) {
            FileNodeRow(
                node: rootNode,
                expandedNodes: $expandedNodes,
                selectedNode: $selectedNode
            )
        }
        .listStyle(.sidebar)
        .onAppear {
            // Auto-expand root node
            expandedNodes.insert(rootNode.path)
        }
    }
}

/// Recursive file node row
struct FileNodeRow: View {
    let node: FileNode
    @Binding var expandedNodes: Set<URL>
    @Binding var selectedNode: FileNode?

    var body: some View {
        if node.isDirectory && !node.children.isEmpty {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedNodes.contains(node.path) },
                    set: { isExpanded in
                        if isExpanded {
                            expandedNodes.insert(node.path)
                        } else {
                            expandedNodes.remove(node.path)
                        }
                    }
                )
            ) {
                ForEach(node.children) { child in
                    FileNodeRow(
                        node: child,
                        expandedNodes: $expandedNodes,
                        selectedNode: $selectedNode
                    )
                }
            } label: {
                FileNodeLabel(node: node)
                    .tag(node)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedNode = node
                    }
            }
        } else {
            FileNodeLabel(node: node)
                .tag(node)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedNode = node
                }
        }
    }
}

/// Label for a file node in the tree
struct FileNodeLabel: View {
    let node: FileNode

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: node.fileType.icon)
                .foregroundStyle(node.fileType.color)
                .frame(width: 20)

            // Name
            Text(node.name)
                .lineLimit(1)

            Spacer()

            // Size
            Text(node.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

#Preview {
    FileBrowserView(
        rootNode: FileNode.directory(
            path: URL(fileURLWithPath: "/Users/example/Documents"),
            name: "Documents",
            modifiedDate: Date(),
            children: [
                FileNode.file(
                    path: URL(fileURLWithPath: "/Users/example/Documents/file1.txt"),
                    name: "file1.txt",
                    size: 1024,
                    fileType: .document,
                    modifiedDate: Date()
                ),
                FileNode.directory(
                    path: URL(fileURLWithPath: "/Users/example/Documents/Projects"),
                    name: "Projects",
                    modifiedDate: Date(),
                    children: [
                        FileNode.file(
                            path: URL(fileURLWithPath: "/Users/example/Documents/Projects/main.swift"),
                            name: "main.swift",
                            size: 2048,
                            fileType: .code,
                            modifiedDate: Date()
                        )
                    ]
                )
            ]
        ),
        selectedNode: .constant(nil)
    )
    .frame(width: 400, height: 600)
}

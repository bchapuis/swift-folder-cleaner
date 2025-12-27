import SwiftUI

/// High-performance treemap visualization using Canvas
struct TreemapView: View {
    let rootNode: FileNode
    @Binding var selectedNode: FileNode?
    @Binding var zoomedNode: FileNode?
    @Environment(\.colorScheme) private var colorScheme

    @State private var hoveredNode: FileNode?
    @State private var mouseLocation: CGPoint = .zero
    @State private var lastClickTime: Date = .distantPast
    @State private var lastClickLocation: CGPoint = .zero

    // Current node being displayed (zoomed node or root)
    private var displayNode: FileNode {
        zoomedNode ?? rootNode
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Generate layout for current bounds
                let rectangles = TreemapLayout.layout(
                    node: displayNode,
                    in: CGRect(origin: .zero, size: size)
                )

                // Render each rectangle
                for rectangle in rectangles {
                    drawRectangle(rectangle, in: context)
                }

                // Draw selection highlight
                if let selected = selectedNode,
                   let selectedRect = rectangles.first(where: { $0.node.path == selected.path }) {
                    drawSelectionHighlight(selectedRect, in: context)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleMouseMove(at: value.location, in: geometry.size)
                    }
                    .onEnded { value in
                        handleClick(at: value.location, in: geometry.size)
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    handleMouseMove(at: location, in: geometry.size)
                case .ended:
                    hoveredNode = nil
                }
            }
            .overlay(alignment: .topLeading) {
                if let hovered = hoveredNode {
                    tooltipView(for: hovered)
                        .position(x: mouseLocation.x, y: mouseLocation.y - 40)
                }
            }
            .focusable()
            .onKeyPress(.escape) {
                handleEscape()
                return .handled
            }
            .onKeyPress(.return) {
                handleEnter()
                return .handled
            }
        }
    }

    // MARK: - Keyboard Handlers

    private func handleEscape() {
        // Zoom out to parent or root
        withAnimation(.easeInOut(duration: 0.3)) {
            zoomedNode = nil
        }
    }

    private func handleEnter() {
        // Zoom into selected directory
        guard let selected = selectedNode,
              selected.isDirectory,
              !selected.children.isEmpty else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            zoomedNode = selected
        }
    }

    // MARK: - Drawing

    private func drawRectangle(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect

        // Don't draw rectangles that are too small
        guard rect.width > 1 && rect.height > 1 else { return }

        // Choose color based on color scheme
        let fillColor = colorScheme == .dark
            ? rectangle.node.fileType.darkModeColor
            : rectangle.node.fileType.color

        // Fill rectangle
        var path = Path(rect)
        context.fill(path, with: .color(fillColor))

        // Draw border
        context.stroke(
            path,
            with: .color(.white.opacity(0.3)),
            lineWidth: 1
        )

        // Draw label if space allows
        if rectangle.canShowLabel {
            drawLabel(for: rectangle, in: context)
        }
    }

    private func drawLabel(for rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect
        let node = rectangle.node

        // Calculate text position (centered in rectangle)
        let centerX = rect.midX
        let centerY = rect.midY

        // Draw name
        let name = node.name
        let namePoint = CGPoint(x: centerX, y: centerY - 8)

        var nameText = Text(name)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white)

        context.draw(
            nameText,
            at: namePoint,
            anchor: .center
        )

        // Draw size if space allows
        if rectangle.canShowSize {
            let size = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
            let sizePoint = CGPoint(x: centerX, y: centerY + 8)

            var sizeText = Text(size)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.9))

            context.draw(
                sizeText,
                at: sizePoint,
                anchor: .center
            )
        }
    }

    private func drawSelectionHighlight(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect.insetBy(dx: 2, dy: 2)
        let path = Path(rect)

        // Draw thick border for selection
        context.stroke(
            path,
            with: .color(.white),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )

        // Draw outer glow
        context.stroke(
            path,
            with: .color(.accentColor),
            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
        )
    }

    // MARK: - Interaction

    private func handleMouseMove(at location: CGPoint, in size: CGSize) {
        mouseLocation = location

        // Find node at location
        let rectangles = TreemapLayout.layout(
            node: displayNode,
            in: CGRect(origin: .zero, size: size)
        )

        hoveredNode = rectangles.first(where: { $0.rect.contains(location) })?.node
    }

    private func handleClick(at location: CGPoint, in size: CGSize) {
        let now = Date()
        let timeSinceLastClick = now.timeIntervalSince(lastClickTime)
        let distance = hypot(location.x - lastClickLocation.x, location.y - lastClickLocation.y)

        // Find node at location
        let rectangles = TreemapLayout.layout(
            node: displayNode,
            in: CGRect(origin: .zero, size: size)
        )

        if let tappedRect = rectangles.first(where: { $0.rect.contains(location) }) {
            // Check for double-click (within 500ms and 10pt distance)
            if timeSinceLastClick < 0.5 && distance < 10 {
                // Double-click: zoom into directory
                handleDoubleClick(node: tappedRect.node)
            } else {
                // Single click: select
                selectedNode = tappedRect.node
            }

            lastClickTime = now
            lastClickLocation = location
        }
    }

    private func handleDoubleClick(node: FileNode) {
        guard node.isDirectory && !node.children.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            zoomedNode = node
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    private func tooltipView(for node: FileNode) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(node.name)
                .font(.system(size: 12, weight: .semibold))

            HStack(spacing: 8) {
                Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                    .font(.system(size: 11))

                if node.totalSize > 0 && displayNode.totalSize > 0 {
                    let percentage = (Double(node.totalSize) / Double(displayNode.totalSize)) * 100
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }
}

#Preview {
    let sampleNode = FileNode(
        path: URL(fileURLWithPath: "/Sample"),
        name: "Sample",
        size: 0,
        fileType: .directory,
        modifiedDate: Date(),
        children: [
            FileNode(
                path: URL(fileURLWithPath: "/Sample/Documents"),
                name: "Documents",
                size: 1_000_000_000,
                fileType: .directory,
                modifiedDate: Date(),
                children: [],
                isDirectory: true
            ),
            FileNode(
                path: URL(fileURLWithPath: "/Sample/Images"),
                name: "Images",
                size: 500_000_000,
                fileType: .directory,
                modifiedDate: Date(),
                children: [],
                isDirectory: true
            ),
            FileNode(
                path: URL(fileURLWithPath: "/Sample/Videos"),
                name: "Videos",
                size: 300_000_000,
                fileType: .directory,
                modifiedDate: Date(),
                children: [],
                isDirectory: true
            )
        ],
        isDirectory: true
    )

    return TreemapView(
        rootNode: sampleNode,
        selectedNode: .constant(nil),
        zoomedNode: .constant(nil)
    )
    .frame(width: 800, height: 600)
}

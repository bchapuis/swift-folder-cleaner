import SwiftUI

/// High-performance treemap visualization with caching and optimizations
struct TreemapView: View {
    // MARK: - Properties

    let rootNode: FileNode
    @Binding var selectedNode: FileNode?
    @Binding var zoomedNode: FileNode?

    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = TreemapViewModel()
    @State private var viewSize: CGSize = .zero
    @State private var mouseLocation: CGPoint = .zero

    // Gesture state
    @GestureState private var isDragging = false
    @State private var tapCount = 0
    @State private var lastTapTime: Date = .distantPast
    @State private var lastTapLocation: CGPoint = .zero

    // MARK: - Computed Properties

    private var displayNode: FileNode {
        zoomedNode ?? rootNode
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Update layout if needed
                viewModel.updateLayout(
                    rootNode: rootNode,
                    displayNode: displayNode,
                    size: size
                )

                // Draw all rectangles
                for rectangle in viewModel.rectangles {
                    drawRectangle(rectangle, in: context)
                }

                // Draw selection highlight
                if let selected = selectedNode,
                   let selectedRect = viewModel.rectangles.first(where: { $0.node.path == selected.path }) {
                    drawSelectionHighlight(selectedRect, in: context)
                }

                // Draw hover highlight
                if let hovered = viewModel.hoveredNode,
                   let hoveredRect = viewModel.rectangles.first(where: { $0.node.path == hovered.path }),
                   hoveredRect.node.path != selectedNode?.path {
                    drawHoverHighlight(hoveredRect, in: context)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        handleDragChanged(value.location, in: geometry.size)
                    }
                    .onEnded { value in
                        handleDragEnded(value.location, in: geometry.size)
                    }
            )
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        handleDoubleTap(at: mouseLocation)
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    handleHover(at: location)
                case .ended:
                    viewModel.updateHover(at: nil)
                }
            }
            .overlay(alignment: .topLeading) {
                if let hovered = viewModel.hoveredNode {
                    tooltipView(for: hovered)
                        .position(x: mouseLocation.x, y: max(40, mouseLocation.y - 40))
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
            .onChange(of: geometry.size) { oldSize, newSize in
                if oldSize != newSize {
                    viewSize = newSize
                    viewModel.invalidateLayout()
                }
            }
            .onChange(of: displayNode.path) {
                viewModel.invalidateLayout()
            }
            .onAppear {
                viewSize = geometry.size
            }
        }
    }

    // MARK: - Drawing

    private func drawRectangle(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect

        // Don't draw tiny rectangles
        guard rect.width > 1 && rect.height > 1 else { return }

        // Choose color based on color scheme
        let fillColor = colorScheme == .dark
            ? rectangle.node.fileType.darkModeColor
            : rectangle.node.fileType.color

        // Fill
        let path = Path(rect)
        context.fill(path, with: .color(fillColor))

        // Border
        context.stroke(
            path,
            with: .color(.white.opacity(0.2)),
            lineWidth: 0.5
        )

        // Label if space allows
        if rectangle.canShowLabel {
            drawLabel(for: rectangle, in: context)
        }
    }

    private func drawLabel(for rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect
        let node = rectangle.node

        let centerX = rect.midX
        let centerY = rect.midY

        // Name
        var nameText = Text(node.name)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white)

        context.draw(
            nameText,
            at: CGPoint(x: centerX, y: centerY - 8),
            anchor: .center
        )

        // Size if space allows
        if rectangle.canShowSize {
            let size = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
            var sizeText = Text(size)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.9))

            context.draw(
                sizeText,
                at: CGPoint(x: centerX, y: centerY + 8),
                anchor: .center
            )
        }
    }

    private func drawSelectionHighlight(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect.insetBy(dx: 2, dy: 2)
        let path = Path(rect)

        // Inner white border
        context.stroke(
            path,
            with: .color(.white),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )

        // Outer accent glow
        context.stroke(
            path,
            with: .color(.accentColor),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawHoverHighlight(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect.insetBy(dx: 1, dy: 1)
        let path = Path(rect)

        // Subtle hover border
        context.stroke(
            path,
            with: .color(.white.opacity(0.5)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }

    // MARK: - Interaction Handlers

    private func handleDragChanged(_ location: CGPoint, in size: CGSize) {
        mouseLocation = location
    }

    private func handleDragEnded(_ location: CGPoint, in size: CGSize) {
        // Single tap/click
        if let node = viewModel.findNode(at: location) {
            selectedNode = node
        }
    }

    private func handleDoubleTap(at location: CGPoint) {
        guard let node = viewModel.findNode(at: location),
              node.isDirectory,
              !node.children.isEmpty else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            zoomedNode = node
        }
    }

    private func handleHover(at location: CGPoint) {
        mouseLocation = location
        viewModel.updateHover(at: location)
    }

    private func handleEscape() {
        withAnimation(.easeInOut(duration: 0.3)) {
            zoomedNode = nil
        }
    }

    private func handleEnter() {
        guard let selected = selectedNode,
              selected.isDirectory,
              !selected.children.isEmpty else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            zoomedNode = selected
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    private func tooltipView(for node: FileNode) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(node.name)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)

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

// MARK: - Preview

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

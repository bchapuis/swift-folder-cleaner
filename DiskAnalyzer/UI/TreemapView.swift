import SwiftUI

/// Treemap visualization - reads state from and sends actions to ScanResultViewModel
struct TreemapView: View {
    // MARK: - Properties

    let viewModel: ScanResultViewModel

    @Environment(\.colorScheme) private var colorScheme

    @State private var mouseLocation: CGPoint = .zero
    @State private var currentSize: CGSize = .zero
    @State private var canvasID = UUID()

    // MARK: - Computed Properties

    private var layoutViewModel: TreemapViewModel {
        viewModel.treemapViewModel
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw pre-filtered rectangles (no computation here!)
                for rectangle in layoutViewModel.drawableRectangles {
                    drawRectangle(rectangle, in: context)
                }

                // Draw selection highlight
                if let selected = viewModel.selectedNode,
                   let selectedRect = layoutViewModel.rectangle(for: selected.path) {
                    // For directories: just draw border
                    // For files: draw full highlight
                    if selectedRect.node.isDirectory && !selectedRect.node.children.isEmpty {
                        drawDirectoryBorder(selectedRect, in: context)
                    } else {
                        drawSelectionHighlight(selectedRect, in: context)
                    }
                }

                // Draw hover highlight
                if let hovered = layoutViewModel.hoveredNode,
                   hovered.path != viewModel.selectedNode?.path,
                   let hoveredRect = layoutViewModel.rectangle(for: hovered.path) {
                    drawHoverHighlight(hoveredRect, in: context)
                }
            }
            .onTapGesture(count: 2) {
                // Double-tap - drill down if directory
                handleDoubleTap(at: mouseLocation)
            }
            .onTapGesture(count: 1) {
                // Single-tap - select item
                handleSingleTap(at: mouseLocation)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    mouseLocation = location
                    layoutViewModel.updateHover(at: location)
                case .ended:
                    layoutViewModel.updateHover(at: nil)
                }
            }
            .overlay(alignment: .topLeading) {
                if let hovered = layoutViewModel.hoveredNode {
                    tooltipView(for: hovered)
                        .position(
                            x: min(mouseLocation.x + 100, geometry.size.width - 100),
                            y: max(40, min(mouseLocation.y - 40, geometry.size.height - 100))
                        )
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                if oldSize != newSize && abs(newSize.width - currentSize.width) > 1 || abs(newSize.height - currentSize.height) > 1 {
                    currentSize = newSize
                    layoutViewModel.updateLayout(rootNode: viewModel.filteredRoot, size: newSize)
                    canvasID = UUID() // Force Canvas redraw
                }
            }
            .onChange(of: viewModel.currentRoot.path) { _, _ in
                // Navigation changed - update layout
                layoutViewModel.updateLayout(rootNode: viewModel.filteredRoot, size: currentSize)
                canvasID = UUID()
            }
            .onChange(of: viewModel.selectedTypes) { _, _ in
                // File type filter changed - update layout with new filtered tree
                layoutViewModel.updateLayout(rootNode: viewModel.filteredRoot, size: currentSize)
                canvasID = UUID()
            }
            .onChange(of: viewModel.selectedSize) { _, _ in
                // Size filter changed - update layout with new filtered tree
                layoutViewModel.updateLayout(rootNode: viewModel.filteredRoot, size: currentSize)
                canvasID = UUID()
            }
            .onAppear {
                currentSize = geometry.size
                layoutViewModel.updateLayout(rootNode: viewModel.filteredRoot, size: geometry.size)
            }
            .id(canvasID)
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
        context.fill(path, with: .color(fillColor.opacity(0.9)))

        // Border
        context.stroke(
            path,
            with: .color(.white.opacity(0.25)),
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

        // Smart truncate: keep file extension visible
        let displayName = smartTruncate(node.name, maxWidth: rect.width - 8)
        let fontSize = rectangle.labelFontSize

        // Draw text shadow for better contrast
        var shadowContext = context
        shadowContext.addFilter(.shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1))

        // Name
        let nameText = Text(displayName)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(.white)

        shadowContext.draw(
            nameText,
            at: CGPoint(x: centerX, y: centerY - 8),
            anchor: .center
        )

        // Size if space allows
        if rectangle.canShowSize {
            let size = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
            let sizeText = Text(size)
                .font(.system(size: fontSize - 2))
                .foregroundStyle(.white.opacity(0.95))

            shadowContext.draw(
                sizeText,
                at: CGPoint(x: centerX, y: centerY + 10),
                anchor: .center
            )
        }
    }

    private func smartTruncate(_ name: String, maxWidth: CGFloat) -> String {
        let avgCharWidth: CGFloat = 7
        let maxChars = Int(maxWidth / avgCharWidth)

        if name.count <= maxChars {
            return name
        }

        // Keep extension visible
        if let dotIndex = name.lastIndex(of: "."),
           dotIndex != name.startIndex {
            let ext = String(name[dotIndex...])
            let nameWithoutExt = String(name[..<dotIndex])

            let extLength = ext.count
            let availableForName = maxChars - extLength - 3 // "..." + extension

            if availableForName > 0 {
                return String(nameWithoutExt.prefix(availableForName)) + "..." + ext
            }
        }

        // Fallback: simple truncation
        return String(name.prefix(maxChars - 3)) + "..."
    }

    private func drawSelectionHighlight(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect.insetBy(dx: 2, dy: 2)
        let path = Path(rect)

        // Thick accent border
        context.stroke(
            path,
            with: .color(.accentColor),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )

        // Subtle glow
        var glowContext = context
        glowContext.addFilter(.shadow(color: .accentColor.opacity(0.5), radius: 4, x: 0, y: 0))
        glowContext.stroke(
            path,
            with: .color(.accentColor),
            style: StrokeStyle(lineWidth: 3)
        )
    }

    private func drawDirectoryBorder(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect.insetBy(dx: 2, dy: 2)
        let path = Path(rect)

        // Thick accent border for directory (no fill, no label)
        context.stroke(
            path,
            with: .color(.accentColor),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )

        // Subtle glow
        var glowContext = context
        glowContext.addFilter(.shadow(color: .accentColor.opacity(0.5), radius: 4, x: 0, y: 0))
        glowContext.stroke(
            path,
            with: .color(.accentColor),
            style: StrokeStyle(lineWidth: 4)
        )
    }

    private func drawHoverHighlight(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect.insetBy(dx: 1, dy: 1)
        let path = Path(rect)

        context.stroke(
            path,
            with: .color(.white.opacity(0.6)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }

    // MARK: - Interaction Handlers

    private func handleSingleTap(at location: CGPoint) {
        guard let node = layoutViewModel.findNode(at: location) else {
            viewModel.selectNode(nil)
            return
        }

        viewModel.selectNode(node)
    }

    private func handleDoubleTap(at location: CGPoint) {
        guard let node = layoutViewModel.findNode(at: location),
              node.isDirectory else {
            return
        }

        viewModel.drillDown(to: node)
    }

    // MARK: - Tooltip

    @ViewBuilder
    private func tooltipView(for node: FileNode) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name
            Text(node.name)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)

            // Size and percentage
            HStack(spacing: 8) {
                Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                    .font(.system(size: 11))

                if node.totalSize > 0 && viewModel.currentRoot.totalSize > 0 {
                    let percentage = (Double(node.totalSize) / Double(viewModel.currentRoot.totalSize)) * 100
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            // File count for directories
            if node.isDirectory {
                Text("\(node.children.count) items")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        }
    }
}

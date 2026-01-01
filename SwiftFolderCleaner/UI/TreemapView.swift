import SwiftUI

/// Treemap visualization - reads state from and sends actions to ScanResultViewModel
struct TreemapView: View {
    // MARK: - Properties

    let viewModel: ScanResultViewModel

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
            Canvas { context, _ in
                // Draw pre-filtered rectangles (no computation here!)
                for rectangle in layoutViewModel.drawableRectangles {
                    drawRectangle(rectangle, in: context)
                }

                // Draw selection highlight
                if let selected = viewModel.selectedNode,
                   let selectedRect = layoutViewModel.rectangle(for: selected.path) {
                    drawSelectionHighlight(selectedRect, in: context)
                }

                // Draw hover highlight
                if let hovered = layoutViewModel.hoveredItem,
                   hovered.path != viewModel.selectedNode?.path,
                   let hoveredRect = layoutViewModel.rectangle(for: hovered.path) {
                    drawHoverHighlight(hoveredRect, in: context)
                }
            }
            .background(Color(white: 0.8))
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
                if let hovered = layoutViewModel.hoveredItem {
                    tooltipView(for: hovered)
                        .position(
                            x: min(mouseLocation.x + 100, geometry.size.width - 100),
                            y: max(40, min(mouseLocation.y - 40, geometry.size.height - 100))
                        )
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                let widthChanged = abs(newSize.width - currentSize.width) > 1
                let heightChanged = abs(newSize.height - currentSize.height) > 1
                if oldSize != newSize && (widthChanged || heightChanged) {
                    currentSize = newSize
                    layoutViewModel.updateLayout(rootItem: viewModel.filteredRoot, size: newSize)
                    canvasID = UUID() // Force Canvas redraw
                }
            }
            .onChange(of: viewModel.currentRoot.path) { _, _ in
                // Navigation changed - update layout
                layoutViewModel.updateLayout(rootItem: viewModel.filteredRoot, size: currentSize)
                canvasID = UUID()
            }
            .onChange(of: viewModel.filterVersion) { _, _ in
                // Any filter changed (type, size, filename, etc.) - update layout with new filtered tree
                layoutViewModel.updateLayout(rootItem: viewModel.filteredRoot, size: currentSize)
                canvasID = UUID()
            }
            .onAppear {
                currentSize = geometry.size
                layoutViewModel.updateLayout(rootItem: viewModel.filteredRoot, size: geometry.size)
            }
            .id(canvasID)
        }
    }

    // MARK: - Drawing

    private func drawRectangle(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect

        // Don't draw tiny rectangles
        guard rect.width > 1 && rect.height > 1 else { return }

        // Color automatically adapts to light/dark mode via asset catalog
        let fillColor = rectangle.item.fileType.color

        // Create sharp rectangle path (no rounding)
        let path = Path(rect)

        // Fully opaque fill to prevent anti-aliasing gaps
        context.fill(path, with: .color(fillColor))

        // Add subtle edge darkening for separation (top and left edges)
        if rect.width > 2 && rect.height > 2 {
            // Top edge - very subtle dark line
            let topEdge = Path(CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width,
                height: 1
            ))
            context.fill(topEdge, with: .color(.black.opacity(0.08)))

            // Left edge - very subtle dark line
            let leftEdge = Path(CGRect(
                x: rect.minX,
                y: rect.minY,
                width: 1,
                height: rect.height
            ))
            context.fill(leftEdge, with: .color(.black.opacity(0.08)))
        }

        // Label if space allows
        if rectangle.canShowLabel {
            drawLabel(for: rectangle, in: context)
        }
    }

    private func drawLabel(for rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect
        let node = rectangle.item

        let centerX = rect.midX
        let centerY = rect.midY

        // Smart truncate: keep file extension visible
        let displayName = smartTruncate(node.name, maxWidth: rect.width - 8)
        let fontSize = rectangle.labelFontSize

        // Check if we can show size
        let showSize = rectangle.canShowSize

        // Calculate vertical position based on whether we show size
        let nameY: CGFloat
        let sizeY: CGFloat

        if showSize {
            // Two lines: center them together
            let totalHeight: CGFloat = fontSize + (fontSize - 2) + 6 // name + size + gap
            nameY = centerY - totalHeight / 2 + fontSize / 2
            sizeY = nameY + fontSize / 2 + 6 + (fontSize - 2) / 2
        } else {
            // Single line: just center it
            nameY = centerY
            sizeY = 0
        }

        // Name - clean and simple, no shadow
        let nameText = Text(displayName)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(.white.opacity(rectangle.labelOpacity))

        context.draw(
            nameText,
            at: CGPoint(x: centerX, y: nameY),
            anchor: .center
        )

        // Size if space allows
        if showSize {
            let size = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
            let sizeText = Text(size)
                .font(.system(size: fontSize - 2, weight: .regular))
                .foregroundStyle(.white.opacity(rectangle.labelOpacity * 0.85))

            context.draw(
                sizeText,
                at: CGPoint(x: centerX, y: sizeY),
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
        let rect = rectangle.rect.insetBy(dx: 1, dy: 1)
        let path = Path(rect)

        // Bold semi-transparent white border for selection (files and directories)
        context.stroke(
            path,
            with: .color(.white.opacity(0.9)),
            style: StrokeStyle(lineWidth: 2, lineCap: .square, lineJoin: .miter)
        )
    }

    private func drawHoverHighlight(_ rectangle: TreemapRectangle, in context: GraphicsContext) {
        let rect = rectangle.rect.insetBy(dx: 1, dy: 1)
        let path = Path(rect)

        // Lighter semi-transparent white border for hover
        context.stroke(
            path,
            with: .color(.white.opacity(0.6)),
            style: StrokeStyle(lineWidth: 2, lineCap: .square, lineJoin: .miter)
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
    private func tooltipView(for node: FileItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name
            Text(node.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)

            // Size and percentage
            HStack(spacing: 8) {
                Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                    .font(.system(size: 11))

                if node.totalSize > 0 && viewModel.currentRoot.totalSize > 0 {
                    let percentage = Double(node.totalSize) / Double(viewModel.currentRoot.totalSize)
                    Text(percentage.formatted(.percent.precision(.fractionLength(1))))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            // File count for directories
            if node.isDirectory {
                Text("\(node.children.count.formatted(.number)) items")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

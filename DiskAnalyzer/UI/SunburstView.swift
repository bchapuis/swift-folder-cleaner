import SwiftUI

/// High-performance sunburst visualization using Canvas
struct SunburstView: View {
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
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = min(size.width, size.height) / 2 - 20

                // Generate layout for current bounds
                let rings = SunburstLayout.layout(
                    node: displayNode,
                    maxRadius: maxRadius
                )

                // Render each ring
                for ring in rings {
                    drawRing(ring, center: center, in: context)
                }

                // Draw selection highlight
                if let selected = selectedNode,
                   let selectedRing = rings.first(where: { $0.node.path == selected.path }) {
                    drawSelectionHighlight(selectedRing, center: center, in: context)
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

    // MARK: - Drawing

    private func drawRing(_ ring: SunburstRing, center: CGPoint, in context: GraphicsContext) {
        // Skip the root center circle if it's not the display node
        if ring.level == 0 && ring.node.path != displayNode.path {
            return
        }

        // Choose color based on color scheme
        let fillColor = colorScheme == .dark
            ? ring.node.fileType.darkModeColor
            : ring.node.fileType.color

        // Create arc path
        var path = Path()

        // For center circle (level 0), draw a full circle
        if ring.level == 0 {
            path.addEllipse(in: CGRect(
                x: center.x - ring.outerRadius,
                y: center.y - ring.outerRadius,
                width: ring.outerRadius * 2,
                height: ring.outerRadius * 2
            ))
        } else {
            // Draw ring segment
            path.move(to: polarToCartesian(
                center: center,
                radius: ring.innerRadius,
                angle: ring.startAngle
            ))

            // Outer arc
            path.addArc(
                center: center,
                radius: ring.outerRadius,
                startAngle: Angle(radians: ring.startAngle - .pi / 2),
                endAngle: Angle(radians: ring.endAngle - .pi / 2),
                clockwise: false
            )

            // Line to inner arc
            path.addLine(to: polarToCartesian(
                center: center,
                radius: ring.innerRadius,
                angle: ring.endAngle
            ))

            // Inner arc (reverse direction)
            path.addArc(
                center: center,
                radius: ring.innerRadius,
                startAngle: Angle(radians: ring.endAngle - .pi / 2),
                endAngle: Angle(radians: ring.startAngle - .pi / 2),
                clockwise: true
            )

            path.closeSubpath()
        }

        // Fill the path
        context.fill(path, with: .color(fillColor))

        // Draw border
        context.stroke(
            path,
            with: .color(.white.opacity(0.2)),
            lineWidth: 1
        )

        // Draw label if space allows
        if ring.canShowLabel {
            drawLabel(for: ring, center: center, in: context)
        }
    }

    private func drawLabel(for ring: SunburstRing, center: CGPoint, in context: GraphicsContext) {
        let labelPosition = polarToCartesian(
            center: center,
            radius: ring.midRadius,
            angle: ring.midAngle
        )

        var nameText = Text(ring.node.name)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white)

        // Rotate text to align with arc
        var textContext = context
        textContext.translateBy(x: labelPosition.x, y: labelPosition.y)

        // Determine if text should be flipped (for readability on left side)
        let angle = ring.midAngle
        let shouldFlip = angle > .pi / 2 && angle < 3 * .pi / 2
        let rotation = shouldFlip ? angle + .pi : angle

        textContext.rotate(by: Angle(radians: rotation))

        textContext.draw(
            nameText,
            at: .zero,
            anchor: .center
        )
    }

    private func drawSelectionHighlight(_ ring: SunburstRing, center: CGPoint, in context: GraphicsContext) {
        var path = Path()

        if ring.level == 0 {
            // Highlight center circle
            path.addEllipse(in: CGRect(
                x: center.x - ring.outerRadius,
                y: center.y - ring.outerRadius,
                width: ring.outerRadius * 2,
                height: ring.outerRadius * 2
            ))
        } else {
            // Highlight ring segment
            path.move(to: polarToCartesian(
                center: center,
                radius: ring.innerRadius,
                angle: ring.startAngle
            ))

            path.addArc(
                center: center,
                radius: ring.outerRadius,
                startAngle: Angle(radians: ring.startAngle - .pi / 2),
                endAngle: Angle(radians: ring.endAngle - .pi / 2),
                clockwise: false
            )

            path.addLine(to: polarToCartesian(
                center: center,
                radius: ring.innerRadius,
                angle: ring.endAngle
            ))

            path.addArc(
                center: center,
                radius: ring.innerRadius,
                startAngle: Angle(radians: ring.endAngle - .pi / 2),
                endAngle: Angle(radians: ring.startAngle - .pi / 2),
                clockwise: true
            )

            path.closeSubpath()
        }

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

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.width, size.height) / 2 - 20

        let rings = SunburstLayout.layout(
            node: displayNode,
            maxRadius: maxRadius
        )

        hoveredNode = findRingAtPoint(location, center: center, rings: rings)?.node
    }

    private func handleClick(at location: CGPoint, in size: CGSize) {
        let now = Date()
        let timeSinceLastClick = now.timeIntervalSince(lastClickTime)
        let distance = hypot(location.x - lastClickLocation.x, location.y - lastClickLocation.y)

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.width, size.height) / 2 - 20

        let rings = SunburstLayout.layout(
            node: displayNode,
            maxRadius: maxRadius
        )

        if let tappedRing = findRingAtPoint(location, center: center, rings: rings) {
            // Check for double-click (within 500ms and 10pt distance)
            if timeSinceLastClick < 0.5 && distance < 10 {
                handleDoubleClick(node: tappedRing.node)
            } else {
                selectedNode = tappedRing.node
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

    // MARK: - Helper Methods

    private func polarToCartesian(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        // Convert from our angle system (0 = right, counterclockwise)
        // to SwiftUI coordinate system
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)
        return CGPoint(x: x, y: y)
    }

    private func cartesianToPolar(point: CGPoint, center: CGPoint) -> (radius: CGFloat, angle: CGFloat) {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let radius = sqrt(dx * dx + dy * dy)
        var angle = atan2(dy, dx)

        // Normalize angle to 0...2π
        if angle < 0 {
            angle += 2 * .pi
        }

        return (radius, angle)
    }

    private func findRingAtPoint(_ point: CGPoint, center: CGPoint, rings: [SunburstRing]) -> SunburstRing? {
        let (radius, angle) = cartesianToPolar(point: point, center: center)

        // Find the ring that contains this point
        for ring in rings.reversed() { // Check from outermost to innermost
            if radius >= ring.innerRadius && radius <= ring.outerRadius &&
               angle >= ring.startAngle && angle <= ring.endAngle {
                return ring
            }
        }

        return nil
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

    return SunburstView(
        rootNode: sampleNode,
        selectedNode: .constant(nil),
        zoomedNode: .constant(nil)
    )
    .frame(width: 800, height: 600)
    .background(Color(white: 0.1))
}

import Foundation

// MARK: - Traversal Order

/// Order for tree traversal
enum TraversalOrder {
    /// Visit node, then children (pre-order depth-first)
    case depthFirst
    /// Visit children, then node (post-order depth-first)
    case depthFirstPostOrder
    /// Visit level by level (breadth-first)
    case breadthFirst
    /// Visit all nodes at each level before moving to next (level-order)
    case levelOrder
}

// MARK: - FileNode Traversal Extensions

extension FileNode {
    /// Traverse the tree with a visitor function
    /// - Parameters:
    ///   - order: Traversal order
    ///   - visit: Visitor function receiving (node, depth). Return false to stop traversal.
    func traverse(
        order: TraversalOrder = .depthFirst,
        visit: (FileNode, Int) -> Bool
    ) {
        switch order {
        case .depthFirst:
            traverseDepthFirst(depth: 0, visit: visit)
        case .depthFirstPostOrder:
            traverseDepthFirstPostOrder(depth: 0, visit: visit)
        case .breadthFirst, .levelOrder:
            traverseBreadthFirst(visit: visit)
        }
    }

    /// Depth-first traversal (pre-order: visit node, then children)
    @discardableResult
    private func traverseDepthFirst(
        depth: Int,
        visit: (FileNode, Int) -> Bool
    ) -> Bool {
        // Visit this node first
        guard visit(self, depth) else { return false }

        // Then visit children
        for child in children {
            guard child.traverseDepthFirst(depth: depth + 1, visit: visit) else {
                return false
            }
        }

        return true
    }

    /// Depth-first traversal (post-order: visit children, then node)
    @discardableResult
    private func traverseDepthFirstPostOrder(
        depth: Int,
        visit: (FileNode, Int) -> Bool
    ) -> Bool {
        // Visit children first
        for child in children {
            guard child.traverseDepthFirstPostOrder(depth: depth + 1, visit: visit) else {
                return false
            }
        }

        // Then visit this node
        return visit(self, depth)
    }

    /// Breadth-first traversal (level by level)
    private func traverseBreadthFirst(visit: (FileNode, Int) -> Bool) {
        var queue: [(node: FileNode, depth: Int)] = [(self, 0)]

        while !queue.isEmpty {
            let (node, depth) = queue.removeFirst()

            guard visit(node, depth) else { return }

            for child in node.children {
                queue.append((child, depth + 1))
            }
        }
    }

    // MARK: - Flatten Operations

    /// Flatten tree to an array
    func flatten(order: TraversalOrder = .depthFirst) -> [FileNode] {
        var results: [FileNode] = []

        traverse(order: order) { node, _ in
            results.append(node)
            return true
        }

        return results
    }

    /// Flatten only directories
    func flattenDirectories(order: TraversalOrder = .depthFirst) -> [FileNode] {
        var results: [FileNode] = []

        traverse(order: order) { node, _ in
            if node.isDirectory {
                results.append(node)
            }
            return true
        }

        return results
    }

    /// Flatten only files
    func flattenFiles(order: TraversalOrder = .depthFirst) -> [FileNode] {
        var results: [FileNode] = []

        traverse(order: order) { node, _ in
            if !node.isDirectory {
                results.append(node)
            }
            return true
        }

        return results
    }

    /// Flatten tree to a specific depth
    func flattenToDepth(_ maxDepth: Int, order: TraversalOrder = .depthFirst) -> [FileNode] {
        var results: [FileNode] = []

        traverse(order: order) { node, depth in
            if depth <= maxDepth {
                results.append(node)
                return true
            }
            return false  // Stop going deeper
        }

        return results
    }

    // MARK: - Map/Reduce Operations

    /// Map transform over all nodes
    func map<T>(_ transform: (FileNode) -> T) -> [T] {
        var results: [T] = []

        traverse { node, _ in
            results.append(transform(node))
            return true
        }

        return results
    }

    /// Compact map transform over all nodes
    func compactMap<T>(_ transform: (FileNode) -> T?) -> [T] {
        var results: [T] = []

        traverse { node, _ in
            if let value = transform(node) {
                results.append(value)
            }
            return true
        }

        return results
    }

    /// Reduce all nodes to a single value
    func reduce<T>(initial: T, combine: (T, FileNode) -> T) -> T {
        var accumulator = initial

        traverse { node, _ in
            accumulator = combine(accumulator, node)
            return true
        }

        return accumulator
    }

    /// Reduce only files
    func reduceFiles<T>(initial: T, combine: (T, FileNode) -> T) -> T {
        var accumulator = initial

        traverse { node, _ in
            if !node.isDirectory {
                accumulator = combine(accumulator, node)
            }
            return true
        }

        return accumulator
    }

    /// Reduce only directories
    func reduceDirectories<T>(initial: T, combine: (T, FileNode) -> T) -> T {
        var accumulator = initial

        traverse { node, _ in
            if node.isDirectory {
                accumulator = combine(accumulator, node)
            }
            return true
        }

        return accumulator
    }

    // MARK: - Lazy Traversal

    /// Create a lazy sequence for traversal
    func lazy(order: TraversalOrder = .depthFirst) -> FileTreeSequence {
        FileTreeSequence(root: self, order: order)
    }
}

// MARK: - Lazy Sequence

/// Lazy sequence for efficient tree traversal
struct FileTreeSequence: Sequence, IteratorProtocol {
    private let root: FileNode
    private let order: TraversalOrder
    private var queue: [(node: FileNode, depth: Int)] = []
    private var stack: [(node: FileNode, depth: Int)] = []
    private var started = false

    init(root: FileNode, order: TraversalOrder) {
        self.root = root
        self.order = order
    }

    mutating func next() -> FileNode? {
        if !started {
            started = true
            switch order {
            case .depthFirst, .depthFirstPostOrder:
                stack = [(root, 0)]
            case .breadthFirst, .levelOrder:
                queue = [(root, 0)]
            }
        }

        switch order {
        case .depthFirst:
            return nextDepthFirst()
        case .depthFirstPostOrder:
            return nextDepthFirstPostOrder()
        case .breadthFirst, .levelOrder:
            return nextBreadthFirst()
        }
    }

    private mutating func nextDepthFirst() -> FileNode? {
        guard !stack.isEmpty else { return nil }

        let (node, depth) = stack.removeLast()

        // Add children to stack (in reverse order for correct traversal)
        for child in node.children.reversed() {
            stack.append((child, depth + 1))
        }

        return node
    }

    private mutating func nextDepthFirstPostOrder() -> FileNode? {
        guard !stack.isEmpty, var current = stack.last else { return nil }
        var visited: Set<URL> = []

        while !stack.isEmpty {
            guard let lastItem = stack.last else { break }
            current = lastItem

            // If all children visited, return this node
            if current.node.children.allSatisfy({ visited.contains($0.path) }) {
                stack.removeLast()
                visited.insert(current.node.path)
                return current.node
            }

            // Add unvisited children
            for child in current.node.children.reversed() where !visited.contains(child.path) {
                stack.append((child, current.depth + 1))
            }
        }

        return nil
    }

    private mutating func nextBreadthFirst() -> FileNode? {
        guard !queue.isEmpty else { return nil }

        let (node, depth) = queue.removeFirst()

        // Add children to queue
        for child in node.children {
            queue.append((child, depth + 1))
        }

        return node
    }
}

// MARK: - Iteration Helpers

extension FileNode {
    /// For-each iteration
    func forEach(_ body: (FileNode) throws -> Void) rethrows {
        try body(self)
        for child in children {
            try child.forEach(body)
        }
    }

    /// For-each with depth
    func forEach(_ body: (FileNode, Int) throws -> Void) rethrows {
        try forEachWithDepth(depth: 0, body: body)
    }

    private func forEachWithDepth(depth: Int, body: (FileNode, Int) throws -> Void) rethrows {
        try body(self, depth)
        for child in children {
            try child.forEachWithDepth(depth: depth + 1, body: body)
        }
    }

    /// Filter nodes
    func filter(_ isIncluded: (FileNode) -> Bool) -> [FileNode] {
        var results: [FileNode] = []

        traverse { node, _ in
            if isIncluded(node) {
                results.append(node)
            }
            return true
        }

        return results
    }
}

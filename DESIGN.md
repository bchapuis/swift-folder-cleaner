# Software Design

## Architecture

```
UI (SwiftUI) → Domain (Pure Swift) → Data (File I/O)
```

### Layers
- **UI**: Views, ViewModels (@Observable/@MainActor), state management
- **Domain**: Models, use cases, business logic (framework-agnostic)
- **Data**: FileManager integration, repositories, I/O operations

### State Management
- Unidirectional flow: View → ViewModel → Domain → Data → ViewModel → View
- **@Observable** (macOS 14+): Modern observation, automatic change tracking
- **ObservableObject** (macOS 13): Legacy pattern with @Published
- Immutable state objects (struct/enum)
- Single source of truth in ViewModels

### Concurrency
- async/await with structured concurrency
- @MainActor for UI isolation
- Actors for shared mutable state
- Sendable for cross-actor types
- Task cancellation via checkCancellation()

## Core Principles

1. **Minimize Complexity**: Eliminate unnecessary state, avoid nested conditionals
2. **Deep Modules**: Small API hiding rich logic
3. **Pull Complexity Down**: High-level code reads like pseudocode
4. **Single Responsibility**: One purpose per abstraction
5. **Optimize for Reading**: Clarity over brevity
6. **Document Intent**: Comments explain *why*, code shows *how*

## Patterns

### State Modeling
Use enums with associated values, not booleans:

```swift
enum ScanState {
    case idle
    case scanning(progress: Double)
    case complete(result: FileTree)
    case failed(error: String)
}
```

### Error Handling
Typed errors with LocalizedError:

```swift
enum ScanError: LocalizedError {
    case permissionDenied(path: String)
    case pathNotFound(path: String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let path): "Access denied: \(path)"
        case .pathNotFound(let path): "Not found: \(path)"
        }
    }
}
```

### Protocol-Oriented Design
Define protocols at boundaries:

```swift
protocol FileScanning: Sendable {
    func scan(path: URL) async throws -> FileTree
}

protocol FileRepository: Sendable {
    func save(_ tree: FileTree) async throws
    func loadRecent() async throws -> [FileTree]
}
```

### Dependency Injection
Constructor injection for testability:

```swift
@MainActor
@Observable
class ScanViewModel {
    private let scanner: any FileScanning

    init(scanner: any FileScanning) {
        self.scanner = scanner
    }
}
```

### SwiftUI View Composition
Extract subviews, use @ViewBuilder:

```swift
struct FileListView: View {
    let nodes: [FileNode]

    var body: some View {
        List(nodes, id: \.path) { node in
            FileRow(node: node)
        }
    }
}
```

### Identifiable Protocol
Stable IDs for collections:

```swift
struct FileNode: Identifiable, Sendable {
    var id: URL { path }
    let path: URL
    let size: Int64
    let children: [FileNode]
}
```

### Value vs Reference Semantics
Prefer structs for immutable data, classes only for identity or reference sharing:

```swift
struct FileNode: Sendable {  // Value type - safe for concurrency
    let path: URL
    let size: Int64
}

@MainActor
class ViewModel: ObservableObject {  // Reference type - needs identity
    @Published var state: State
}
```

### Retain Cycle Prevention
Use weak for delegates, unowned for guaranteed parent:

```swift
class FileScanner {
    weak var delegate: ScanDelegate?  // Delegate pattern
}

class TreeNode {
    unowned let parent: TreeNode?  // Parent always outlives child
    let children: [TreeNode]
}
```

## Testing

### Structure
Arrange-Act-Assert pattern:

```swift
func testScanReturnsCorrectSize() async throws {
    // Arrange
    let scanner = FileScanner()
    let testDir = createTestDirectory()

    // Act
    let result = try await scanner.scan(path: testDir)

    // Assert
    XCTAssertEqual(expectedSize, result.totalSize)
}
```

### Async Testing
```swift
func testCancellation() async throws {
    let task = Task {
        try await scanner.scan(path: largePath)
    }
    task.cancel()

    do {
        _ = try await task.value
        XCTFail("Should throw CancellationError")
    } catch is CancellationError {
        // Expected
    }
}
```

### Mocking
Protocol-based test doubles:

```swift
final class MockScanner: FileScanning {
    var scanResult: Result<FileTree, Error> = .failure(TestError())

    func scan(path: URL) async throws -> FileTree {
        try scanResult.get()
    }
}
```

## Documentation

Use DocC-style comments for public APIs:

```swift
/// Scans a directory tree and calculates file sizes.
///
/// - Parameter path: Root directory to scan
/// - Returns: Tree structure with size information
/// - Throws: `ScanError` if permission denied or path invalid
func scan(path: URL) async throws -> FileTree
```

## Refactoring Checklist

- [ ] Single sentence description possible?
- [ ] Magic numbers → named constants?
- [ ] Duplicated logic extracted?
- [ ] Error cases handled gracefully?
- [ ] Code clear to newcomers?
- [ ] Complexity pushed to lower layers?
- [ ] Comments explain *why*?
- [ ] Proper access control (private/internal/public)?
- [ ] Value types where appropriate?
- [ ] Protocol conformance (Sendable, Identifiable, Codable)?
- [ ] Retain cycles avoided (weak/unowned)?
- [ ] Tests passing?
- [ ] Async/await instead of callbacks?

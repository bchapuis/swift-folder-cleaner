---
name: swift-refactoring
description: Auto-invoked for refactoring Swift code. Applies project design principles.
allowed-tools: Read, Edit, Glob, Grep
---

## Principles

1. Minimize complexity: guard over nested if
2. Enums for state: not booleans
3. Extensions for organization
4. Immutability: prefer structs
5. Result types for expected failures

## Patterns

**Guard Statements:**
```swift
// Before
if FileManager.default.fileExists(atPath: url.path) {
    if FileManager.default.isReadableFile(atPath: url.path) {
        return readFile(at: url)
    }
}

// After
guard FileManager.default.fileExists(atPath: url.path) else {
    return .failure(.doesNotExist)
}
guard FileManager.default.isReadableFile(atPath: url.path) else {
    return .failure(.permissionDenied)
}
return readFile(at: url)
```

**Enum State:**
```swift
// Before
struct ScanState {
    var isScanning: Bool
    var result: FileTree?
    var error: String?
}

// After
enum ScanState {
    case idle
    case scanning(progress: Double)
    case complete(result: FileTree)
    case failed(error: String)
}
```

**@Observable Migration:**
```swift
// Before (ObservableObject)
class ScanViewModel: ObservableObject {
    @Published var state: ScanState = .idle
}

// After (@Observable)
@Observable
class ScanViewModel {
    var state: ScanState = .idle  // No @Published
}
```

**Actor Isolation:**
```swift
// Before (unsafe)
class FileScanner {
    var filesProcessed: Int = 0  // Data race!
}

// After (safe)
actor FileScanner {
    private var filesProcessed: Int = 0
    func getProgress() -> Int { filesProcessed }
}
```

**Sendable Conformance:**
```swift
struct FileNode: Sendable {
    let path: URL
    let size: Int64  // Immutable
    let children: [FileNode]
}
```

## Checklist

- [ ] Single sentence description?
- [ ] Magic numbers → constants?
- [ ] Duplicated logic extracted?
- [ ] Error cases handled?
- [ ] Code clear to newcomers?
- [ ] Tests passing?

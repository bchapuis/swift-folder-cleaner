---
name: swift-concurrency-best-practices
description: Auto-invoked for Swift concurrency (async/await, actors, tasks).
allowed-tools: Read, Edit, Glob, Grep
---

## Patterns

**Async File I/O:**
```swift
func scanDirectory(_ url: URL) async throws -> FileTree {
    let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
    var nodes: [FileNode] = []

    while let fileURL = enumerator?.nextObject() as? URL {
        try Task.checkCancellation()
        nodes.append(try await processFile(fileURL))
    }

    return FileTree(nodes: nodes)
}
```

**Actors for Shared State:**
```swift
actor FileScanner {
    private var filesProcessed: Int = 0

    func updateProgress(count: Int) {
        filesProcessed += count
    }

    func getProgress() -> Int {
        filesProcessed
    }
}
```

**@MainActor for UI:**
```swift
@MainActor
@Observable
class ScanViewModel {
    var state: ScanState = .idle

    func startScan(at path: URL) {
        Task {
            state = .scanning(progress: 0)
            let result = await scanner.scan(path: path)
            state = .complete(result: result)
        }
    }
}
```

**Cancellation:**
```swift
func scanDirectory(_ url: URL) async throws -> [FileNode] {
    var results: [FileNode] = []
    let enumerator = FileManager.default.enumerator(atPath: url.path)

    while let file = enumerator?.nextObject() as? String {
        try Task.checkCancellation()  // Respect cancellation
        results.append(try await processFile(at: url.appendingPathComponent(file)))
    }

    return results
}
```

**Progress with AsyncStream:**
```swift
func scanWithProgress(at url: URL) -> AsyncStream<ScanProgress> {
    AsyncStream { continuation in
        Task {
            var processed = 0
            let enumerator = FileManager.default.enumerator(atPath: url.path)

            while let file = enumerator?.nextObject() as? String {
                try Task.checkCancellation()
                processed += 1

                if processed % 100 == 0 {
                    continuation.yield(ScanProgress(filesProcessed: processed, currentPath: file))
                }
            }
            continuation.finish()
        }
    }
}
```

**TaskGroup for Parallelism:**
```swift
func scanDirectories(urls: [URL]) async throws -> [FileTree] {
    try await withThrowingTaskGroup(of: FileTree.self) { group in
        for url in urls {
            group.addTask { try await scanDirectory(url) }
        }

        var results: [FileTree] = []
        for try await tree in group {
            results.append(tree)
        }
        return results
    }
}
```

**Sendable Types:**
```swift
struct ScanResult: Sendable {
    let totalSize: Int64
    let fileCount: Int
    let root: FileNode
}

protocol FileScanning: Sendable {
    func scan(path: URL) async throws -> FileTree
}
```

## Anti-Patterns

❌ **Don't mix DispatchQueue with async/await:**
```swift
// Bad
DispatchQueue.global().async {
    await scanDirectory(at: path)
}

// Good
Task {
    await scanDirectory(at: path)
}
```

❌ **Don't forget @MainActor for UI:**
```swift
// Bad - can crash
class ViewModel: ObservableObject {
    @Published var state: State

    func update() async {
        state = .loading  // Might be on background thread!
    }
}

// Good - guaranteed main thread
@MainActor
class ViewModel: ObservableObject {
    @Published var state: State

    func update() async {
        state = .loading  // Always on main thread
    }
}
```

## Checklist

- [ ] async/await for I/O
- [ ] Actors for shared mutable state
- [ ] @MainActor for UI
- [ ] Task.checkCancellation() in loops
- [ ] Sendable conformance for cross-actor types
- [ ] TaskGroup for parallelism
- [ ] Enable -strict-concurrency=complete

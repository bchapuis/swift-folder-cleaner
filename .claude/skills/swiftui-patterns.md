---
name: swiftui-patterns
description: Auto-invoked for SwiftUI components. State management, animations, performance.
allowed-tools: Read, Edit, Glob, Grep
---

## State Management

**@Observable (macOS 14+):**
```swift
@Observable
class ScanViewModel {
    var state: ScanState = .idle
    var progress: Double = 0.0
}

struct ScanView: View {
    let viewModel: ScanViewModel  // No property wrapper!

    var body: some View {
        Text("Progress: \(viewModel.progress)")
    }
}
```

**ObservableObject (macOS 13):**
```swift
class ScanViewModel: ObservableObject {
    @Published var state: ScanState = .idle
}

struct ScanView: View {
    @ObservedObject var viewModel: ScanViewModel
}
```

**Environment Injection:**
```swift
@Observable
class AppState {
    var currentScan: FileTree?
}

@main
struct App: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView().environment(appState)
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
}
```

## Performance

**List Optimization:**
```swift
LazyVStack {
    ForEach(nodes, id: \.path) { node in
        FileRow(node: node).equatable()
    }
}

struct FileRow: View, Equatable {
    let node: FileNode

    static func == (lhs: FileRow, rhs: FileRow) -> Bool {
        lhs.node.path == rhs.node.path
    }
}
```

**Animations:**
```swift
@State private var expanded = false

Rectangle()
    .frame(height: expanded ? 300 : 48)
    .animation(.spring(duration: 0.25), value: expanded)
```

**Reduce Motion:**
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

Rectangle()
    .animation(reduceMotion ? .none : .spring(), value: state)
```

## Custom Modifiers

```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
```

## PreferenceKey

```swift
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct ParentView: View {
    @State private var childSize: CGSize = .zero

    var body: some View {
        ChildView()
            .background(GeometryReader { geometry in
                Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
            })
            .onPreferenceChange(SizePreferenceKey.self) { size in
                childSize = size
            }
    }
}
```

## Accessibility

```swift
Button("Delete") { deleteFile() }
    .keyboardShortcut(.delete)
    .accessibilityLabel("Delete selected file")
    .accessibilityHint("Moves file to trash")
    .accessibilityAddTraits(.isDestructive)

@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20
Image(systemName: "doc").frame(width: iconSize, height: iconSize)
```

## Checklist

- [ ] @State for view-local state
- [ ] @Observable for ViewModels (macOS 14+)
- [ ] Stable IDs for List
- [ ] Lazy stacks for large lists
- [ ] .equatable() for expensive views
- [ ] Respect Reduce Motion
- [ ] VoiceOver labels
- [ ] Dynamic Type support
